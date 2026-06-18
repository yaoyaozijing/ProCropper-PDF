package com.example.briss_flutter

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import java.io.FileInputStream
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val createDocumentRequestCode = 41021
    private val channelName = "briss_flutter/android_documents"
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "createDocument" -> handleCreateDocument(call, result)
                    "writeDocumentFromPath" -> handleWriteDocumentFromPath(call, result)
                    else -> result.notImplemented()
                }
            }
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
}
