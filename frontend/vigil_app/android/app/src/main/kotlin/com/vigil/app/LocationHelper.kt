package com.vigil.app

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.*
import io.flutter.plugin.common.EventChannel

/**
 * Handles background location tracking using Google Fused Location Provider.
 *
 * Modes:
 * - Normal: updates every 30s with 50m distance filter (battery friendly)
 * - High Frequency: updates every 5s with 5m filter (during active alert)
 *
 * Features:
 * - Continuous background updates via FusedLocationProviderClient
 * - Battery-efficient with configurable intervals
 * - Streams location to Flutter via EventChannel
 * - Provides last known location for immediate use
 */
class LocationHelper(private val context: Context) {

    companion object {
        private const val LOCATION_PERMISSION_CODE = 1003
    }

    private var fusedLocationClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)

    private var locationCallback: LocationCallback? = null
    private var locationEventSink: EventChannel.EventSink? = null
    private var isUpdating = false

    /**
     * Start location updates with specified parameters.
     *
     * @param intervalMs Update interval in milliseconds
     * @param distanceFilter Minimum distance change in meters to trigger update
     * @param accuracy "high", "balanced", or "low"
     */
    fun startUpdates(intervalMs: Long, distanceFilter: Float, accuracy: String) {
        if (!hasPermission()) return

        // Stop existing updates
        stopUpdates()

        val priority = when (accuracy) {
            "high" -> Priority.PRIORITY_HIGH_ACCURACY
            "balanced" -> Priority.PRIORITY_BALANCED_POWER_ACCURACY
            "low" -> Priority.PRIORITY_LOW_POWER
            else -> Priority.PRIORITY_BALANCED_POWER_ACCURACY
        }

        val locationRequest = LocationRequest.Builder(priority, intervalMs)
            .setMinUpdateDistanceMeters(distanceFilter)
            .setWaitForAccurateLocation(false)
            .build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let { location ->
                    sendLocationToFlutter(location)
                }
            }
        }

        try {
            if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION)
                == PackageManager.PERMISSION_GRANTED
            ) {
                fusedLocationClient.requestLocationUpdates(
                    locationRequest,
                    locationCallback!!,
                    Looper.getMainLooper()
                )
                isUpdating = true
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Stop location updates.
     */
    fun stopUpdates() {
        locationCallback?.let {
            fusedLocationClient.removeLocationUpdates(it)
        }
        locationCallback = null
        isUpdating = false
    }

    /**
     * Get last known location (for immediate use during alert creation).
     */
    fun getLastKnownLocation(callback: (Map<String, Any>?) -> Unit) {
        if (!hasPermission()) {
            callback(null)
            return
        }

        try {
            if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION)
                == PackageManager.PERMISSION_GRANTED
            ) {
                fusedLocationClient.lastLocation
                    .addOnSuccessListener { location: Location? ->
                        if (location != null) {
                            callback(
                                mapOf(
                                    "latitude" to location.latitude,
                                    "longitude" to location.longitude,
                                    "accuracy" to location.accuracy.toDouble(),
                                    "altitude" to location.altitude,
                                    "speed" to location.speed.toDouble()
                                )
                            )
                        } else {
                            callback(null)
                        }
                    }
                    .addOnFailureListener {
                        callback(null)
                    }
            } else {
                callback(null)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            callback(null)
        }
    }

    /**
     * Send location data to Flutter via EventChannel sink.
     */
    private fun sendLocationToFlutter(location: Location) {
        val data = mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "accuracy" to location.accuracy.toDouble(),
            "altitude" to location.altitude,
            "speed" to location.speed.toDouble(),
            "bearing" to location.bearing.toDouble(),
            "timestamp" to location.time
        )
        locationEventSink?.success(data)
    }

    /**
     * Get EventChannel StreamHandler for location updates.
     */
    fun getLocationStreamHandler(): EventChannel.StreamHandler {
        return object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                locationEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                locationEventSink = null
            }
        }
    }

    /**
     * Check if location permissions are granted.
     */
    private fun hasPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Request location permissions (fine + background).
     */
    fun requestPermission(activity: Activity): Boolean {
        if (hasPermission()) return true

        val permissions = mutableListOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )

        // Background location requires separate request on Android 10+
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            // First request foreground, then background separately
            ActivityCompat.requestPermissions(
                activity,
                permissions.toTypedArray(),
                LOCATION_PERMISSION_CODE
            )
        } else {
            ActivityCompat.requestPermissions(
                activity,
                permissions.toTypedArray(),
                LOCATION_PERMISSION_CODE
            )
        }
        return false
    }
}
