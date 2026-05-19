import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Manages the alarm lifecycle:
/// 1. Grace period expires -> wake screen + show safety check
/// 2. Safety check not cancelled -> trigger loud alarm
/// 3. Alarm rings continuously until owner stops it
/// 4. Simultaneously triggers location share + photo capture + contact alert
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  static const MethodChannel _channel = MethodChannel('com.vigil.app/alarm');

  bool _isAlarmActive = false;
  bool _isSafetyCheckShowing = false;
  Timer? _safetyCheckTimer;
  String _selectedRingtone = 'default_alarm';

  // Callbacks
  VoidCallback? onShowSafetyCheck;
  VoidCallback? onAlarmTriggered;
  VoidCallback? onAlarmStopped;

  bool get isAlarmActive => _isAlarmActive;
  bool get isSafetyCheckShowing => _isSafetyCheckShowing;

  /// Set custom alarm ringtone
  void setRingtone(String ringtone) {
    _selectedRingtone = ringtone;
  }

  /// Step 1: Grace period expired - show safety check screen
  void triggerSafetyCheck() {
    if (_isSafetyCheckShowing || _isAlarmActive) return;

    _isSafetyCheckShowing = true;
    debugPrint('[Vigil Alarm] Showing safety check screen');

    // Wake the screen
    _wakeScreen();

    // Notify UI to show lock-screen safety check
    onShowSafetyCheck?.call();

    // Start countdown - if not cancelled, trigger full alarm
    _safetyCheckTimer = Timer(const Duration(seconds: 10), () {
      if (_isSafetyCheckShowing) {
        triggerFullAlarm();
      }
    });
  }

  /// Step 2: Safety check not cancelled - FULL ALARM
  void triggerFullAlarm() {
    _isSafetyCheckShowing = false;
    _isAlarmActive = true;
    _safetyCheckTimer?.cancel();

    debugPrint('[Vigil Alarm] FULL ALARM TRIGGERED');

    // Start loud alarm sound
    _playAlarmSound();

    // Enable maximum volume
    _setMaxVolume();

    // Notify listeners (will trigger location share, photo, contact alerts)
    onAlarmTriggered?.call();
  }

  /// Owner stops the alarm
  void stopAlarm() {
    _isAlarmActive = false;
    _isSafetyCheckShowing = false;
    _safetyCheckTimer?.cancel();

    // Stop alarm sound
    _stopAlarmSound();

    debugPrint('[Vigil Alarm] Alarm stopped by owner');
    onAlarmStopped?.call();
  }

  /// Owner confirms safe during safety check (cancels alarm)
  void confirmSafe() {
    _isSafetyCheckShowing = false;
    _safetyCheckTimer?.cancel();
    debugPrint('[Vigil Alarm] Owner confirmed safe - cancelled');
  }

  /// Wake the device screen via platform channel
  Future<void> _wakeScreen() async {
    try {
      await _channel.invokeMethod('wakeScreen');
    } catch (e) {
      debugPrint('[Vigil] Wake screen failed: $e');
    }
  }

  /// Play alarm sound continuously
  Future<void> _playAlarmSound() async {
    try {
      await _channel.invokeMethod('playAlarm', {
        'ringtone': _selectedRingtone,
        'loop': true,
        'maxVolume': true,
      });
    } catch (e) {
      debugPrint('[Vigil] Play alarm failed: $e');
    }
  }

  /// Stop alarm sound
  Future<void> _stopAlarmSound() async {
    try {
      await _channel.invokeMethod('stopAlarm');
    } catch (e) {
      debugPrint('[Vigil] Stop alarm failed: $e');
    }
  }

  /// Set device volume to maximum
  Future<void> _setMaxVolume() async {
    try {
      await _channel.invokeMethod('setMaxVolume');
    } catch (e) {
      debugPrint('[Vigil] Set max volume failed: $e');
    }
  }
}
