package com.carbs.studybuddy.study_buddy

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import java.io.File

class RecorderService : Service() {

    companion object {
        private val stateLock = Any()
        private var stateIsRecording: Boolean = false
        private var stateIsPaused: Boolean = false
        private var statePath: String? = null
        private var stateStartedAtMillis: Long = 0L
        private var statePausedAtMillis: Long = 0L
        private var statePausedTotalMillis: Long = 0L
        private var stateRecorderPresent: Boolean = false
        private var stateHasStarted: Boolean = false
        private var stateFileExists: Boolean = false
        private var stateFileSizeBytes: Long = 0L
        private var stateLastModifiedMillis: Long = 0L
        private var stateLastObservedSizeBytes: Long = 0L
        private var stateLastFileGrowthAtMillis: Long = 0L

        fun serviceState(): Map<String, Any?> = synchronized(stateLock) {
            val now = SystemClock.elapsedRealtime()
            updateFileHealthLocked(now)
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
            val fileStaleMillis = if (
                stateIsRecording &&
                !stateIsPaused &&
                stateLastFileGrowthAtMillis > 0L
            ) {
                now - stateLastFileGrowthAtMillis
            } else {
                0L
            }

            mapOf(
                "isRecording" to stateIsRecording,
                "isPaused" to stateIsPaused,
                "path" to statePath,
                "elapsedMillis" to elapsedMillis,
                "recorderPresent" to stateRecorderPresent,
                "hasStarted" to stateHasStarted,
                "fileExists" to stateFileExists,
                "fileSizeBytes" to stateFileSizeBytes,
                "lastModifiedMillis" to stateLastModifiedMillis,
                "fileStaleMillis" to fileStaleMillis,
            )
        }

        private fun markStarted(path: String) = synchronized(stateLock) {
            val now = SystemClock.elapsedRealtime()
            stateIsRecording = true
            stateIsPaused = false
            statePath = path
            stateStartedAtMillis = now
            statePausedAtMillis = 0L
            statePausedTotalMillis = 0L
            stateRecorderPresent = true
            stateHasStarted = true
            stateLastObservedSizeBytes = 0L
            stateLastFileGrowthAtMillis = now
            updateFileHealthLocked(now)
        }

        private fun markPaused() = synchronized(stateLock) {
            if (stateIsRecording && !stateIsPaused) {
                stateIsPaused = true
                statePausedAtMillis = SystemClock.elapsedRealtime()
                updateFileHealthLocked(statePausedAtMillis)
            }
        }

        private fun markResumed() = synchronized(stateLock) {
            if (stateIsRecording && stateIsPaused) {
                val now = SystemClock.elapsedRealtime()
                if (statePausedAtMillis > 0L) {
                    statePausedTotalMillis +=
                        now - statePausedAtMillis
                }
                stateIsPaused = false
                statePausedAtMillis = 0L
                stateLastFileGrowthAtMillis = now
                updateFileHealthLocked(now)
            }
        }

        private fun markStopped() = synchronized(stateLock) {
            updateFileHealthLocked(SystemClock.elapsedRealtime())
            stateIsRecording = false
            stateIsPaused = false
            statePath = null
            stateStartedAtMillis = 0L
            statePausedAtMillis = 0L
            statePausedTotalMillis = 0L
            stateRecorderPresent = false
            stateHasStarted = false
            stateLastObservedSizeBytes = 0L
            stateLastFileGrowthAtMillis = 0L
        }

        private fun refreshFileHealth() = synchronized(stateLock) {
            updateFileHealthLocked(SystemClock.elapsedRealtime())
        }

        private fun shouldContinueHealthMonitor(): Boolean = synchronized(stateLock) {
            stateIsRecording
        }

        private fun updateFileHealthLocked(now: Long = SystemClock.elapsedRealtime()) {
            val path = statePath
            if (path.isNullOrEmpty()) {
                stateFileExists = false
                stateFileSizeBytes = 0L
                stateLastModifiedMillis = 0L
                return
            }

            val file = File(path)
            stateFileExists = file.exists()
            stateFileSizeBytes = if (stateFileExists) file.length() else 0L
            stateLastModifiedMillis = if (stateFileExists) file.lastModified() else 0L

            if (stateFileSizeBytes > stateLastObservedSizeBytes) {
                stateLastFileGrowthAtMillis = now
            }
            stateLastObservedSizeBytes = stateFileSizeBytes
        }
    }

    private var recorder: MediaRecorder? = null
    private var hasStarted: Boolean = false
    private var currentPath: String? = null
    private val healthHandler = Handler(Looper.getMainLooper())
    private val healthPollIntervalMillis = 2_000L
    private val healthPoll = object : Runnable {
        override fun run() {
            refreshFileHealth()
            if (shouldContinueHealthMonitor()) {
                healthHandler.postDelayed(this, healthPollIntervalMillis)
            }
        }
    }

    // Keep CPU on while screen is locked so recording continues reliably
    private var wakeLock: PowerManager.WakeLock? = null

    private val channelId = "study_buddy_recorder"
    private val notifId = 1001

    private fun startHealthMonitor() {
        healthHandler.removeCallbacks(healthPoll)
        healthHandler.post(healthPoll)
    }

    private fun stopHealthMonitor() {
        healthHandler.removeCallbacks(healthPoll)
        refreshFileHealth()
    }

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
            startHealthMonitor()

        } catch (e: Exception) {
            // If anything fails, make sure we release cleanly so next start works
            try { r.reset() } catch (_: Exception) {}
            try { r.release() } catch (_: Exception) {}
            recorder = null
            hasStarted = false
            currentPath = null
            shutdownAfterStartFailure()
        }
    }

    private fun stopRecordingInternal() {
        val r = recorder
        if (r == null) {
            stopHealthMonitor()
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
            stopHealthMonitor()
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
            .setContentTitle(getString(R.string.recording_notification_title))
            .setContentText(getString(R.string.recording_notification_body))
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
                getString(R.string.recording_channel_name),
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

    private fun shutdownAfterStartFailure() {
        stopHealthMonitor()
        markStopped()
        releaseWakeLock()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (_: Exception) {}
        stopSelf()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
