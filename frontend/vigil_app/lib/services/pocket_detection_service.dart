import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Smart pocket detection service using proximity, light, and motion sensors.
/// Combines multiple signals to reduce false alarms.
class PocketDetectionService {
  // Singleton
  static final PocketDetectionService _instance = PocketDetectionService._internal();
  factory PocketDetectionService() => _instance;
  PocketDetectionService._internal();

  // State
  bool _isActive = false;
  bool _isInPocket = false;
  bool _graceActive = false;
  int _gracePeriodSeconds = 3;
  Timer? _graceTimer;
  Timer? _sensorPollTimer;

  // Sensor values
  double _proximityValue = 0.0; // 0 = near (in pocket), max = far
  double _lightValue = 0.0; // low = dark (in pocket)
  double _accelerometerMagnitude = 0.0;
  
  // Thresholds for pocket detection
  static const double _proximityThreshold = 1.0; // Near threshold
  static const double _lightThresholdDark = 15.0; // Lux - dark (pocket)
  static const double _lightThresholdBright = 50.0; // Lux - exposed
  static const double _motionThresholdNormal = 2.0; // Normal pocket movement
  static const double _motionThresholdSuspicious = 8.0; // Suspicious grab

  // False alarm prevention - signal history
  final List<_SensorSnapshot> _sensorHistory = [];
  static const int _historySize = 10;
  static const int _confirmationReadings = 3; // Need 3 consistent readings

  // Callbacks
  VoidCallback? onPocketEntry;
  VoidCallback? onPocketExit;
  VoidCallback? onGracePeriodStart;
  VoidCallback? onGracePeriodExpired;
  Function(SensorData)? onSensorUpdate;

  // Getters
  bool get isActive => _isActive;
  bool get isInPocket => _isInPocket;
  bool get isGraceActive => _graceActive;
  int get gracePeriodSeconds => _gracePeriodSeconds;
  double get proximityValue => _proximityValue;
  double get lightValue => _lightValue;
  double get accelerometerMagnitude => _accelerometerMagnitude;

  /// Start pocket detection monitoring
  void start({int gracePeriodSeconds = 3}) {
    if (_isActive) return;
    _isActive = true;
    _gracePeriodSeconds = gracePeriodSeconds;
    _sensorHistory.clear();
    _startSensorListening();
    debugPrint('[Vigil] Pocket detection started (grace: ${gracePeriodSeconds}s)');
  }

  /// Stop pocket detection monitoring
  void stop() {
    _isActive = false;
    _isInPocket = false;
    _graceActive = false;
    _graceTimer?.cancel();
    _sensorPollTimer?.cancel();
    _sensorHistory.clear();
    debugPrint('[Vigil] Pocket detection stopped');
  }

  /// Update grace period setting
  void setGracePeriod(int seconds) {
    _gracePeriodSeconds = seconds;
  }

  /// Called when user confirms they're using the phone (pause detection)
  void pauseForDuration(Duration duration) {
    stop();
    Timer(duration, () {
      if (!_isActive) start(gracePeriodSeconds: _gracePeriodSeconds);
    });
    debugPrint('[Vigil] Paused for ${duration.inMinutes} minutes');
  }

