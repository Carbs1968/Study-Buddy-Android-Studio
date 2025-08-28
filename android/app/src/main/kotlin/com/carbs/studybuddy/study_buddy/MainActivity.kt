package com.carbs.studybuddy.study_buddy

import android.content.Intent
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
                    else -> result.notImplemented()
                }
            }
    }
}
