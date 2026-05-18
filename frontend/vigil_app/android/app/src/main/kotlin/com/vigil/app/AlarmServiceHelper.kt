package com.vigil.app

import android.app.KeyguardManager
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.WindowManager

/**
 * Handles alarm playback, screen wake, and volume control.
 *
 * Flow:
 * 1. Grace period expires → wakeScreen() called
 * 2. Safety check not cancelled → playAlarm() called
 * 3. Alarm plays continuously at max volume with vibration
 * 4. Owner taps "I'm safe" → stopAlarm() called
 */
class AlarmServiceHelper(private val context: Context) {

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var originalVolume: Int = -1
    private val audioManager: AudioManager =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    /**
     * Wake the device screen and bring app to foreground.
     * Works even when phone is locked (uses FLAG_SHOW_WHEN_LOCKED).
     */
    fun wakeScreen() {
        try {
            // Acquire wake lock to turn on screen
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.FULL_WAKE_LOCK or
                        PowerManager.ACQUIRE_CAUSES_WAKEUP or
                        PowerManager.ON_AFTER_RELEASE,
                "vigil:alarm_wake_lock"
            )
            wakeLock?.acquire(60 * 1000L) // 60 second timeout

            // Show over lock screen (for Activity-based approach)
            if (context is MainActivity) {
                val activity = context
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                    activity.setShowWhenLocked(true)
                    activity.setTurnScreenOn(true)
                    val keyguardManager =
                        context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                    keyguardManager.requestDismissKeyguard(activity, null)
                } else {
                    @Suppress("DEPRECATION")
                    activity.window.addFlags(
                        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    )
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Play alarm sound continuously at maximum volume with vibration.
     *
     * @param ringtone Name of ringtone (currently uses system alarm default)
     * @param loop Whether to loop the alarm
     * @param maxVolume Whether to set device to maximum volume
     */
    fun playAlarm(ringtone: String, loop: Boolean, maxVolume: Boolean) {
        try {
            // Stop any existing alarm
            stopAlarm()

            // Set max volume if requested
            if (maxVolume) {
                setMaxVolume()
            }

            // Get alarm sound URI
            val alarmUri: Uri = when (ringtone) {
                "default_alarm" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                "siren" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                "emergency" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                else -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            }
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            // Create and start media player
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(context, alarmUri)
                isLooping = loop
                prepare()
                start()
            }

            // Start vibration pattern
            startVibration()

        } catch (e: Exception) {
            e.printStackTrace()
            // Fallback: try system ringtone
            try {
                val fallbackUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                mediaPlayer = MediaPlayer().apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .build()
                    )
                    setDataSource(context, fallbackUri)
                    isLooping = loop
                    prepare()
                    start()
                }
            } catch (ex: Exception) {
                ex.printStackTrace()
            }
        }
    }

    /**
     * Stop alarm playback, vibration, and release resources.
     */
    fun stopAlarm() {
        try {
            mediaPlayer?.let {
                if (it.isPlaying) {
                    it.stop()
                }
                it.release()
            }
            mediaPlayer = null

            // Stop vibration
            stopVibration()

            // Release wake lock
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                }
            }
            wakeLock = null

            // Restore original volume
            if (originalVolume >= 0) {
                audioManager.setStreamVolume(
                    AudioManager.STREAM_ALARM, originalVolume, 0
                )
                originalVolume = -1
            }

            // Remove lock screen flags
            if (context is MainActivity) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                    context.setShowWhenLocked(false)
                    context.setTurnScreenOn(false)
                } else {
                    @Suppress("DEPRECATION")
                    context.window.clearFlags(
                        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    )
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Set device alarm stream to maximum volume.
     * Saves original volume for restoration when alarm stops.
     */
    fun setMaxVolume() {
        try {
            originalVolume = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, maxVolume, 0)

            // Also set ring/notification to max in case alarm stream not used
            val maxRing = audioManager.getStreamMaxVolume(AudioManager.STREAM_RING)
            audioManager.setStreamVolume(AudioManager.STREAM_RING, maxRing, 0)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Start aggressive vibration pattern for the alarm.
     */
    private fun startVibration() {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager =
                    context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }

            // Pattern: vibrate 500ms, pause 200ms, vibrate 500ms, pause 200ms...
            val pattern = longArrayOf(0, 500, 200, 500, 200, 800, 300)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(
                    VibrationEffect.createWaveform(pattern, 0) // 0 = repeat from index 0
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(pattern, 0)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Stop vibration.
     */
    private fun stopVibration() {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager =
                    context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            vibrator.cancel()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
