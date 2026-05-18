package com.example.pocket_guardian

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat

class PocketGuardService : Service(), SensorEventListener {
    private lateinit var sensorManager: SensorManager
    private var wakeLock: PowerManager.WakeLock? = null
    private val strongMovementTimes = ArrayDeque<Long>()
    private var latestLightLux: Float? = null
    private var latestProximityCm: Float? = null
    private var maxProximityCm: Float? = null
    private var removedFromPocketAt = 0L
    private val handler = Handler(Looper.getMainLooper())
    private var removalRunnable: Runnable? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
        startForeground(3001, buildServiceNotification("Monitoring suspicious pocket movement"))

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)?.also {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
        }
        sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT)?.also {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
        }
        sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)?.also {
            maxProximityCm = it.maximumRange
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
        }
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "PocketGuardian::MotionWakeLock"
        ).apply { acquire(10 * 60 * 1000L) }
    }

    override fun onDestroy() {
        sensorManager.unregisterListener(this)
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_REFRESH) {
            refreshServiceNotification()
        }
        return START_STICKY
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    override fun onSensorChanged(event: SensorEvent?) {
        event ?: return
        when (event.sensor.type) {
            Sensor.TYPE_LIGHT -> {
                latestLightLux = event.values[0]
                updatePocketState()
                return
            }
            Sensor.TYPE_PROXIMITY -> {
                latestProximityCm = event.values[0]
                updatePocketState()
                return
            }
        }
        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]
        val magnitude = x * x + y * y + z * z
        if (magnitude < 185) return

        val now = System.currentTimeMillis()
        while (strongMovementTimes.isNotEmpty() && now - strongMovementTimes.first() > 4_000) {
            strongMovementTimes.removeFirst()
        }
        strongMovementTimes.addLast(now)
        if (isSnoozed()) return
        val withinRemovalWindow =
            removedFromPocketAt != 0L && now - removedFromPocketAt <= 20_000
        if (strongMovementTimes.size >= 2 && withinRemovalWindow && !emergencyOpen) {
            launchEmergencyActivity()
            strongMovementTimes.clear()
        }
    }

    private fun isRemovedFromPocketLikely(): Boolean {
        val lightSuggestsOutside = latestLightLux?.let { it >= 8f } ?: false
        val proximitySuggestsOutside =
            latestProximityCm != null &&
                maxProximityCm != null &&
                latestProximityCm!! >= maxProximityCm!!
        return lightSuggestsOutside || proximitySuggestsOutside
    }

    private fun updatePocketState() {
        if (isRemovedFromPocketLikely()) {
            if (removedFromPocketAt == 0L) {
                removedFromPocketAt = System.currentTimeMillis()
                refreshServiceNotification()
                scheduleRemovalTimeout()
            }
        } else {
            removedFromPocketAt = 0L
            removalRunnable?.let(handler::removeCallbacks)
            refreshServiceNotification()
        }
    }

    private fun scheduleRemovalTimeout() {
        removalRunnable?.let(handler::removeCallbacks)
        val graceSeconds = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            .getInt("flutter.removal_grace_seconds", 3)
        removalRunnable = Runnable {
            if (!isSnoozed() && removedFromPocketAt != 0L && !emergencyOpen) {
                launchEmergencyActivity()
            }
        }.also { handler.postDelayed(it, graceSeconds * 1000L) }
    }

    private fun launchEmergencyActivity() {
        emergencyOpen = true
        val intent = Intent(this, EmergencyActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            7001,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val manager = getSystemService(NotificationManager::class.java)
        val notification = NotificationCompat.Builder(this, "pocket_guard_alarm")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentTitle("Pocket Guardian Alert")
            .setContentText("Suspicious movement detected")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(pendingIntent, true)
            .setContentIntent(pendingIntent)
            .setAutoCancel(false)
            .build()
        manager.notify(7001, notification)
    }

    private fun buildServiceNotification(text: String): android.app.Notification {
        val snoozeIntent = Intent(this, SnoozeReceiver::class.java)
        val snoozePendingIntent = PendingIntent.getBroadcast(
            this,
            3002,
            snoozeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, "pocket_guard")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentTitle("Vigil active")
            .setContentText(text)
            .setOngoing(true)
            .addAction(
                android.R.drawable.ic_media_pause,
                "Using phone — pause 5 min",
                snoozePendingIntent
            )
            .build()
    }

    private fun isSnoozed(): Boolean {
        val until = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            .getLong("flutter.snoozed_until", 0L)
        return System.currentTimeMillis() < until
    }

    private fun refreshServiceNotification() {
        val manager = getSystemService(NotificationManager::class.java)
        val text = when {
            isSnoozed() -> "Paused for 5 minutes"
            removedFromPocketAt != 0L -> "Phone appears out of pocket"
            else -> "Monitoring suspicious pocket movement"
        }
        manager.notify(3001, buildServiceNotification(text))
    }

    companion object {
        const val ACTION_REFRESH = "com.example.pocket_guardian.REFRESH"
        private var emergencyOpen = false

        fun markEmergencyClosed() {
            emergencyOpen = false
        }

        fun snoozeForFiveMinutes(context: Context) {
            val until = System.currentTimeMillis() + 5 * 60 * 1000L
            context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .edit()
                .putLong("flutter.snoozed_until", until)
                .apply()
        }
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "pocket_guard",
                "Pocket Guardian",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                lightColor = Color.CYAN
                enableLights(true)
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
            val alarmChannel = NotificationChannel(
                "pocket_guard_alarm",
                "Pocket Guardian Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                enableLights(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(alarmChannel)
        }
    }
}
