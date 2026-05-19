package com.vigil.app

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.ImageFormat
import android.hardware.camera2.*
import android.media.Image
import android.media.ImageReader
import android.os.Environment
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*

/**
 * Handles front camera photo capture for intruder evidence.
 *
 * IMPORTANT: This capture happens ONLY when the safety screen is visible
 * (after grace period expires). Android restricts background camera use,
 * so we capture through the visible emergency flow.
 *
 * Flow:
 * 1. Safety check screen is shown (screen is awake and visible)
 * 2. CameraHelper.capturePhoto() is called
 * 3. Front camera opens silently, captures one frame
 * 4. Image saved to private app storage
 * 5. Path returned to Flutter for upload to backend
 */
class CameraHelper(private val context: Context) {

    companion object {
        private const val TAG = "VigilCamera"
        private const val CAMERA_PERMISSION_CODE = 1001
    }

    private var cameraDevice: CameraDevice? = null
    private var imageReader: ImageReader? = null
    private var backgroundHandler: Handler? = null
    private var backgroundThread: HandlerThread? = null

    /**
     * Capture a photo from the front camera.
     * Called when the safety check screen is already visible.
     *
     * @param camera "front" or "back"
     * @param quality JPEG quality (1-100)
     * @param callback Returns the file path of the captured photo, or null on failure
     */
    fun capturePhoto(camera: String, quality: Int, callback: (String?) -> Unit) {
        if (!hasPermission()) {
            Log.e(TAG, "Camera permission not granted")
            callback(null)
            return
        }

        try {
            startBackgroundThread()

            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameraId = getCameraId(cameraManager, camera)

            if (cameraId == null) {
                Log.e(TAG, "No $camera camera found")
                callback(null)
                return
            }

            // Get camera characteristics for resolution
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val streamConfigMap = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
            val jpegSizes = streamConfigMap?.getOutputSizes(ImageFormat.JPEG)

            // Use a medium resolution for balance of quality and speed
            val width = jpegSizes?.firstOrNull()?.width ?: 1280
            val height = jpegSizes?.firstOrNull()?.height ?: 960

            imageReader = ImageReader.newInstance(width, height, ImageFormat.JPEG, 1)
            imageReader?.setOnImageAvailableListener({ reader ->
                val image: Image? = reader.acquireLatestImage()
                if (image != null) {
                    val photoPath = saveImage(image, quality)
                    image.close()
                    closeCamera()
                    callback(photoPath)
                } else {
                    closeCamera()
                    callback(null)
                }
            }, backgroundHandler)

            // Open camera
            if (ActivityCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
                == PackageManager.PERMISSION_GRANTED
            ) {
                cameraManager.openCamera(cameraId, object : CameraDevice.StateCallback() {
                    override fun onOpened(device: CameraDevice) {
                        cameraDevice = device
                        takePicture()
                    }

                    override fun onDisconnected(device: CameraDevice) {
                        device.close()
                        cameraDevice = null
                        callback(null)
                    }

                    override fun onError(device: CameraDevice, error: Int) {
                        device.close()
                        cameraDevice = null
                        Log.e(TAG, "Camera open error: $error")
                        callback(null)
                    }
                }, backgroundHandler)
            } else {
                callback(null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Capture failed: ${e.message}")
            closeCamera()
            callback(null)
        }
    }

    /**
     * Create a capture request and take the picture.
     */
    private fun takePicture() {
        try {
            val device = cameraDevice ?: return
            val reader = imageReader ?: return
            val surface = reader.surface

            val captureBuilder = device.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)
            captureBuilder.addTarget(surface)

            // Auto settings for best quality in any lighting
            captureBuilder.set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO)
            captureBuilder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_AUTO)
            captureBuilder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON)
            // No flash to avoid alerting the intruder
            captureBuilder.set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_OFF)

            device.createCaptureSession(
                listOf(surface),
                object : CameraCaptureSession.StateCallback() {
                    override fun onConfigured(session: CameraCaptureSession) {
                        try {
                            session.capture(
                                captureBuilder.build(),
                                null,
                                backgroundHandler
                            )
                        } catch (e: Exception) {
                            Log.e(TAG, "Capture session error: ${e.message}")
                        }
                    }

                    override fun onConfigureFailed(session: CameraCaptureSession) {
                        Log.e(TAG, "Capture session configure failed")
                    }
                },
                backgroundHandler
            )
        } catch (e: Exception) {
            Log.e(TAG, "takePicture error: ${e.message}")
        }
    }

    /**
     * Save captured image to private app storage.
     * Returns the file path.
     */
    private fun saveImage(image: Image, quality: Int): String? {
        return try {
            val buffer = image.planes[0].buffer
            val bytes = ByteArray(buffer.remaining())
            buffer.get(bytes)

            // Save to app-private directory (not gallery)
            val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val fileName = "intruder_$timestamp.jpg"
            val dir = File(context.filesDir, "intruder_photos")
            if (!dir.exists()) dir.mkdirs()

            val file = File(dir, fileName)
            FileOutputStream(file).use { fos ->
                fos.write(bytes)
                fos.flush()
            }

            Log.d(TAG, "Photo saved: ${file.absolutePath}")
            file.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "Save image failed: ${e.message}")
            null
        }
    }

    /**
     * Get the camera ID for front or back camera.
     */
    private fun getCameraId(manager: CameraManager, facing: String): String? {
        val lensFacing = if (facing == "front") {
            CameraCharacteristics.LENS_FACING_FRONT
        } else {
            CameraCharacteristics.LENS_FACING_BACK
        }

        for (id in manager.cameraIdList) {
            val characteristics = manager.getCameraCharacteristics(id)
            if (characteristics.get(CameraCharacteristics.LENS_FACING) == lensFacing) {
                return id
            }
        }
        return null
    }

    /**
     * Check if camera permission is granted.
     */
    fun hasPermission(): Boolean {
        return ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
                PackageManager.PERMISSION_GRANTED
    }

    /**
     * Request camera permission from the user.
     */
    fun requestPermission(activity: Activity): Boolean {
        if (hasPermission()) return true
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.CAMERA),
            CAMERA_PERMISSION_CODE
        )
        return false // Will be granted asynchronously
    }

    /**
     * Start background thread for camera operations.
     */
    private fun startBackgroundThread() {
        backgroundThread = HandlerThread("VigilCameraThread").also { it.start() }
        backgroundHandler = Handler(backgroundThread!!.looper)
    }

    /**
     * Stop background thread.
     */
    private fun stopBackgroundThread() {
        backgroundThread?.quitSafely()
        try {
            backgroundThread?.join()
            backgroundThread = null
            backgroundHandler = null
        } catch (e: InterruptedException) {
            e.printStackTrace()
        }
    }

    /**
     * Close camera and release resources.
     */
    private fun closeCamera() {
        cameraDevice?.close()
        cameraDevice = null
        imageReader?.close()
        imageReader = null
        stopBackgroundThread()
    }
}
