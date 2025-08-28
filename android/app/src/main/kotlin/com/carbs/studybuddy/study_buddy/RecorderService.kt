package com.carbs.studybuddy.study_buddy

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class RecorderService : Service() {
    private var recorder: MediaRecorder? = null
    private val channelId = "study_buddy_recorder"
    private val notifId = 1001

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notif = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Recording in progress")
            .setContentText("Study Buddy is recording your lecture")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .build()
        startForeground(notifId, notif)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START" -> startRecording(intent.getStringExtra("path") ?: return START_NOT_STICKY)
            "PAUSE" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                try { recorder?.pause() } catch (_: Exception) {}
            }
            "RESUME" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                try { recorder?.resume() } catch (_: Exception) {}
            }
            "STOP" -> stopRecording()
        }
        return START_NOT_STICKY
    }

    private fun startRecording(path: String) {
        stopRecording() // safety if already running
        recorder = MediaRecorder().apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setAudioEncodingBitRate(128_000)
            setAudioSamplingRate(44_100)
            setOutputFile(path)
            prepare()
            start()
        }
    }

    private fun stopRecording() {
        try {
            recorder?.apply { stop(); reset(); release() }
        } catch (_: Exception) {}
        recorder = null
        stopForeground(STOP_FOREGROUND_DETACH)
        stopSelf()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                channelId,
                "Study Buddy Recording",
                NotificationManager.IMPORTANCE_LOW
            )
            nm.createNotificationChannel(channel)
        }
    }
}
