package com.vigil.app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.plugin.common.EventChannel

/**
 * Native sensor service that provides proximity, light, and accelerometer data
 * via EventChannel streams to the Flutter layer.
 *
 * Combines all three sensors for smart pocket detection:
 * - Proximity: near (0) = in pocket, far (max) = exposed
 * - Light: dark (low lux) = in pocket, bright = exposed
 * - Accelerometer: magnitude used to detect suspicious grab motion
 */
class SensorService(private val context: Context) {

    private val sensorManager: SensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager

    private val proximitySensor: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)
    private val lightSensor: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT)
    private val accelerometer: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

    // Event sinks for streaming sensor data to Flutter
    private var proximityEventSink: EventChannel.EventSink? = null
    private var lightEventSink: EventChannel.EventSink? = null
    private var accelerometerEventSink: EventChannel.EventSink? = null

    // Sensor listeners
    private var proximityListener: SensorEventListener? = null
    private var lightListener: SensorEventListener? = null
    private var accelerometerListener: SensorEventListener? = null

    /**
     * Check which sensors are available on this device.
     */
    fun checkAvailableSensors(): Map<String, Boolean> {
        return mapOf(
            "proximity" to (proximitySensor != null),
            "light" to (lightSensor != null),
            "accelerometer" to (accelerometer != null)
        )
    }

    /**
     * Get EventChannel StreamHandler for proximity sensor.
     * Proximity sensor: 0 = near (object close / in pocket), max = far (exposed)
     */
    fun getProximityStreamHandler(): EventChannel.StreamHandler {
        return object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                proximityEventSink = events
                startProximityListener()
            }

            override fun onCancel(arguments: Any?) {
                stopProximityListener()
                proximityEventSink = null
            }
        }
    }

    /**
     * Get EventChannel StreamHandler for light sensor.
     * Light sensor: reports ambient light in lux.
     * Dark pocket = 0-10 lux, indoor = 100-500, outdoor = 10000+
     */
    fun getLightStreamHandler(): EventChannel.StreamHandler {
        return object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                lightEventSink = events
                startLightListener()
            }

            override fun onCancel(arguments: Any?) {
                stopLightListener()
                lightEventSink = null
            }
        }
    }

    /**
     * Get EventChannel StreamHandler for accelerometer.
     * Reports x, y, z acceleration values as a Map.
     * Used to detect sudden motion (phone grab) vs normal pocket movement.
     */
    fun getAccelerometerStreamHandler(): EventChannel.StreamHandler {
        return object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                accelerometerEventSink = events
                startAccelerometerListener()
            }

            override fun onCancel(arguments: Any?) {
                stopAccelerometerListener()
                accelerometerEventSink = null
            }
        }
    }

    // === PROXIMITY SENSOR ===

    private fun startProximityListener() {
        if (proximitySensor == null) return

        proximityListener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent?) {
                event?.let {
                    // values[0] = distance in cm (0 = near, max = far)
                    proximityEventSink?.success(it.values[0].toDouble())
                }
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }

        sensorManager.registerListener(
            proximityListener,
            proximitySensor,
            SensorManager.SENSOR_DELAY_UI // ~60ms polling
        )
    }

    private fun stopProximityListener() {
        proximityListener?.let {
            sensorManager.unregisterListener(it)
        }
        proximityListener = null
    }

    // === LIGHT SENSOR ===

    private fun startLightListener() {
        if (lightSensor == null) return

        lightListener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent?) {
                event?.let {
                    // values[0] = ambient light level in lux
                    lightEventSink?.success(it.values[0].toDouble())
                }
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }

        sensorManager.registerListener(
            lightListener,
            lightSensor,
            SensorManager.SENSOR_DELAY_UI
        )
    }

    private fun stopLightListener() {
        lightListener?.let {
            sensorManager.unregisterListener(it)
        }
        lightListener = null
    }

    // === ACCELEROMETER ===

    private fun startAccelerometerListener() {
        if (accelerometer == null) return

        accelerometerListener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent?) {
                event?.let {
                    // Send x, y, z as a map to Flutter
                    val data = mapOf(
                        "x" to it.values[0].toDouble(),
                        "y" to it.values[1].toDouble(),
                        "z" to it.values[2].toDouble()
                    )
                    accelerometerEventSink?.success(data)
                }
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }

        sensorManager.registerListener(
            accelerometerListener,
            accelerometer,
            SensorManager.SENSOR_DELAY_GAME // ~20ms for accurate motion detection
        )
    }

    private fun stopAccelerometerListener() {
        accelerometerListener?.let {
            sensorManager.unregisterListener(it)
        }
        accelerometerListener = null
    }

    /**
     * Stop all sensor listeners. Called when activity is destroyed.
     */
    fun stopAll() {
        stopProximityListener()
        stopLightListener()
        stopAccelerometerListener()
        proximityEventSink = null
        lightEventSink = null
        accelerometerEventSink = null
    }
}
