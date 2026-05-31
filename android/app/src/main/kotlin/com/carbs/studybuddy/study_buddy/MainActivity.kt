package com.carbs.studybuddy.study_buddy

import android.content.Intent
import android.media.MediaMetadataRetriever
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "study_buddy/recorder_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                fun send(action: String, path: String? = null) {
                    val intent = Intent(this, RecorderService::class.java).apply {
                        this.action = action
                        if (path != null) putExtra("path", path)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                }

                fun audioDurationMillis(path: String): Long? {
                    val retriever = MediaMetadataRetriever()
                    return try {
                        retriever.setDataSource(path)
                        retriever
                            .extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                            ?.toLongOrNull()
                    } finally {
                        try { retriever.release() } catch (_: Exception) {}
                    }
                }

                when (call.method) {
                    "startService" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("ARG", "Missing 'path' argument", null)
                        } else {
                            send("START", path)
                            result.success(null)
                        }
                    }
                    "pauseService" -> {
                        send("PAUSE")
                        result.success(null)
                    }
                    "resumeService" -> {
                        send("RESUME")
                        result.success(null)
                    }
                    "stopService" -> {
                        send("STOP")
                        result.success(null)
                    }
                    "getServiceState" -> {
                        result.success(RecorderService.serviceState())
                    }
                    "getAudioDurationMillis" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("ARG", "Missing 'path' argument", null)
                        } else {
                            try {
                                result.success(audioDurationMillis(path))
                            } catch (e: Exception) {
                                result.error(
                                    "DURATION",
                                    "Could not read audio duration: ${e.message}",
                                    null
                                )
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
