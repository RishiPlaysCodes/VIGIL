package com.vigil.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log

/**
 * Receives BOOT_COMPLETED broadcast to restart the foreground service
 * after device reboot, if pocket mode was previously enabled.
 *
 * This ensures protection persists across reboots.
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "VigilBootReceiver"
        private const val PREFS_NAME = "vigil_prefs"
        private const val KEY_POCKET_MODE_ACTIVE = "pocket_mode_active"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null) return

        val action = intent?.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            Log.d(TAG, "Device booted - checking if pocket mode was active")

            // Check if pocket mode was active before reboot
            val prefs: SharedPreferences =
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val wasPocketModeActive = prefs.getBoolean(KEY_POCKET_MODE_ACTIVE, false)

            if (wasPocketModeActive) {
                Log.d(TAG, "Restarting Vigil foreground service")
                val serviceIntent = Intent(context, VigilForegroundService::class.java).apply {
                    this.action = VigilForegroundService.ACTION_START
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        }
    }
}
