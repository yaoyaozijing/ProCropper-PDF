package com.example.procropper_pdf

import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.DocumentsContract
import androidx.documentfile.provider.DocumentFile
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val createDocumentRequestCode = 41021
    private val openDocumentTreeRequestCode = 41022
    private val documentsChannelName = "procropper_pdf/android_documents"
    private val incomingPdfChannelName = "procropper_pdf/android_incoming_pdf"
    private var pendingResult: MethodChannel.Result? = null
    private var pendingRequestCode: Int? = null
    private var pendingIncomingPdfPath: String? = null
    private var incomingPdfChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingIncomingPdfPath = resolveIncomingPdfPath(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, documentsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "createDocument" -> handleCreateDocument(call, result)
                    "pickDirectoryTree" -> handlePickDirectoryTree(result)
                    "listPdfFilesInTree" -> handleListPdfFilesInTree(call, result)
                    "copyTreeFileToCache" -> handleCopyTreeFileToCache(call, result)
                    "writeDocumentFromPath" -> handleWriteDocumentFromPath(call, result)
                    "writeFileToTree" -> handleWriteFileToTree(call, result)
                    else -> result.notImplemented()
                }
            }

        incomingPdfChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            incomingPdfChannelName,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialIncomingPdfPath" -> {
                        result.success(pendingIncomingPdfPath)
                        pendingIncomingPdfPath = null
                    }

                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val path = resolveIncomingPdfPath(intent) ?: return
        pendingIncomingPdfPath = null
        incomingPdfChannel?.invokeMethod("incomingPdfPath", path)
    }

    private fun handleCreateDocument(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "A document picker request is already in progress.", null)
            return
        }

        val fileName = call.argument<String>("fileName") ?: "export.pdf"
        val mimeType = call.argument<String>("mimeType") ?: "application/pdf"

        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            putExtra(Intent.EXTRA_TITLE, fileName)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, null as Uri?)
            }
        }

        pendingResult = result
        pendingRequestCode = createDocumentRequestCode
        startActivityForResult(intent, createDocumentRequestCode)
    }

    private fun handlePickDirectoryTree(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "A document picker request is already in progress.", null)
            return
        }

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }

        pendingResult = result
        pendingRequestCode = openDocumentTreeRequestCode
        startActivityForResult(intent, openDocumentTreeRequestCode)
    }

    private fun handleListPdfFilesInTree(call: MethodCall, result: MethodChannel.Result) {
        val treeUriString = call.argument<String>("treeUri")
        val recursive = call.argument<Boolean>("recursive") ?: false
        if (treeUriString.isNullOrBlank()) {
            result.error("invalid_args", "treeUri is required.", null)
            return
        }

        try {
            val treeUri = Uri.parse(treeUriString)
            contentResolver.takePersistableUriPermissionIfSupported(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
            val root = DocumentFile.fromTreeUri(this, treeUri)
            if (root == null || !root.isDirectory) {
                result.error("tree_invalid", "Unable to open selected folder.", null)
                return
            }
            val files = mutableListOf<Map<String, String>>()
            collectPdfFiles(root, "", recursive, files)
            result.success(files)
        } catch (e: Exception) {
            result.error("list_failed", e.message, null)
        }
    }

    private fun handleCopyTreeFileToCache(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        val fileNameArg = call.argument<String>("fileName")
        if (uriString.isNullOrBlank()) {
            result.error("invalid_args", "uri is required.", null)
            return
        }

        try {
            val uri = Uri.parse(uriString)
            contentResolver.takePersistableUriPermissionIfSupported(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
            val cachedPath = copyUriToCache(
                uri = uri,
                preferredFileName = fileNameArg,
                subdirectory = "batch_inputs",
            )
            result.success(cachedPath)
        } catch (e: Exception) {
            result.error("copy_failed", e.message, null)
        }
    }

    private fun handleWriteDocumentFromPath(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        val sourcePath = call.argument<String>("sourcePath")

        if (uriString.isNullOrBlank() || sourcePath.isNullOrBlank()) {
            result.error("invalid_args", "uri and sourcePath are required.", null)
            return
        }

        try {
            val uri = Uri.parse(uriString)
            contentResolver.openOutputStream(uri, "w")?.use { output ->
                FileInputStream(sourcePath).use { input ->
                    input.copyTo(output)
                }
            } ?: run {
                result.error("open_failed", "Unable to open destination document.", null)
                return
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("write_failed", e.message, null)
        }
    }

    private fun handleWriteFileToTree(call: MethodCall, result: MethodChannel.Result) {
        val treeUriString = call.argument<String>("treeUri")
        val relativeDirectory = call.argument<String>("relativeDirectory") ?: ""
        val fileName = call.argument<String>("fileName")
        val sourcePath = call.argument<String>("sourcePath")

        if (treeUriString.isNullOrBlank() || fileName.isNullOrBlank() || sourcePath.isNullOrBlank()) {
            result.error(
                "invalid_args",
                "treeUri, fileName and sourcePath are required.",
                null,
            )
            return
        }

        try {
            val treeUri = Uri.parse(treeUriString)
            contentResolver.takePersistableUriPermissionIfSupported(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
            val root = DocumentFile.fromTreeUri(this, treeUri)
            if (root == null || !root.isDirectory) {
                result.error("tree_invalid", "Unable to open selected output folder.", null)
                return
            }

            val targetDirectory = ensureRelativeDirectory(root, relativeDirectory)
            val existing = targetDirectory.findFile(fileName)
            existing?.delete()
            val targetFile = targetDirectory.createFile("application/pdf", fileName)
            if (targetFile == null) {
                result.error("create_failed", "Unable to create destination file.", null)
                return
            }

            contentResolver.openOutputStream(targetFile.uri, "w")?.use { output ->
                FileInputStream(sourcePath).use { input ->
                    input.copyTo(output)
                }
            } ?: run {
                result.error("open_failed", "Unable to open destination document.", null)
                return
            }
            result.success(targetFile.uri.toString())
        } catch (e: Exception) {
            result.error("write_failed", e.message, null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        val expectedRequestCode = pendingRequestCode
        if (requestCode != expectedRequestCode) {
            return
        }

        val callback = pendingResult
        pendingResult = null
        pendingRequestCode = null
        if (callback == null) {
            return
        }

        if (resultCode != Activity.RESULT_OK) {
            callback.success(null)
            return
        }

        callback.success(data?.data?.toString())
    }

    private fun resolveIncomingPdfPath(intent: Intent?): String? {
        if (intent == null) {
            return null
        }
        return when (intent.action) {
            Intent.ACTION_VIEW -> copyUriToCache(intent.data)
            Intent.ACTION_SEND -> copyUriToCache(extractSingleUri(intent))
            Intent.ACTION_SEND_MULTIPLE -> copyUriToCache(extractMultipleUris(intent).firstOrNull())
            else -> null
        }
    }

    private fun extractSingleUri(intent: Intent): Uri? {
        @Suppress("DEPRECATION")
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
    }

    private fun extractMultipleUris(intent: Intent): List<Uri> {
        @Suppress("DEPRECATION")
        val uris = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
        }
        return uris ?: emptyList()
    }

    private fun copyUriToCache(uri: Uri?): String? {
        if (uri == null) {
            return null
        }

        return try {
            contentResolver.takePersistableUriPermissionIfSupported(uri)
            copyUriToCache(
                uri = uri,
                preferredFileName = null,
                subdirectory = "incoming_pdfs",
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun copyUriToCache(
        uri: Uri,
        preferredFileName: String?,
        subdirectory: String,
    ): String? {
        val fileName = buildIncomingFileName(uri, preferredFileName)
        val incomingDir = File(cacheDir, subdirectory).apply {
            if (!exists()) {
                mkdirs()
            }
        }
        val targetFile = File(incomingDir, "${System.currentTimeMillis()}_$fileName")
        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(targetFile).use { output ->
                input.copyTo(output)
            }
        } ?: return null
        return targetFile.absolutePath
    }

    private fun buildIncomingFileName(uri: Uri, preferredFileName: String? = null): String {
        val candidate = preferredFileName
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: uri.lastPathSegment
            ?.substringAfterLast('/')
            ?.substringAfterLast(':')
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: "incoming.pdf"
        return if (candidate.lowercase().endsWith(".pdf")) {
            candidate
        } else {
            "$candidate.pdf"
        }
    }

    private fun collectPdfFiles(
        directory: DocumentFile,
        relativeDirectory: String,
        recursive: Boolean,
        output: MutableList<Map<String, String>>,
    ) {
        for (child in directory.listFiles()) {
            if (child.isDirectory) {
                if (!recursive) {
                    continue
                }
                val childName = child.name?.trim().orEmpty()
                if (childName.isEmpty()) {
                    continue
                }
                val nextRelativeDirectory = if (relativeDirectory.isEmpty()) {
                    childName
                } else {
                    "$relativeDirectory/$childName"
                }
                collectPdfFiles(child, nextRelativeDirectory, recursive, output)
                continue
            }
            if (!child.isFile) {
                continue
            }
            val name = child.name?.trim().orEmpty()
            if (!name.lowercase().endsWith(".pdf")) {
                continue
            }
            output.add(
                mapOf(
                    "uri" to child.uri.toString(),
                    "name" to name,
                    "relativeDirectory" to relativeDirectory,
                ),
            )
        }
    }

    private fun ensureRelativeDirectory(root: DocumentFile, relativeDirectory: String): DocumentFile {
        var current = root
        val normalized = relativeDirectory
            .replace('\\', '/')
            .split('/')
            .map { it.trim() }
            .filter { it.isNotEmpty() && it != "." }
        for (segment in normalized) {
            val existing = current.findFile(segment)
            current = when {
                existing != null && existing.isDirectory -> existing
                else -> current.createDirectory(segment)
                    ?: throw IllegalStateException("Unable to create directory: $segment")
            }
        }
        return current
    }

    private fun ContentResolver.takePersistableUriPermissionIfSupported(
        uri: Uri,
        flags: Int = Intent.FLAG_GRANT_READ_URI_PERMISSION,
    ) {
        if (uri.scheme != ContentResolver.SCHEME_CONTENT) {
            return
        }
        try {
            takePersistableUriPermission(uri, flags)
        } catch (_: SecurityException) {
            // Some providers don't grant persistable permissions; ignore.
        } catch (_: IllegalArgumentException) {
            // Some URIs do not support persistable permissions; ignore.
        }
    }
}
