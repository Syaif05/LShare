package com.syaifulloh.lshare

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.app.DownloadManager
import android.content.Context

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.syaifulloh.lshare/file_utils"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openDownloadsFolder") {
                openDownloadsFolder()
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openDownloadsFolder() {
        try {
            // Try to open the /Download/LShare folder directly using Documents UI provider
            val uri = Uri.parse("content://com.android.externalstorage.documents/document/primary%3ADownload%2FLShare")
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "vnd.android.document/directory")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (e: Exception) {
            try {
                // Fallback: Open DownloadManager ACTION_VIEW_DOWNLOADS
                val intent = Intent(DownloadManager.ACTION_VIEW_DOWNLOADS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
            } catch (ex: Exception) {
                try {
                    // Fallback 2: Open generic external downloads root
                    val mainUri = Uri.parse("content://com.android.externalstorage.documents/root/primary")
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(mainUri, "vnd.android.document/directory")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                } catch (exc: Exception) {
                    try {
                        // Fallback 3: Launch system file picker or standard viewer
                        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "*/*"
                            addCategory(Intent.CATEGORY_OPENABLE)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                    } catch (finalEx: Exception) {
                        // All fallbacks failed
                    }
                }
            }
        }
    }
}
