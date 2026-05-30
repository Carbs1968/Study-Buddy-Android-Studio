package com.carbs.studybuddy.study_buddy

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.SystemClock
import androidx.core.app.NotificationCompat

class RecorderService : Service() {

    companion object {
        private val stateLock = Any()
        private var stateIsRecording: Boolean = false
        private var stateIsPaused: Boolean = false
        private var statePath: String? = null
        private var stateStartedAtMillis: Long = 0L
        private var statePausedAtMillis: Long = 0L
        private var statePausedTotalMillis: Long = 0L

        fun serviceState(): Map<String, Any?> = synchronized(stateLock) {
            val now = SystemClock.elapsedRealtime()
            val elapsedMillis = if (!stateIsRecording || stateStartedAtMillis == 0L) {
                0L
            } else {
                val activeUntil = if (stateIsPaused && statePausedAtMillis > 0L) {
                    statePausedAtMillis
                } else {
                    now
                }
                (activeUntil - stateStartedAtMillis - statePausedTotalMillis)
                    .coerceAtLeast(0L)
            }

            mapOf(
                "isRecording" to stateIsRecording,
                "isPaused" to stateIsPaused,
                "path" to statePath,
                "elapsedMillis" to elapsedMillis,
            )
        }

        private fun markStarted(path: String) = synchronized(stateLock) {
            stateIsRecording = true
            stateIsPaused = false
            statePath = path
            stateStartedAtMillis = SystemClock.elapsedRealtime()
            statePausedAtMillis = 0L
            statePausedTotalMillis = 0L
        }

        private fun markPaused() = synchronized(stateLock) {
            if (stateIsRecording && !stateIsPaused) {
                stateIsPaused = true
                statePausedAtMillis = SystemClock.elapsedRealtime()
            }
        }

        private fun markResumed() = synchronized(stateLock) {
            if (stateIsRecording && stateIsPaused) {
                if (statePausedAtMillis > 0L) {
                    statePausedTotalMillis +=
                        SystemClock.elapsedRealtime() - statePausedAtMillis
                }
                stateIsPaused = false
                statePausedAtMillis = 0L
            }
        }

        private fun markStopped() = synchronized(stateLock) {
            stateIsRecording = false
            stateIsPaused = false
            statePath = null
            stateStartedAtMillis = 0L
            statePausedAtMillis = 0L
            statePausedTotalMillis = 0L
        }
    }

    private var recorder: MediaRecorder? = null
    private var hasStarted: Boolean = false
    private var currentPath: String? = null

    // Keep CPU on while screen is locked so recording continues reliably
    private var wakeLock: PowerManager.WakeLock? = null

    private val channelId = "study_buddy_recorder"
    private val notifId = 1001

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        acquireWakeLock()
        startForeground(notifId, buildNotification())
    }

    override fun onDestroy() {
        super.onDestroy()
        // Ensure we finalize and free resources if process is torn down
        stopRecordingInternal()
        releaseWakeLock()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START" -> {
                val path = intent.getStringExtra("path")
                if (path != null) startRecording(path)
            }
            "PAUSE" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    try {
                        recorder?.pause()
                        markPaused()
                    } catch (_: Exception) {}
                }
            }
            "RESUME" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    try {
                        recorder?.resume()
                        markResumed()
                    } catch (_: Exception) {}
                }
            }
            "STOP" -> stopRecordingInternal()
        }
        // We don’t want the system to restart this if it gets killed after you stop.
        return START_NOT_STICKY
    }

    private fun startRecording(path: String) {
        // Safety: if something was already running, finalize it first
        stopRecordingInternal()

        currentPath = path

        val r = MediaRecorder()
        recorder = r

        try {
            // Correct, broadly compatible pipeline for .m4a:
            // AAC-LC audio inside MP4 container (MPEG_4)
            r.setAudioSource(MediaRecorder.AudioSource.MIC)
            r.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            r.setAudioEncoder(MediaRecorder.AudioEncoder.AAC) // AAC-LC
            r.setAudioEncodingBitRate(128_000)               // 128 kbps
            r.setAudioSamplingRate(44_100)                   // 44.1 kHz
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Force mono on newer APIs; improves browser/WMP compatibility
                r.setAudioChannels(1)
            }
            r.setOutputFile(path)

            r.prepare()
            r.start()
            hasStarted = true
            markStarted(path)

        } catch (e: Exception) {
            // If anything fails, make sure we release cleanly so next start works
            try { r.reset() } catch (_: Exception) {}
            try { r.release() } catch (_: Exception) {}
            recorder = null
            hasStarted = false
            currentPath = null
            markStopped()
            // We stay foreground so Flutter can report/start again; no crash.
        }
    }

    private fun stopRecordingInternal() {
        val r = recorder
        if (r == null) {
            markStopped()
            return
        }

        // Try to finalize the MP4 atom so players (browser/WMP/device) can read it
        try {
            if (hasStarted) {
                try { r.stop() } catch (_: Exception) { /* on some OEMs, stop may throw if already finalized */ }
            }
        } catch (_: Exception) {
            // If stop throws, the file may be corrupt; we still release to avoid leaks.
        } finally {
            try { r.reset() } catch (_: Exception) {}
            try { r.release() } catch (_: Exception) {}
            recorder = null
            hasStarted = false
            currentPath = null
            markStopped()
        }

        // Keep the service alive only while actively recording
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_DETACH)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (_: Exception) {}

        stopSelf()
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("Recording in progress")
            .setContentText("Study Buddy is recording your lecture")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setForegroundServiceBehavior(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE
                } else {
                    0
                }
            )
            .build()
    }

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

    private fun acquireWakeLock() {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            // PARTIAL_WAKE_LOCK keeps CPU running with the screen off (lockscreen),
            // which prevents MediaRecorder from stalling on some OEMs.
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "StudyBuddy:RecorderWakeLock"
            ).apply { setReferenceCounted(false); acquire() }
        } catch (_: Exception) {
            // If wakelock fails, foreground service usually still suffices;
            // we keep going to preserve behavior.
        }
    }

    private fun releaseWakeLock() {
        try { wakeLock?.let { if (it.isHeld) it.release() } } catch (_: Exception) {}
        wakeLock = null
    }

    override fun onBind(intent: Intent?): IBinder? = null
}