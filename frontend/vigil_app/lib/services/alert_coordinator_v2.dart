import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_sensor_fusion_engine.dart';
import 'behavioral_context_analyzer.dart';
import 'sensor_manager_v2.dart';
import 'alarm_service.dart';
import 'camera_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'api_service.dart';

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

  /// CRITICAL: Extraction detected by AI fusion engine
  void _onExtractionDetected() {
    if (!_isProtectionActive) return;
    if (_state == ProtectionState.graceCountdown ||
        _state == ProtectionState.alarm) return;

    debugPrint('[Vigil CoordV2] EXTRACTION DETECTED — starting verification flow');

    // Step 1: Attempt face verification (auto-cancel if owner's face detected)
    _updateState(ProtectionState.faceVerification);
    onShowFaceVerification?.call();

    // Give face verification 2 seconds to work
    Timer(const Duration(seconds: 2), () {
      if (_state == ProtectionState.faceVerification) {
        // Face verification didn't auto-cancel — start grace countdown
        _startGraceCountdown();
      }
    });
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
