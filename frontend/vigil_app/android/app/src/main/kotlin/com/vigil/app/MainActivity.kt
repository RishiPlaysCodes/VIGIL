package com.vigil.app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // Platform channels
    private val SENSOR_CHANNEL = "com.vigil.app/sensors"
    private val PROXIMITY_CHANNEL = "com.vigil.app/proximity"
    private val LIGHT_CHANNEL = "com.vigil.app/light"
    private val ACCELEROMETER_CHANNEL = "com.vigil.app/accelerometer"
    private val GYROSCOPE_CHANNEL = "com.vigil.app/gyroscope"
    private val ALARM_CHANNEL = "com.vigil.app/alarm"
    private val CAMERA_CHANNEL = "com.vigil.app/camera"
    private val NOTIFICATION_CHANNEL = "com.vigil.app/notifications"
    private val LOCATION_CHANNEL = "com.vigil.app/location"
    private val LOCATION_STREAM_CHANNEL = "com.vigil.app/location_stream"

    // Services
    private lateinit var sensorService: SensorService
    private lateinit var alarmService: AlarmServiceHelper
    private lateinit var cameraHelper: CameraHelper
    private lateinit var notificationHelper: NotificationHelper
    private lateinit var locationHelper: LocationHelper

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize helpers
        sensorService = SensorService(this)
        alarmService = AlarmServiceHelper(this)
        cameraHelper = CameraHelper(this)
        notificationHelper = NotificationHelper(this, flutterEngine)
        locationHelper = LocationHelper(this)

        // === SENSOR METHOD CHANNEL ===
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SENSOR_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkSensors" -> {
                        result.success(sensorService.checkAvailableSensors())
                    }
                    else -> result.notImplemented()
                }
            }

        // === SENSOR EVENT CHANNELS ===
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PROXIMITY_CHANNEL)
            .setStreamHandler(sensorService.getProximityStreamHandler())

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LIGHT_CHANNEL)
            .setStreamHandler(sensorService.getLightStreamHandler())

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, ACCELEROMETER_CHANNEL)
            .setStreamHandler(sensorService.getAccelerometerStreamHandler())

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, GYROSCOPE_CHANNEL)
            .setStreamHandler(sensorService.getGyroscopeStreamHandler())

        // === ALARM METHOD CHANNEL ===
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "wakeScreen" -> {
                        alarmService.wakeScreen()
                        result.success(true)
                    }
                    "playAlarm" -> {
                        val ringtone = call.argument<String>("ringtone") ?: "default_alarm"
                        val loop = call.argument<Boolean>("loop") ?: true
                        val maxVolume = call.argument<Boolean>("maxVolume") ?: true
                        alarmService.playAlarm(ringtone, loop, maxVolume)
                        result.success(true)
                    }
                    "stopAlarm" -> {
                        alarmService.stopAlarm()
                        result.success(true)
                    }
                    "setMaxVolume" -> {
                        alarmService.setMaxVolume()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // === CAMERA METHOD CHANNEL ===
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CAMERA_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "capturePhoto" -> {
                        val camera = call.argument<String>("camera") ?: "front"
                        val quality = call.argument<Int>("quality") ?: 80
                        cameraHelper.capturePhoto(camera, quality) { photoPath ->
                            result.success(photoPath)
                        }
                    }
                    "requestCameraPermission" -> {
                        result.success(cameraHelper.requestPermission(this))
                    }
                    "hasCameraPermission" -> {
                        result.success(cameraHelper.hasPermission())
                    }
                    else -> result.notImplemented()
                }
            }

        // === NOTIFICATION METHOD CHANNEL ===
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        notificationHelper.initialize()
                        result.success(true)
                    }
                    "showNotification" -> {
                        val id = call.argument<Int>("id") ?: 0
                        val title = call.argument<String>("title") ?: ""
                        val body = call.argument<String>("body") ?: ""
                        val ongoing = call.argument<Boolean>("ongoing") ?: false
                        val channelId = call.argument<String>("channelId") ?: "vigil_default"
                        val channelName = call.argument<String>("channelName") ?: "Vigil"
                        val importance = call.argument<String>("importance") ?: "default"
                        val actions = call.argument<List<Map<String, String>>>("actions")
                        notificationHelper.showNotification(
                            id, title, body, ongoing, channelId, channelName, importance, actions
                        )
                        result.success(true)
                    }
                    "cancelNotification" -> {
                        val id = call.argument<Int>("id") ?: 0
                        notificationHelper.cancelNotification(id)
                        result.success(true)
                    }
                    "cancelAllNotifications" -> {
                        notificationHelper.cancelAll()
                        result.success(true)
                    }
                    "requestPermission" -> {
                        result.success(notificationHelper.requestPermission(this))
                    }
                    else -> result.notImplemented()
                }
            }

        // === LOCATION METHOD CHANNEL ===
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLocationUpdates" -> {
                        val interval = call.argument<Int>("interval") ?: 30000
                        val distanceFilter = call.argument<Double>("distanceFilter") ?: 50.0
                        val accuracy = call.argument<String>("accuracy") ?: "balanced"
                        locationHelper.startUpdates(interval.toLong(), distanceFilter.toFloat(), accuracy)
                        result.success(true)
                    }
                    "stopLocationUpdates" -> {
                        locationHelper.stopUpdates()
                        result.success(true)
                    }
                    "getLastKnownLocation" -> {
                        locationHelper.getLastKnownLocation { location ->
                            result.success(location)
                        }
                    }
                    "requestLocationPermission" -> {
                        result.success(locationHelper.requestPermission(this))
                    }
                    else -> result.notImplemented()
                }
            }

        // === LOCATION EVENT CHANNEL ===
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_STREAM_CHANNEL)
            .setStreamHandler(locationHelper.getLocationStreamHandler())
    }

    override fun onDestroy() {
        super.onDestroy()
        sensorService.stopAll()
        alarmService.stopAlarm()
        locationHelper.stopUpdates()
    }
}
