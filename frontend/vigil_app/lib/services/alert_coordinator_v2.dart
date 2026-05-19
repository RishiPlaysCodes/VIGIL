import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'ai_sensor_fusion_engine.dart';
import 'behavioral_context_analyzer.dart';
import 'sensor_manager_v2.dart';
import 'alarm_service.dart';
import 'camera_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'api_service.dart';
import 'wake_intent_service.dart';
import '../utils/navigation_service.dart';

/// Alert Coordinator V2 — The upgraded brain of Vigil.
///
/// Critical fixes over V1:
/// 1. ACTUALLY connects AI Sensor Fusion Engine (V1 had simulated sensors)
/// 2. Uses BehavioralContextAnalyzer for adaptive thresholds
/// 3. Extraction detection triggers face verification FIRST (not alarm)
/// 4. Grace period is configurable and context-aware
/// 5. Implements proper state machine with no skipped states
/// 6. Offline alert queuing for network failures
/// 7. Starts/stops the foreground service properly
/// 8. Integrates with multi-layer authentication before cancellation
///
/// Flow:
/// AI Fusion Engine detects extraction → Face verification attempt →
/// Grace period with countdown → Multi-layer auth required to cancel →
/// Full emergency protocol if not authenticated
class AlertCoordinatorV2 {
  static final AlertCoordinatorV2 _instance = AlertCoordinatorV2._internal();
  factory AlertCoordinatorV2() => _instance;
  AlertCoordinatorV2._internal();

  // Core services
  final SensorManagerV2 _sensorManager = SensorManagerV2();
  final AlarmService _alarm = AlarmService();
  final CameraService _camera = CameraService();
  final LocationService _location = LocationService();
  final NotificationService _notifications = NotificationService();
  final ApiService _api = ApiService();
  final WakeIntentService _wakeIntent = WakeIntentService();

  // Native channel for direct wake activity launches
  static const MethodChannel _alarmChannel = MethodChannel('com.vigil.app/alarm');

  // State
  bool _isInitialized = false;
  bool _isProtectionActive = false;
  ProtectionState _state = ProtectionState.inactive;
  int _gracePeriodSeconds = 3;
  Timer? _graceTimer;
  int? _activeAlertId;
  DateTime? _protectionStartTime;

  // Offline queue for failed API calls
  final List<Map<String, dynamic>> _offlineAlertQueue = [];

  // Callbacks for UI
  Function(ProtectionState)? onStateChange;
  VoidCallback? onShowSafetyScreen;
  VoidCallback? onShowFaceVerification;
  VoidCallback? onAlarmStarted;
  VoidCallback? onAlarmStopped;
  Function(String)? onStatusMessage;
  Function(ThreatAssessment)? onThreatDetected;

  // Getters
  bool get isProtectionActive => _isProtectionActive;
  ProtectionState get state => _state;
  AISensorFusionEngine get fusionEngine => _sensorManager.fusionEngine;
  BehavioralContextAnalyzer get contextAnalyzer => _sensorManager.contextAnalyzer;
  int get gracePeriodSeconds => _gracePeriodSeconds;

  /// Initialize the coordinator and all services
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _notifications.initialize();
    await _wakeIntent.initialize();

    // Wire AI fusion engine events
    _sensorManager.fusionEngine.onExtractionDetected = _onExtractionDetected;
    _sensorManager.fusionEngine.onThreatAssessment = _onThreatAssessed;
    _sensorManager.fusionEngine.onPocketEntry = _onPocketEntry;
    _sensorManager.fusionEngine.onPocketExit = _onNormalPocketExit;

    // Wire alarm events
    _alarm.onAlarmTriggered = _onFullAlarmTriggered;
    _alarm.onAlarmStopped = _onAlarmResolved;

    // Wire notification actions
    _notifications.onPause5MinTapped = _onPause5Min;
    _notifications.onImSafeTapped = _onRequestAuthentication;

