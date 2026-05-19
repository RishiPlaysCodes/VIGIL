package com.vigil.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Receives notification action button taps and forwards them
 * to the Flutter layer via the running MainActivity.
 *
 * Actions:
 * - ACTION_PAUSE_5_MIN: User tapped "Using phone - pause 5 min"
 * - ACTION_STOP_POCKET_MODE: User tapped "Stop Protection"
 * - ACTION_IM_SAFE: User tapped "I Am Safe" on alert notification
 */
class NotificationActionReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "VigilActionReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        val action = intent.action ?: return
        Log.d(TAG, "Notification action received: $action")

        // Forward action to Flutter by launching/bringing app to front
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            this.action = action
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("notification_action", action)
        }
        context.startActivity(launchIntent)
    }
}