  /// Start listening to device sensors
  void _startSensorListening() {
    // In real implementation, these would connect to:
    // - sensors_plus package for accelerometer
    // - proximity_sensor package
    // - light_sensor package
    //
    // For now, this is the architecture that will be connected to real sensors.
    
    _sensorPollTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _processSensorData(),
    );
  }

  /// Process incoming sensor data and determine pocket state
  void _processSensorData() {
    if (!_isActive) return;

    // Create snapshot of current sensor state
    final snapshot = _SensorSnapshot(
      proximity: _proximityValue,
      light: _lightValue,
      motion: _accelerometerMagnitude,
      timestamp: DateTime.now(),
    );

    _sensorHistory.add(snapshot);
    if (_sensorHistory.length > _historySize) {
      _sensorHistory.removeAt(0);
    }

    // Determine pocket state using combined signals
    final pocketState = _determinePocketState();

    // Notify sensor update
    onSensorUpdate?.call(SensorData(
      proximity: _proximityValue,
      light: _lightValue,
      motion: _accelerometerMagnitude,
      isInPocket: _isInPocket,
      pocketConfidence: pocketState.confidence,
    ));

    // State change: entered pocket
    if (pocketState.isInPocket && !_isInPocket) {
      _isInPocket = true;
      _graceActive = false;
      _graceTimer?.cancel();
      onPocketEntry?.call();
      debugPrint('[Vigil] Phone entered pocket (confidence: ${pocketState.confidence})');
    }
    // State change: left pocket
    else if (!pocketState.isInPocket && _isInPocket && pocketState.confidence > 0.7) {
      _handlePocketExit(pocketState);
    }
  }

  /// Handle pocket exit with grace period
  void _handlePocketExit(_PocketState state) {
    // Check if this is a suspicious removal or normal use
    if (!_isSuspiciousRemoval(state)) {
      debugPrint('[Vigil] Normal pocket exit detected (not suspicious)');
      return;
    }

    _isInPocket = false;
    _graceActive = true;
    onPocketExit?.call();
    onGracePeriodStart?.call();
    debugPrint('[Vigil] Suspicious pocket exit! Grace period: ${_gracePeriodSeconds}s');

    // Start grace period timer
    _graceTimer?.cancel();
    _graceTimer = Timer(
      Duration(seconds: _gracePeriodSeconds),
      () {
        if (_graceActive && _isActive) {
          _graceActive = false;
          onGracePeriodExpired?.call();
          debugPrint('[Vigil] Grace period expired - TRIGGERING ALARM');
        }
      },
    );
  }

  /// Determine if the pocket removal is suspicious (vs normal phone pickup)
  bool _isSuspiciousRemoval(_PocketState state) {
    if (_sensorHistory.length < 3) return false;

    // Get recent motion history
    final recentMotion = _sensorHistory
        .skip(_sensorHistory.length - 3)
        .map((s) => s.motion)
        .toList();

    // Check 1: Was there a sudden motion spike?
    final maxRecentMotion = recentMotion.reduce(max);
    final hasSuddenMotion = maxRecentMotion > _motionThresholdSuspicious;

    // Check 2: Was the light change sudden? (dark -> bright quickly)
    final lightChange = _sensorHistory.last.light - _sensorHistory.first.light;
    final hasSuddenLightChange = lightChange > _lightThresholdBright;

    // Check 3: Did proximity change from near to far?
    final proximityChanged = _sensorHistory.first.proximity < _proximityThreshold &&
        _sensorHistory.last.proximity >= _proximityThreshold;

    // COMBINED DECISION: Need at least 2 out of 3 signals
    int suspiciousSignals = 0;
    if (hasSuddenMotion) suspiciousSignals++;
    if (hasSuddenLightChange) suspiciousSignals++;
    if (proximityChanged) suspiciousSignals++;

    debugPrint('[Vigil] Suspicion check: motion=$hasSuddenMotion, '
        'light=$hasSuddenLightChange, proximity=$proximityChanged '
        '(signals: $suspiciousSignals/3)');

    // Need at least 2 signals to be suspicious (reduces false alarms)
    return suspiciousSignals >= 2;
  }

  /// Analyze sensor history to determine current pocket state
  _PocketState _determinePocketState() {
    if (_sensorHistory.isEmpty) {
      return _PocketState(isInPocket: false, confidence: 0.0);
    }

    // Get recent readings for confirmation
    final recentReadings = _sensorHistory.length >= _confirmationReadings
        ? _sensorHistory.sublist(_sensorHistory.length - _confirmationReadings)
        : _sensorHistory;

    // Score each reading for "in pocket" likelihood
    double totalScore = 0;
    for (final reading in recentReadings) {
      double score = 0;

      // Proximity: near = in pocket
      if (reading.proximity < _proximityThreshold) {
        score += 0.4;
      }

      // Light: dark = in pocket
      if (reading.light < _lightThresholdDark) {
        score += 0.35;
      }

      // Motion: low/normal = in pocket (not being actively handled)
      if (reading.motion < _motionThresholdNormal) {
        score += 0.25;
      }

      totalScore += score;
    }

    final avgScore = totalScore / recentReadings.length;
    final isInPocket = avgScore > 0.6; // Need 60%+ confidence

    return _PocketState(isInPocket: isInPocket, confidence: avgScore);
  }

  /// Cancel the grace period (user confirmed safe)
  void cancelGracePeriod() {
    _graceActive = false;
    _graceTimer?.cancel();
    _isInPocket = false;
    debugPrint('[Vigil] Grace period cancelled by user');
  }

  // === SENSOR UPDATE METHODS (called by platform channel / sensor plugins) ===

  /// Update proximity sensor value
  void updateProximity(double value) {
    _proximityValue = value;
  }

  /// Update light sensor value
  void updateLight(double value) {
    _lightValue = value;
  }

  /// Update accelerometer data (pass magnitude of XYZ vector)
  void updateAccelerometer(double x, double y, double z) {
    _accelerometerMagnitude = sqrt(x * x + y * y + z * z);
  }
}

/// Internal sensor snapshot for history tracking
class _SensorSnapshot {
  final double proximity;
  final double light;
  final double motion;
  final DateTime timestamp;

  _SensorSnapshot({
    required this.proximity,
    required this.light,
    required this.motion,
    required this.timestamp,
  });
}

/// Internal pocket state determination result
class _PocketState {
  final bool isInPocket;
  final double confidence; // 0.0 to 1.0

  _PocketState({required this.isInPocket, required this.confidence});
}

/// Public sensor data model for UI updates
class SensorData {
  final double proximity;
  final double light;
  final double motion;
  final bool isInPocket;
  final double pocketConfidence;

  SensorData({
    required this.proximity,
    required this.light,
    required this.motion,
    required this.isInPocket,
    required this.pocketConfidence,
  });
}