    debugPrint('[Vigil CoordV2] Initialized');
  }

  /// Enable pocket mode protection
  Future<void> enableProtection({
    int gracePeriodSeconds = 3,
    bool highSecurity = false,
    bool batterySaver = false,
  }) async {
    await initialize();

    _isProtectionActive = true;
    _gracePeriodSeconds = gracePeriodSeconds;
    _protectionStartTime = DateTime.now();

    // Start sensor listening with appropriate mode
    if (highSecurity) {
      await _sensorManager.startListening(mode: SensorPollingMode.highSecurity);
    } else if (batterySaver) {
      await _sensorManager.startListening(mode: SensorPollingMode.batterySaver);
    } else {
      await _sensorManager.startListening();
    }

    // Start background location tracking
    await _location.startTracking();

    // Show persistent notification
    await _notifications.showPocketModeNotification();

    // Update state
    _updateState(ProtectionState.monitoring);
    onStatusMessage?.call('Protection active — AI monitoring sensors');

    debugPrint('[Vigil CoordV2] Protection enabled (grace: ${gracePeriodSeconds}s, '
        'highSec: $highSecurity, battery: $batterySaver)');
  }

  /// Disable pocket mode protection
  void disableProtection() {
    _isProtectionActive = false;
    _sensorManager.stopListening();
    _location.stopTracking();
    _graceTimer?.cancel();
    _notifications.cancelNotification(NotificationService.pocketModeNotificationId);
    _updateState(ProtectionState.inactive);
    onStatusMessage?.call('Protection disabled');
    debugPrint('[Vigil CoordV2] Protection disabled');
  }

  /// Called when owner is verified through multi-layer auth
  void onOwnerVerified() {
    debugPrint('[Vigil CoordV2] Owner verified — cancelling all alerts');
    _graceTimer?.cancel();
    _alarm.stopAlarm();
    _location.disableHighFrequency();

    if (_activeAlertId != null) {
      _api.acknowledgeAlert(_activeAlertId!);
      _activeAlertId = null;
    }

    _updateState(ProtectionState.monitoring);
    onAlarmStopped?.call();
    onStatusMessage?.call('Verified safe — returning to monitoring');
  }

  /// Pause protection for a duration (user is using phone)
  void pauseFor(Duration duration) {
    debugPrint('[Vigil CoordV2] Pausing for ${duration.inMinutes} min');
    _sensorManager.stopListening();
    _graceTimer?.cancel();
    _updateState(ProtectionState.paused);
    onStatusMessage?.call('Paused for ${duration.inMinutes} minutes');

    Timer(duration, () {
      if (_isProtectionActive) {
        _sensorManager.startListening();
        _updateState(ProtectionState.monitoring);
        onStatusMessage?.call('Protection resumed');
      }
    });
  }

  /// Set grace period (user preference)
  void setGracePeriod(int seconds) {
    _gracePeriodSeconds = seconds;
  }

  // ═══════════════════════════════════════════════════════════
  // AI FUSION ENGINE EVENT HANDLERS
  // ═══════════════════════════════════════════════════════════

  void _onPocketEntry() {
    if (_state == ProtectionState.monitoring) {
      onStatusMessage?.call('Phone secured in pocket');
    }
  }

  void _onNormalPocketExit() {
    // Normal exit (low threat) — user just took out their phone
    onStatusMessage?.call('Phone in hand — monitoring');
  }

  /// CRITICAL: Extraction detected by AI fusion engine.
  /// This is the entry point for the entire emergency flow.
  ///
  /// Flow:
  /// 1. Check we should actually trigger (not already in another phase)
  /// 2. Capture intruder photo IMMEDIATELY (don't wait for screen)
  /// 3. Wake the screen via NATIVE wake intent (works even when locked)
  /// 4. Native opens MainActivity with showWhenLocked + turnScreenOn
  /// 5. Native sends route to Dart, NavigationService pushes /lock-screen-safety
  /// 6. Lock screen tries face verification automatically
  /// 7. If face fails → countdown + multi-layer auth UI
  /// 8. If countdown expires → escalate to /emergency-active
  void _onExtractionDetected() {
    if (!_isProtectionActive) return;
    if (_state == ProtectionState.graceCountdown ||
        _state == ProtectionState.alarm ||
        _state == ProtectionState.faceVerification) return;

    debugPrint('[Vigil CoordV2] EXTRACTION DETECTED — waking screen');

    _updateState(ProtectionState.faceVerification);

    // Capture photo immediately while phone may still be in motion (intruder evidence)
    _camera.captureIntruderPhoto();

    // Trigger native wake — this brings the safety screen up over the lock screen
    _launchSafetyScreenNative();

    // Also trigger UI callback (in case app is in foreground)
    onShowFaceVerification?.call();

    // If face verification doesn't auto-cancel within 2s, start grace countdown
    Timer(const Duration(seconds: 2), () {
      if (_state == ProtectionState.faceVerification) {
        _startGraceCountdown();
      }
    });
  }

  /// Launch the safety screen via native wake intent so it shows over lock screen.
  Future<void> _launchSafetyScreenNative() async {
    try {
      // Native launchSafetyActivity opens MainActivity with wake flags +
      // sends route to Flutter via wake_intent channel
      await _alarmChannel.invokeMethod('launchSafetyActivity', {
        'route': 'lock-screen',
      });
    } catch (e) {
      debugPrint('[Vigil CoordV2] Native wake failed: $e');
      // Fallback: try Flutter-side navigation if app is already in foreground
      NavigationService.pushNamed('/lock-screen-safety');
    }
  }

  void _onThreatAssessed(ThreatAssessment threat) {
    onThreatDetected?.call(threat);
    debugPrint('[Vigil CoordV2] Threat: ${threat.confidence.toStringAsFixed(2)} '
        '(${threat.reason})');
  }

  // ═══════════════════════════════════════════════════════════
  // GRACE PERIOD & ALARM FLOW
  // ═══════════════════════════════════════════════════════════

  void _startGraceCountdown() {
    _updateState(ProtectionState.graceCountdown);
    onShowSafetyScreen?.call();
    onStatusMessage?.call('Grace period: ${_gracePeriodSeconds}s to verify');

    // Wake screen and show safety verification
    _alarm.triggerSafetyCheck();

    // Start the countdown
    _graceTimer?.cancel();
    _graceTimer = Timer(Duration(seconds: _gracePeriodSeconds), () {
      if (_state == ProtectionState.graceCountdown) {
        // Not cancelled — TRIGGER FULL ALARM
        _triggerFullEmergency();
      }
    });

    // Also attempt intruder photo capture during safety screen
    _camera.captureIntruderPhoto();
  }

  void _triggerFullEmergency() {
    debugPrint('[Vigil CoordV2] FULL EMERGENCY TRIGGERED');
    _updateState(ProtectionState.alarm);
    _alarm.triggerFullAlarm();
  }

  Future<void> _onFullAlarmTriggered() async {
    onAlarmStarted?.call();
    onStatusMessage?.call('EMERGENCY — Alarm active');

    // Switch to high-frequency location
    _location.enableHighFrequency();

    // Get current location
    final location = await _location.getCurrentLocation();

    // Create alert on backend (with offline fallback)
    try {
      final alertId = await _api.createAlert(
        triggerType: 'ai_extraction',
        latitude: location?['latitude'],
        longitude: location?['longitude'],
        proximityValue: _sensorManager.getCurrentReadings().proximity,
        lightValue: _sensorManager.getCurrentReadings().light,
      );

      _activeAlertId = alertId;

      // Upload intruder photo
      if (alertId != null && _camera.lastPhotoPath != null) {
        await _camera.uploadIntruderPhoto(
          alertId: alertId,
          photoPath: _camera.lastPhotoPath!,
        );
      }
    } catch (e) {
      // Offline fallback — queue the alert
      _offlineAlertQueue.add({
        'trigger_type': 'ai_extraction',
        'latitude': location?['latitude'],
        'longitude': location?['longitude'],
        'timestamp': DateTime.now().toIso8601String(),
        'photo_path': _camera.lastPhotoPath,
      });
      debugPrint('[Vigil CoordV2] Alert queued offline: $e');
    }

    // Show high-priority notification
    await _notifications.showAlertNotification(
      title: 'VIGIL EMERGENCY',
      body: 'Suspicious extraction detected. Verify your identity.',
    );
  }

  void _onAlarmResolved() {
    _location.disableHighFrequency();
    _updateState(ProtectionState.monitoring);
    onAlarmStopped?.call();
    onStatusMessage?.call('Alert resolved');
  }

  // ═══════════════════════════════════════════════════════════
  // NOTIFICATION ACTION HANDLERS
  // ═══════════════════════════════════════════════════════════

  void _onPause5Min() {
    pauseFor(const Duration(minutes: 5));
  }

  void _onRequestAuthentication() {
    // "I Am Safe" notification tapped — requires authentication, not just a tap
    onShowSafetyScreen?.call();
    onStatusMessage?.call('Authenticate to confirm you are safe');
  }

  // ═══════════════════════════════════════════════════════════
  // STATE MACHINE
  // ═══════════════════════════════════════════════════════════

  void _updateState(ProtectionState newState) {
    if (_state == newState) return;
    final previous = _state;
    _state = newState;
    onStateChange?.call(newState);
    debugPrint('[Vigil CoordV2] State: $previous → $newState');
  }

  /// Sync any offline queued alerts to backend
  Future<void> syncOfflineAlerts() async {
    if (_offlineAlertQueue.isEmpty) return;

    final toSync = List<Map<String, dynamic>>.from(_offlineAlertQueue);
    _offlineAlertQueue.clear();

    for (final alert in toSync) {
      try {
        await _api.createAlert(
          triggerType: alert['trigger_type'],
          latitude: alert['latitude'],
          longitude: alert['longitude'],
        );
      } catch (e) {
        // Re-queue if still failing
        _offlineAlertQueue.add(alert);
      }
    }
  }

  /// Get protection status for UI
  ProtectionStatusV2 getStatus() {
    return ProtectionStatusV2(
      state: _state,
      isActive: _isProtectionActive,
      gracePeriodSeconds: _gracePeriodSeconds,
      threatConfidence: _sensorManager.fusionEngine.threatConfidence,
      movementClass: _sensorManager.fusionEngine.movementClass,
      isInPocket: _sensorManager.fusionEngine.isInPocket,
      safetyScore: _sensorManager.contextAnalyzer.safetyScore,
      uptime: _protectionStartTime != null
          ? DateTime.now().difference(_protectionStartTime!)
          : Duration.zero,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════

enum ProtectionState {
  inactive,
  monitoring,
  paused,
  faceVerification,
  graceCountdown,
  alarm,
}

class ProtectionStatusV2 {
  final ProtectionState state;
  final bool isActive;
  final int gracePeriodSeconds;
  final double threatConfidence;
  final MovementClassification movementClass;
  final bool isInPocket;
  final double safetyScore;
  final Duration uptime;

  ProtectionStatusV2({
    required this.state,
    required this.isActive,
    required this.gracePeriodSeconds,
    required this.threatConfidence,
    required this.movementClass,
    required this.isInPocket,
    required this.safetyScore,
    required this.uptime,
  });

  String get stateLabel {
    switch (state) {
      case ProtectionState.inactive: return 'Inactive';
      case ProtectionState.monitoring: return 'Monitoring';
      case ProtectionState.paused: return 'Paused';
      case ProtectionState.faceVerification: return 'Verifying...';
      case ProtectionState.graceCountdown: return 'Grace Period';
      case ProtectionState.alarm: return 'EMERGENCY';
    }
  }
}
