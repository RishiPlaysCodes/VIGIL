package com.example.pocket_guardian

import android.Manifest
import android.content.Intent
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.telephony.SmsManager
import java.io.File
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "pocket_guardian/native"
    private var alarmRingtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playAlarm" -> {
                        playAlarm()
                        result.success(true)
                    }
                    "stopAlarm" -> {
                        alarmRingtone?.stop()
                        result.success(true)
                    }
                    "sendSms" -> {
                        val phone = call.argument<String>("phone").orEmpty()
                        val message = call.argument<String>("message").orEmpty()
                        result.success(sendSms(phone, message))
                    }
                    "placeCall" -> {
                        val phone = call.argument<String>("phone").orEmpty()
                        result.success(placeCall(phone))
                    }
                    "startPocketGuardService" -> {
                        startPocketGuardService()
                        result.success(true)
                    }
                    "stopPocketGuardService" -> {
                        stopService(Intent(this, PocketGuardService::class.java))
                        result.success(true)
                    }
                    "requestEmergencyPermissions" -> {
                        requestEmergencyPermissions()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun playAlarm() {
        val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        alarmRingtone = RingtoneManager.getRingtone(applicationContext, uri)
        alarmRingtone?.audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        alarmRingtone?.play()
    }

    companion object {
        private var emergencyRingtone: Ringtone? = null

        fun triggerNativeAlarm(context: android.content.Context) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val customPath = prefs.getString("flutter.custom_ringtone_path", null)
            val uri = if (!customPath.isNullOrBlank() && File(customPath).exists()) {
                Uri.fromFile(File(customPath))
            } else {
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            }
            val ringtone = RingtoneManager.getRingtone(context.applicationContext, uri)
            ringtone.audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            emergencyRingtone = ringtone
            ringtone.play()
        }

        fun stopNativeAlarm() {
            emergencyRingtone?.stop()
        }
    }

    private fun sendSms(phone: String, message: String): Boolean {
        if (phone.isBlank() || message.isBlank()) return false
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.SEND_SMS), 101)
            return false
        }
        SmsManager.getDefault().sendTextMessage(phone, null, message, null, null)
        return true
    }

    private fun placeCall(phone: String): Boolean {
        if (phone.isBlank()) return false
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CALL_PHONE), 102)
            return false
        }
        startActivity(Intent(Intent.ACTION_CALL, Uri.parse("tel:$phone")))
        return true
    }

    private fun startPocketGuardService() {
        val intent = Intent(this, PocketGuardService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun requestEmergencyPermissions() {
        val permissions = mutableListOf<String>()
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
            != PackageManager.PERMISSION_GRANTED
        ) permissions.add(Manifest.permission.SEND_SMS)
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
            != PackageManager.PERMISSION_GRANTED
        ) permissions.add(Manifest.permission.CALL_PHONE)
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        if (permissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, permissions.toTypedArray(), 103)
        }
    }
}
