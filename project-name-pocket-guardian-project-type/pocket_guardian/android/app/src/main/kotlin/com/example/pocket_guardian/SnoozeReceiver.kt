package com.example.pocket_guardian

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class SnoozeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        PocketGuardService.snoozeForFiveMinutes(context)
        context.startService(
            Intent(context, PocketGuardService::class.java).setAction(PocketGuardService.ACTION_REFRESH)
        )
    }
}
