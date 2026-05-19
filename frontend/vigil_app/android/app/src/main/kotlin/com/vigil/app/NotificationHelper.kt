package com.vigil.app

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Handles notification display with action buttons.
 *
 * Notification types:
 * 1. Pocket Mode persistent notification - "Using phone - pause 5 min" action
 * 2. Alert notification - high priority with "I Am Safe" action
 * 3. Location tracking notification - silent persistent
 *
 * Action buttons communicate back to Flutter via MethodChannel callbacks.
 */
class NotificationHelper(
    private val context: Context,
    private val flutterEngine: FlutterEngine
) {

    companion object {
        private const val NOTIFICATION_PERMISSION_CODE = 1002
        const val ACTION_PAUSE_5_MIN = "com.vigil.app.ACTION_PAUSE_5_MIN"
        const val ACTION_STOP_POCKET_MODE = "com.vigil.app.ACTION_STOP_POCKET_MODE"
        const val ACTION_IM_SAFE = "com.vigil.app.ACTION_IM_SAFE"
    }

    private val notificationManager: NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private var actionReceiver: BroadcastReceiver? = null

    /**
     * Initialize notification channels and register action receiver.
     */
    fun initialize() {
        createNotificationChannels()
        registerActionReceiver()
    }

    /**
     * Create all required notification channels (Android 8.0+).
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Pocket Mode channel (low priority, silent)
            val pocketChannel = NotificationChannel(
                "vigil_pocket_mode",
                "Pocket Mode",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when pocket mode protection is active"
                setShowBadge(false)
            }

            // Alert channel (high priority, with sound)
            val alertChannel = NotificationChannel(
                "vigil_alerts",
                "Safety Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Emergency safety alerts"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500)
                setShowBadge(true)
            }

            // Location channel (low priority, silent)
            val locationChannel = NotificationChannel(
                "vigil_location",
                "Location Tracking",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when location is being shared"
                setShowBadge(false)
            }

            // Default channel
            val defaultChannel = NotificationChannel(
                "vigil_default",
                "Vigil",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "General notifications"
            }

            notificationManager.createNotificationChannels(
                listOf(pocketChannel, alertChannel, locationChannel, defaultChannel)
            )
        }
    }

    /**
     * Register broadcast receiver for notification action buttons.
     * When user taps an action, it sends a callback to Flutter.
     */
    private fun registerActionReceiver() {
        actionReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val action = intent?.action ?: return
                // Send action back to Flutter via MethodChannel
                val channel = MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    "com.vigil.app/notifications"
                )
                val flutterAction = when (action) {
                    ACTION_PAUSE_5_MIN -> "ACTION_PAUSE_5_MIN"
                    ACTION_STOP_POCKET_MODE -> "ACTION_STOP_POCKET_MODE"
                    ACTION_IM_SAFE -> "ACTION_IM_SAFE"
                    else -> return
                }
                channel.invokeMethod("onNotificationAction", flutterAction)
            }
        }

        val filter = IntentFilter().apply {
            addAction(ACTION_PAUSE_5_MIN)
            addAction(ACTION_STOP_POCKET_MODE)
            addAction(ACTION_IM_SAFE)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(actionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(actionReceiver, filter)
        }
    }

    /**
     * Show a notification with optional action buttons.
     */
    fun showNotification(
        id: Int,
        title: String,
        body: String,
        ongoing: Boolean,
        channelId: String,
        channelName: String,
        importance: String,
        actions: List<Map<String, String>>?
    ) {
        val priority = when (importance) {
            "high" -> NotificationCompat.PRIORITY_HIGH
            "low" -> NotificationCompat.PRIORITY_LOW
            "min" -> NotificationCompat.PRIORITY_MIN
            else -> NotificationCompat.PRIORITY_DEFAULT
        }

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_alert) // TODO: Replace with Vigil icon
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(priority)
            .setOngoing(ongoing)
            .setAutoCancel(!ongoing)

        // Add action buttons
        actions?.forEach { action ->
            val actionId = action["id"] ?: return@forEach
            val actionTitle = action["title"] ?: return@forEach

            val intent = Intent(actionId)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                actionId.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            builder.addAction(0, actionTitle, pendingIntent)
        }

        // Open app when notification tapped
        val tapIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val tapPendingIntent = PendingIntent.getActivity(
            context, 0, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        builder.setContentIntent(tapPendingIntent)

        // Show notification
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
            == PackageManager.PERMISSION_GRANTED || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU
        ) {
            NotificationManagerCompat.from(context).notify(id, builder.build())
        }
    }

    /**
     * Cancel a specific notification.
     */
    fun cancelNotification(id: Int) {
        notificationManager.cancel(id)
    }

    /**
     * Cancel all notifications.
     */
    fun cancelAll() {
        notificationManager.cancelAll()
    }

    /**
     * Request notification permission (Android 13+).
     */
    fun requestPermission(activity: Activity): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    activity,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_CODE
                )
                return false
            }
        }
        return true
    }
}
