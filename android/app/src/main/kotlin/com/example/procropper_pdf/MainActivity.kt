package com.example.procropper_pdf

import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.DocumentsContract
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val createDocumentRequestCode = 41021
    private val documentsChannelName = "procropper_pdf/android_documents"
    private val incomingPdfChannelName = "procropper_pdf/android_incoming_pdf"
    private var pendingResult: MethodChannel.Result? = null
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
                    "writeDocumentFromPath" -> handleWriteDocumentFromPath(call, result)
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
        startActivityForResult(intent, createDocumentRequestCode)
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

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != createDocumentRequestCode) {
            return
        }

        val callback = pendingResult
        pendingResult = null
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
            val fileName = buildIncomingFileName(uri)
            val incomingDir = File(cacheDir, "incoming_pdfs").apply {
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
            targetFile.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    private fun buildIncomingFileName(uri: Uri): String {
        val candidate = uri.lastPathSegment
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

    private fun ContentResolver.takePersistableUriPermissionIfSupported(uri: Uri) {
        if (uri.scheme != ContentResolver.SCHEME_CONTENT) {
            return
        }
        try {
            takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
        } catch (_: SecurityException) {
            // Some providers don't grant persistable permissions; ignore.
        } catch (_: IllegalArgumentException) {
            // Some URIs do not support persistable permissions; ignore.
        }
    }
}
