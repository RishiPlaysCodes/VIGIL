package com.example.pocket_guardian

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraMetadata
import android.hardware.camera2.CaptureRequest
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import android.os.Build
import android.os.Bundle
import android.os.CountDownTimer
import android.telephony.SmsManager
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone
import java.io.File
import java.io.FileOutputStream

class EmergencyActivity : Activity() {
    private lateinit var timerText: TextView
    private lateinit var actionButton: Button
    private var timer: CountDownTimer? = null
    private var alarmStarted = false
    private var cameraThread: HandlerThread? = null
    private var cameraHandler: Handler? = null
    private var imageReader: ImageReader? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val imagePath = prefs.getString("flutter.lock_screen_image_path", null)
        val avatar = prefs.getInt("flutter.safety_avatar", 0)
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(32, 32, 32, 32)
            setBackgroundColor(0xFF111827.toInt())
        }
        val bitmap = imagePath?.let { decodeScaledBitmap(it, 720, 720) }
        if (avatar == 3 && bitmap != null) {
            layout.addView(ImageView(this).apply {
                adjustViewBounds = true
                maxHeight = 520
                setImageBitmap(bitmap)
            })
        } else {
            layout.addView(TextView(this).apply {
                text = when (avatar) {
                    1 -> "🦊"
                    2 -> "🐉"
                    else -> "🛡️"
                }
                textSize = 96f
                gravity = Gravity.CENTER
            })
        }
        layout.addView(TextView(this).apply {
            text = "Pocket Guardian Check"
            textSize = 28f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
        })
        layout.addView(TextView(this).apply {
            text = "Are you safe?"
            textSize = 20f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
        })
        timerText = TextView(this).apply {
            textSize = 18f
            setTextColor(0xFFFFE08A.toInt())
            gravity = Gravity.CENTER
        }
        layout.addView(timerText)
        actionButton = Button(this).apply {
            text = "I am safe — stop check"
            setOnClickListener {
                timer?.cancel()
                if (alarmStarted) MainActivity.stopNativeAlarm()
                clearEmergencyNotification()
                finish()
            }
        }
        layout.addView(actionButton)
        setContentView(layout)
        captureNativePhoto()
        startSafetyCountdown()
    }

    private fun startSafetyCountdown() {
        timer = object : CountDownTimer(10_000, 1_000) {
            override fun onTick(millisUntilFinished: Long) {
                timerText.text = "Alarm starts in ${millisUntilFinished / 1000}s"
            }

            override fun onFinish() {
                alarmStarted = true
                timerText.text = "No response — alarm active"
                actionButton.text = "Stop alarm — I am safe"
                getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                    .edit()
                    .putBoolean("flutter.pending_intruder_capture", true)
                    .apply()
                MainActivity.triggerNativeAlarm(this@EmergencyActivity)
                sendEmergencySms()
                syncEmergencyAlert()
            }
        }.start()
    }

    private fun sendEmergencySms() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val phone = prefs.getString("flutter.contact_phone", "").orEmpty().replace(" ", "")
        val location = prefs.getString("flutter.last_known_location", "Location unavailable").orEmpty()
        if (phone.isBlank()) return
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
            != PackageManager.PERMISSION_GRANTED
        ) return
        SmsManager.getDefault().sendTextMessage(
            phone,
            null,
            "Pocket Guardian alert: no safety response after suspicious movement. Location: $location",
            null,
            null
        )
    }

    private fun clearEmergencyNotification() {
        getSystemService(NotificationManager::class.java).cancel(7001)
    }

    private fun syncEmergencyAlert() {
        Thread {
            try {
                val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                val baseUrl = prefs.getString("flutter.api_base_url", null).orEmpty()
                val userId = prefs.getInt("flutter.backend_user_id", -1)
                val token = prefs.getString("flutter.api_token", null).orEmpty()
                if (baseUrl.isBlank() || userId <= 0 || token.isBlank()) return@Thread
                val parts = prefs.getString("flutter.last_known_location", "").orEmpty()
                    .split(",")
                    .map { it.trim() }
                val payload = JSONObject().apply {
                    put("reason", "lock-screen safety check timed out")
                    put("status", "triggered")
                    put("occurred_at", isoNow())
                    put("latitude", parts.getOrNull(0)?.toDoubleOrNull())
                    put("longitude", parts.getOrNull(1)?.toDoubleOrNull())
                    put("photo_path", "")
                }
                val connection = URL("$baseUrl/users/$userId/alerts/").openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Authorization", "Token $token")
                connection.doOutput = true
                connection.outputStream.use { it.write(payload.toString().toByteArray()) }
                if (connection.responseCode in 200..299) {
                    val responseText = connection.inputStream.bufferedReader().use { it.readText() }
                    val response = JSONObject(responseText)
                    val alertId = response.optInt("id", -1)
                    if (alertId > 0) {
                        prefs.edit().putInt("flutter.native_alert_id", alertId).apply()
                    }
                }
                connection.disconnect()
            } catch (_: Exception) {
                // The local alarm must still work even if the network is unavailable.
            }
        }.start()
    }

    private fun captureNativePhoto() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
            != PackageManager.PERMISSION_GRANTED
        ) return
        try {
            cameraThread = HandlerThread("VigilCamera").also { it.start() }
            cameraHandler = Handler(cameraThread!!.looper)
            val manager = getSystemService(CAMERA_SERVICE) as CameraManager
            val cameraId = manager.cameraIdList.firstOrNull { id ->
                manager.getCameraCharacteristics(id)
                    .get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_FRONT
            } ?: return
            imageReader = ImageReader.newInstance(640, 480, android.graphics.ImageFormat.JPEG, 1)
            imageReader?.setOnImageAvailableListener({ reader ->
                reader.acquireLatestImage()?.use { image ->
                    val buffer = image.planes[0].buffer
                    val bytes = ByteArray(buffer.remaining())
                    buffer.get(bytes)
                    val file = File(cacheDir, "native_intruder_${System.currentTimeMillis()}.jpg")
                    FileOutputStream(file).use { it.write(bytes) }
                    getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                        .edit()
                        .putString("flutter.native_intruder_photo_path", file.absolutePath)
                        .apply()
                }
            }, cameraHandler)
            manager.openCamera(cameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    val target = imageReader?.surface ?: return
                    val request = camera.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE).apply {
                        addTarget(target)
                        set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO)
                    }
                    camera.createCaptureSession(
                        listOf(target),
                        object : android.hardware.camera2.CameraCaptureSession.StateCallback() {
                            override fun onConfigured(session: android.hardware.camera2.CameraCaptureSession) {
                                session.capture(request.build(), null, cameraHandler)
                            }
                            override fun onConfigureFailed(session: android.hardware.camera2.CameraCaptureSession) = Unit
                        },
                        cameraHandler
                    )
                }
                override fun onDisconnected(camera: CameraDevice) = camera.close()
                override fun onError(camera: CameraDevice, error: Int) = camera.close()
            }, cameraHandler)
        } catch (_: CameraAccessException) {
        }
    }

    private fun decodeScaledBitmap(path: String, reqWidth: Int, reqHeight: Int): android.graphics.Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        var sampleSize = 1
        while (
            bounds.outHeight / sampleSize > reqHeight ||
            bounds.outWidth / sampleSize > reqWidth
        ) {
            sampleSize *= 2
        }
        val options = BitmapFactory.Options().apply { inSampleSize = sampleSize.coerceAtLeast(1) }
        return BitmapFactory.decodeFile(path, options)
    }

    private fun isoNow(): String {
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        format.timeZone = TimeZone.getTimeZone("UTC")
        return format.format(System.currentTimeMillis())
    }

    override fun onDestroy() {
        timer?.cancel()
        imageReader?.close()
        cameraThread?.quitSafely()
        PocketGuardService.markEmergencyClosed()
        super.onDestroy()
    }
}
