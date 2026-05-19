import 'dart:async';
import 'package:flutter/foundation.dart';
import 'alarm_service.dart';
import 'camera_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'pocket_detection_service.dart';
import 'api_service.dart';

/// Central coordinator that orchestrates the full alert flow:
/// 1. Pocket detection triggers grace period
/// 2. Grace expires -> safety check shown + photo captured
/// 3. Not cancelled -> full alarm + location share + contact alerts
/// 
/// This is the "brain" that connects all services together.
class AlertCoordinator {
  static final AlertCoordinator _instance = AlertCoordinator._internal();
  factory AlertCoordinator() => _instance;
  AlertCoordinator._internal();

  final PocketDetectionService _detection = PocketDetectionService();
  final AlarmService _alarm = AlarmService();
  final CameraService _camera = CameraService();
  final LocationService _location = LocationService();
  final NotificationService _notifications = NotificationService();
  final ApiService _api = ApiService();

  bool _isInitialized = false;
  int? _activeAlertId;

  // Callbacks for UI
  VoidCallback? onShowSafetyScreen;
  VoidCallback? onAlarmStarted;
  VoidCallback? onAlarmStopped;
  Function(String)? onStatusChange;

  /// Initialize all services and wire them together
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _notifications.initialize();

    // Wire pocket detection to alarm flow
    _detection.onGracePeriodExpired = _onGracePeriodExpired;
    _detection.onPocketEntry = _onPhoneEnteredPocket;
    _detection.onPocketExit = _onPhoneLeftPocket;

    // Wire alarm to actions
    _alarm.onShowSafetyCheck = _onSafetyCheckShown;
    _alarm.onAlarmTriggered = _onFullAlarmTriggered;
    _alarm.onAlarmStopped = _onAlarmResolved;

    // Wire notification actions
    _notifications.onPause5MinTapped = () {
      _detection.pauseForDuration(const Duration(minutes: 5));
      _notifications.cancelNotification(NotificationService.pocketModeNotificationId);
      onStatusChange?.call('Paused for 5 minutes');
      debugPrint('[Vigil Coordinator] Paused by user for 5 min');
    };

    _notifications.onImSafeTapped = () {
      confirmSafe();
    };

    debugPrint('[Vigil Coordinator] Initialized');
  }

  /// Enable pocket mode protection
  Future<void> enableProtection({int gracePeriodSeconds = 3}) async {
    await initialize();

    // Start pocket detection
    _detection.start(gracePeriodSeconds: gracePeriodSeconds);

    // Start location tracking (normal mode)
    await _location.startTracking();

    // Show persistent notification
    await _notifications.showPocketModeNotification();

    onStatusChange?.call('Protection active');
    debugPrint('[Vigil Coordinator] Protection enabled');
  }

  /// Disable pocket mode protection
  void disableProtection() {
    _detection.stop();
    _location.stopTracking();
    _notifications.cancelNotification(NotificationService.pocketModeNotificationId);
    onStatusChange?.call('Protection disabled');
    debugPrint('[Vigil Coordinator] Protection disabled');
  }

  /// User confirms they are safe (from lock screen or notification)
  void confirmSafe() {
    _detection.cancelGracePeriod();
    _alarm.confirmSafe();
    _alarm.stopAlarm();
    _location.disableHighFrequency();

    if (_activeAlertId != null) {
      _api.acknowledgeAlert(_activeAlertId!);
      _activeAlertId = null;
    }

    onAlarmStopped?.call();
    onStatusChange?.call('Confirmed safe');
    debugPrint('[Vigil Coordinator] User confirmed safe');
  }

  // === INTERNAL EVENT HANDLERS ===

  void _onPhoneEnteredPocket() {
    onStatusChange?.call('Phone in pocket - protected');
    debugPrint('[Vigil Coordinator] Phone entered pocket');
  }

  void _onPhoneLeftPocket() {
    onStatusChange?.call('Phone removed - grace period started');
    debugPrint('[Vigil Coordinator] Phone left pocket - grace period');
  }

  /// Grace period expired without user cancellation
  void _onGracePeriodExpired() {
    debugPrint('[Vigil Coordinator] Grace expired - showing safety check');
    _alarm.triggerSafetyCheck();
  }

  /// Safety check screen is now visible
  void _onSafetyCheckShown() {
    onShowSafetyScreen?.call();

    // Attempt to capture intruder photo while screen is visible
    _camera.captureIntruderPhoto();

    debugPrint('[Vigil Coordinator] Safety check shown + photo capture attempt');
  }

  /// Full alarm triggered - maximum alert mode
  Future<void> _onFullAlarmTriggered() async {
    debugPrint('[Vigil Coordinator] FULL ALARM - sending all alerts');

    onAlarmStarted?.call();
    onStatusChange?.call('EMERGENCY - Alarm active');

    // Switch to high-frequency location tracking
    _location.enableHighFrequency();

    // Get current location
    final location = await _location.getCurrentLocation();

    // Create alert on backend
    try {
      final alertId = await _api.createAlert(
        triggerType: 'pocket_removal',
        latitude: location?['latitude'],
        longitude: location?['longitude'],
        proximityValue: _detection.proximityValue,
        lightValue: _detection.lightValue,
      );

      _activeAlertId = alertId;

      // Upload intruder photo if captured
      if (alertId != null && _camera.lastPhotoPath != null) {
        await _camera.uploadIntruderPhoto(
          alertId: alertId,
          photoPath: _camera.lastPhotoPath!,
        );
      }

      debugPrint('[Vigil Coordinator] Alert created: $alertId');
    } catch (e) {
      debugPrint('[Vigil Coordinator] Alert creation failed: $e');
    }

    // Show high-priority alert notification
    await _notifications.showAlertNotification(
      title: 'VIGIL EMERGENCY',
      body: 'Alarm active. Tap to confirm you are safe.',
    );
  }

  /// Alarm was stopped/resolved
  void _onAlarmResolved() {
    _location.disableHighFrequency();
    onAlarmStopped?.call();
    onStatusChange?.call('Alert resolved');
    debugPrint('[Vigil Coordinator] Alarm resolved');
  }

  /// Get current protection status
  ProtectionStatus getStatus() {
    return ProtectionStatus(
      isActive: _detection.isActive,
      isInPocket: _detection.isInPocket,
      isGraceActive: _detection.isGraceActive,
      isAlarmActive: _alarm.isAlarmActive,
      isTracking: _location.isTracking,
      gracePeriodSeconds: _detection.gracePeriodSeconds,
    );
  }
}

/// Current protection status for UI display
class ProtectionStatus {
  final bool isActive;
  final bool isInPocket;
  final bool isGraceActive;
  final bool isAlarmActive;
  final bool isTracking;
  final int gracePeriodSeconds;

  ProtectionStatus({
    required this.isActive,
    required this.isInPocket,
    required this.isGraceActive,
    required this.isAlarmActive,
    required this.isTracking,
    required this.gracePeriodSeconds,
  });

  String get statusText {
    if (isAlarmActive) return 'EMERGENCY';
    if (isGraceActive) return 'Grace Period';
    if (isInPocket) return 'Protected';
    if (isActive) return 'Monitoring';
    return 'Inactive';
  }
}
