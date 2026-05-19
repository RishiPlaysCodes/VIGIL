package com.vigil.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Foreground service that keeps pocket detection running in the background.
 *
 * Android kills background apps aggressively. A foreground service with
 * a persistent notification ensures sensors keep monitoring even when
 * the app is not in the foreground.
 *
 * This service is started when Pocket Mode is activated and stopped
 * when it's deactivated.
 */
class VigilForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "vigil_foreground_service"
        const val NOTIFICATION_ID = 2001
        const val ACTION_START = "com.vigil.app.START_FOREGROUND"
        const val ACTION_STOP = "com.vigil.app.STOP_FOREGROUND"
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startForegroundService()
            ACTION_STOP -> stopSelf()
        }
        return START_STICKY // Restart if killed
    }

    private fun startForegroundService() {
        createNotificationChannel()

        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Pause action
        val pauseIntent = Intent(NotificationHelper.ACTION_PAUSE_5_MIN)
        val pausePendingIntent = PendingIntent.getBroadcast(
            this, 1, pauseIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Stop action
        val stopIntent = Intent(NotificationHelper.ACTION_STOP_POCKET_MODE)
        val stopPendingIntent = PendingIntent.getBroadcast(
            this, 2, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Vigil - Protection Active")
            .setContentText("Pocket mode is monitoring your phone")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .addAction(0, "Using phone - pause 5 min", pausePendingIntent)
            .addAction(0, "Stop", stopPendingIntent)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Vigil Protection Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps pocket detection running in background"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        stopForeground(STOP_FOREGROUND_REMOVE)
    }
}
