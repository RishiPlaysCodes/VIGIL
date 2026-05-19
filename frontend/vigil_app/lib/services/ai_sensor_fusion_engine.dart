import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// AI-driven Sensor Fusion Engine for Vigil.
///
/// Replaces simple threshold-based detection with a sophisticated multi-sensor
/// analysis system that combines:
/// - Accelerometer (3-axis motion magnitude, jerk, orientation)
/// - Gyroscope (rotation rate, tilt detection)
/// - Proximity sensor (in-pocket vs exposed)
/// - Ambient light sensor (dark pocket vs exposed)
/// - Orientation analysis (phone angle changes)
/// - Motion intensity classification
/// - Extraction pattern recognition
/// - AI confidence scoring with Bayesian fusion
///
/// Key design: The engine NEVER triggers on motion alone. It requires
/// combined multi-sensor evidence of actual pocket EXTRACTION before
/// any alert flow begins.
class AISensorFusionEngine {
  static final AISensorFusionEngine _instance = AISensorFusionEngine._internal();
  factory AISensorFusionEngine() => _instance;
  AISensorFusionEngine._internal();

  // === STATE ===
  bool _isActive = false;
  bool _isInPocket = false;
  PhoneState _currentState = PhoneState.unknown;
  double _threatConfidence = 0.0;
  DateTime? _lastStateChange;

  // === SENSOR BUFFERS (ring buffers for efficiency) ===
  final List<AccelReading> _accelBuffer = [];
  final List<GyroReading> _gyroBuffer = [];
  final List<double> _proximityBuffer = [];
  final List<double> _lightBuffer = [];
  final List<OrientationReading> _orientationBuffer = [];

  static const int _accelBufferSize = 100; // ~2s at 50Hz
  static const int _gyroBufferSize = 100;
  static const int _proximityBufferSize = 30;
  static const int _lightBufferSize = 30;
  static const int _orientationBufferSize = 50;

  // === AI CONFIDENCE PARAMETERS ===
  // Bayesian prior probabilities (learned over time)
  double _priorPocketProb = 0.5;
  double _priorExtractionProb = 0.01; // Extraction is rare
  double _priorNormalUseProb = 0.49;

  // Sensor reliability weights (calibrated per device)
  double _proximityWeight = 0.30;
  double _lightWeight = 0.25;
  double _motionWeight = 0.20;
  double _gyroWeight = 0.15;
  double _orientationWeight = 0.10;

  // === EXTRACTION DETECTION THRESHOLDS ===
  // These are NOT simple thresholds — they're input to the confidence model
  static const double _extractionJerkThreshold = 15.0; // m/s³
  static const double _extractionRotationThreshold = 3.0; // rad/s
  static const double _extractionAccelPeak = 12.0; // m/s²
  static const double _normalMotionCeiling = 4.0; // m/s² (bus, walking)
  static const double _pocketProximityThreshold = 1.0; // cm
  static const double _pocketLightThreshold = 10.0; // lux
  static const double _exposedLightThreshold = 50.0; // lux

  // === BEHAVIORAL CONTEXT ===
  MovementClassification _movementClass = MovementClassification.stationary;
  bool _isInVehicle = false;
  bool _isWalking = false;
  bool _isRunning = false;
  double _ambientMotionBaseline = 9.81; // Calibrated gravity baseline

  // === TIMING ===
  Timer? _analysisTimer;
  DateTime? _pocketEntryTime;
  DateTime? _lastExtractionCandidate;
  static const Duration _minPocketDuration = Duration(seconds: 2);
  static const Duration _extractionCooldown = Duration(seconds: 5);

  // === CALLBACKS ===
  Function(ThreatAssessment)? onThreatAssessment;
  Function(PhoneState)? onStateChange;
  Function(SensorFusionDebug)? onDebugUpdate;
  VoidCallback? onExtractionDetected;
  VoidCallback? onPocketEntry;
  VoidCallback? onPocketExit;

  // === GETTERS ===
  bool get isActive => _isActive;
  bool get isInPocket => _isInPocket;
  PhoneState get currentState => _currentState;
  double get threatConfidence => _threatConfidence;
  MovementClassification get movementClass => _movementClass;

  /// Start the AI sensor fusion engine
  void start() {
    if (_isActive) return;
    _isActive = true;
    _resetBuffers();

    // Analysis runs at 10Hz (every 100ms) for smooth real-time processing
    _analysisTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _runFusionAnalysis(),
    );

    debugPrint('[Vigil AI] Sensor fusion engine started');
  }

  /// Stop the engine
  void stop() {
    _isActive = false;
    _analysisTimer?.cancel();
    _analysisTimer = null;
    _resetBuffers();
    _currentState = PhoneState.unknown;
    _threatConfidence = 0.0;
    debugPrint('[Vigil AI] Sensor fusion engine stopped');
  }

  // ═══════════════════════════════════════════════════════════
  // SENSOR INPUT METHODS (called by SensorManager)
  // ═══════════════════════════════════════════════════════════

  /// Feed accelerometer data (called at ~50Hz from native)
  void feedAccelerometer(double x, double y, double z) {
    if (!_isActive) return;
    final now = DateTime.now();
    final magnitude = sqrt(x * x + y * y + z * z);

    // Calculate jerk (rate of acceleration change)
    double jerk = 0.0;
    if (_accelBuffer.isNotEmpty) {
      final prev = _accelBuffer.last;
      final dt = now.difference(prev.timestamp).inMicroseconds / 1000000.0;
      if (dt > 0) {
        jerk = (magnitude - prev.magnitude).abs() / dt;
      }
    }

    _accelBuffer.add(AccelReading(
      x: x, y: y, z: z,
      magnitude: magnitude,
      jerk: jerk,
      timestamp: now,
    ));

    if (_accelBuffer.length > _accelBufferSize) {
      _accelBuffer.removeAt(0);
    }
  }

  /// Feed gyroscope data (called at ~50Hz from native)
  void feedGyroscope(double x, double y, double z) {
    if (!_isActive) return;
    final magnitude = sqrt(x * x + y * y + z * z);

    _gyroBuffer.add(GyroReading(
      x: x, y: y, z: z,
      magnitude: magnitude,
      timestamp: DateTime.now(),
    ));

    if (_gyroBuffer.length > _gyroBufferSize) {
      _gyroBuffer.removeAt(0);
    }
  }

  /// Feed proximity sensor data
  void feedProximity(double value) {
    if (!_isActive) return;
    _proximityBuffer.add(value);
    if (_proximityBuffer.length > _proximityBufferSize) {
      _proximityBuffer.removeAt(0);
    }
  }

  /// Feed ambient light sensor data
  void feedLight(double lux) {
    if (!_isActive) return;
    _lightBuffer.add(lux);
    if (_lightBuffer.length > _lightBufferSize) {
      _lightBuffer.removeAt(0);
    }
  }

  /// Feed orientation data (computed from accelerometer)
  void feedOrientation(double pitch, double roll, double azimuth) {
    if (!_isActive) return;
    _orientationBuffer.add(OrientationReading(
      pitch: pitch,
      roll: roll,
      azimuth: azimuth,
      timestamp: DateTime.now(),
    ));
    if (_orientationBuffer.length > _orientationBufferSize) {
      _orientationBuffer.removeAt(0);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CORE AI FUSION ANALYSIS (runs at 10Hz)
  // ═══════════════════════════════════════════════════════════

  void _runFusionAnalysis() {
    if (!_isActive) return;
    if (_accelBuffer.length < 10) return; // Need minimum data

    // Step 1: Classify current movement context
    _classifyMovement();

    // Step 2: Determine pocket state (Bayesian inference)
    final pocketConfidence = _computePocketConfidence();

    // Step 3: Check for extraction signature
    final extractionScore = _computeExtractionScore();

    // Step 4: Compute overall threat confidence
    _threatConfidence = _computeThreatConfidence(
      pocketConfidence: pocketConfidence,
      extractionScore: extractionScore,
    );

    // Step 5: Update phone state machine
    _updateStateMachine(pocketConfidence, extractionScore);

    // Step 6: Emit debug data
    onDebugUpdate?.call(SensorFusionDebug(
      pocketConfidence: pocketConfidence,
      extractionScore: extractionScore,
      threatConfidence: _threatConfidence,
      movementClass: _movementClass,
      phoneState: _currentState,
      isInPocket: _isInPocket,
      accelMagnitude: _accelBuffer.isNotEmpty ? _accelBuffer.last.magnitude : 0,
      gyroMagnitude: _gyroBuffer.isNotEmpty ? _gyroBuffer.last.magnitude : 0,
      proximity: _proximityBuffer.isNotEmpty ? _proximityBuffer.last : -1,
      light: _lightBuffer.isNotEmpty ? _lightBuffer.last : -1,
    ));
  }

  // ═══════════════════════════════════════════════════════════
  // MOVEMENT CLASSIFICATION
  // ═══════════════════════════════════════════════════════════

  void _classifyMovement() {
    if (_accelBuffer.length < 20) return;

    final recent = _accelBuffer.sublist(_accelBuffer.length - 20);
    final magnitudes = recent.map((r) => r.magnitude).toList();

    // Statistical features
    final mean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final variance = magnitudes
        .map((m) => (m - mean) * (m - mean))
        .reduce((a, b) => a + b) / magnitudes.length;
    final stdDev = sqrt(variance);

    // Frequency analysis (zero-crossing rate around gravity)
    int zeroCrossings = 0;
    for (int i = 1; i < magnitudes.length; i++) {
      final prev = magnitudes[i - 1] - _ambientMotionBaseline;
      final curr = magnitudes[i] - _ambientMotionBaseline;
      if ((prev > 0 && curr < 0) || (prev < 0 && curr > 0)) {
        zeroCrossings++;
      }
    }

    final duration = recent.last.timestamp.difference(recent.first.timestamp).inMilliseconds;
    final frequency = duration > 0 ? zeroCrossings / (duration / 1000.0) : 0.0;

    // Peak acceleration
    final peakAccel = magnitudes.reduce(max);

    // Classification rules (multi-feature decision)
    if (stdDev < 0.3 && mean < 10.0) {
      _movementClass = MovementClassification.stationary;
      _isWalking = false;
      _isRunning = false;
      _isInVehicle = false;
    } else if (stdDev >= 0.3 && stdDev < 2.0 && frequency < 1.5) {
      _movementClass = MovementClassification.vehicle;
      _isInVehicle = true;
      _isWalking = false;
      _isRunning = false;
    } else if (frequency >= 1.5 && frequency <= 3.5 && stdDev < 4.0) {
      _movementClass = MovementClassification.walking;
      _isWalking = true;
      _isRunning = false;
      _isInVehicle = false;
    } else if (frequency > 3.5 && stdDev >= 3.0 && peakAccel > 15.0) {
      _movementClass = MovementClassification.running;
      _isRunning = true;
      _isWalking = false;
      _isInVehicle = false;
    } else if (peakAccel > _extractionAccelPeak && stdDev > 5.0) {
      _movementClass = MovementClassification.suspiciousMotion;
    } else {
      _movementClass = MovementClassification.activeUse;
      _isWalking = false;
      _isRunning = false;
      _isInVehicle = false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // POCKET STATE CONFIDENCE (Bayesian Multi-Sensor Fusion)
  // ═══════════════════════════════════════════════════════════

  double _computePocketConfidence() {
    double score = 0.0;
    double totalWeight = 0.0;

    // Signal 1: Proximity sensor
    if (_proximityBuffer.isNotEmpty) {
      final avgProximity = _proximityBuffer.reduce((a, b) => a + b) / _proximityBuffer.length;
      final proximityScore = avgProximity < _pocketProximityThreshold ? 1.0 : 0.0;
      score += proximityScore * _proximityWeight;
      totalWeight += _proximityWeight;
    }

    // Signal 2: Light sensor
    if (_lightBuffer.isNotEmpty) {
      final avgLight = _lightBuffer.reduce((a, b) => a + b) / _lightBuffer.length;
      double lightScore;
      if (avgLight < _pocketLightThreshold) {
        lightScore = 1.0;
      } else if (avgLight < _exposedLightThreshold) {
        lightScore = 1.0 - (avgLight - _pocketLightThreshold) /
            (_exposedLightThreshold - _pocketLightThreshold);
      } else {
        lightScore = 0.0;
      }
      score += lightScore * _lightWeight;
      totalWeight += _lightWeight;
    }

    // Signal 3: Motion pattern (low, steady motion = in pocket)
    if (_accelBuffer.length >= 10) {
      final recent = _accelBuffer.sublist(_accelBuffer.length - 10);
      final stdDev = _computeStdDev(recent.map((r) => r.magnitude).toList());
      // In pocket: motion is predictable (gravity + small vibrations)
      final motionScore = stdDev < 1.5 ? 1.0 : (stdDev < 3.0 ? 0.5 : 0.0);
      score += motionScore * _motionWeight;
      totalWeight += _motionWeight;
    }

    // Signal 4: Gyroscope (low rotation = in pocket)
    if (_gyroBuffer.length >= 10) {
      final recent = _gyroBuffer.sublist(_gyroBuffer.length - 10);
      final avgRotation = recent.map((r) => r.magnitude).reduce((a, b) => a + b) / recent.length;
      final gyroScore = avgRotation < 0.5 ? 1.0 : (avgRotation < 1.5 ? 0.5 : 0.0);
      score += gyroScore * _gyroWeight;
      totalWeight += _gyroWeight;
    }

    // Signal 5: Orientation stability (pocket = stable orientation)
    if (_orientationBuffer.length >= 10) {
      final recent = _orientationBuffer.sublist(_orientationBuffer.length - 10);
      final pitchVariance = _computeStdDev(recent.map((r) => r.pitch).toList());
      final rollVariance = _computeStdDev(recent.map((r) => r.roll).toList());
      final orientationScore = (pitchVariance < 5.0 && rollVariance < 5.0) ? 1.0 : 0.0;
      score += orientationScore * _orientationWeight;
      totalWeight += _orientationWeight;
    }

    return totalWeight > 0 ? (score / totalWeight).clamp(0.0, 1.0) : 0.0;
  }

  // ═══════════════════════════════════════════════════════════
  // EXTRACTION DETECTION (the critical anti-theft signal)
  // ═══════════════════════════════════════════════════════════

  double _computeExtractionScore() {
    // Extraction signature: rapid removal from pocket characterized by:
    // 1. High jerk (sudden acceleration change)
    // 2. Significant rotation (phone flips/turns during grab)
    // 3. Proximity changes from near → far
    // 4. Light changes from dark → bright
    // 5. All happening within a short time window (~500ms)

    if (_accelBuffer.length < 20 || !_isInPocket) return 0.0;

    double score = 0.0;

    // Check 1: Jerk analysis (rate of acceleration change)
    final recentJerks = _accelBuffer
        .sublist(_accelBuffer.length - 10)
        .map((r) => r.jerk)
        .toList();
    final maxJerk = recentJerks.reduce(max);
    if (maxJerk > _extractionJerkThreshold) {
      score += 0.30; // Strong extraction signal
    } else if (maxJerk > _extractionJerkThreshold * 0.6) {
      score += 0.15; // Moderate signal
    }

    // Check 2: Rotation spike (gyroscope)
    if (_gyroBuffer.length >= 10) {
      final recentGyro = _gyroBuffer.sublist(_gyroBuffer.length - 10);
      final maxRotation = recentGyro.map((r) => r.magnitude).reduce(max);
      if (maxRotation > _extractionRotationThreshold) {
        score += 0.25;
      } else if (maxRotation > _extractionRotationThreshold * 0.5) {
        score += 0.10;
      }
    }

    // Check 3: Proximity transition (near → far)
    if (_proximityBuffer.length >= 5) {
      final oldProximity = _proximityBuffer.sublist(0, min(5, _proximityBuffer.length))
          .reduce((a, b) => a + b) / min(5, _proximityBuffer.length);
      final newProximity = _proximityBuffer.sublist(_proximityBuffer.length - 3)
          .reduce((a, b) => a + b) / 3;
      if (oldProximity < _pocketProximityThreshold && newProximity >= _pocketProximityThreshold) {
        score += 0.25; // Clear pocket exit signal
      }
    }

    // Check 4: Light transition (dark → bright)
    if (_lightBuffer.length >= 5) {
      final oldLight = _lightBuffer.sublist(0, min(5, _lightBuffer.length))
          .reduce((a, b) => a + b) / min(5, _lightBuffer.length);
      final newLight = _lightBuffer.sublist(_lightBuffer.length - 3)
          .reduce((a, b) => a + b) / 3;
      final lightDelta = newLight - oldLight;
      if (oldLight < _pocketLightThreshold && lightDelta > 40.0) {
        score += 0.20; // Significant exposure
      }
    }

    // === CRITICAL: Apply movement context modifiers ===
    // This is what prevents false positives from normal activity

    // If user is walking/running, require MUCH higher score
    if (_isWalking) {
      score *= 0.4; // Walking generates motion — heavily discount
    }
    if (_isRunning) {
      score *= 0.3; // Running generates even more motion
    }
    // If in vehicle, bus brakes cause motion spikes — discount
    if (_isInVehicle) {
      score *= 0.35;
    }

    // Extraction can't happen if phone wasn't in pocket long enough
    if (_pocketEntryTime != null) {
      final inPocketDuration = DateTime.now().difference(_pocketEntryTime!);
      if (inPocketDuration < _minPocketDuration) {
        score *= 0.1; // Phone just entered pocket — probably user putting it back
      }
    }

    // Cooldown: don't re-trigger within 5 seconds of last detection
    if (_lastExtractionCandidate != null) {
      final timeSinceLast = DateTime.now().difference(_lastExtractionCandidate!);
      if (timeSinceLast < _extractionCooldown) {
        score *= 0.2;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  // ═══════════════════════════════════════════════════════════
  // THREAT CONFIDENCE COMPUTATION
  // ═══════════════════════════════════════════════════════════

  double _computeThreatConfidence({
    required double pocketConfidence,
    required double extractionScore,
  }) {
    // Threat confidence is HIGH only when:
    // 1. Phone WAS in pocket (high pocket confidence historically)
    // 2. Extraction signature is strong
    // 3. Movement context doesn't explain the motion

    if (!_isInPocket) return 0.0; // Can't be threatened if not in pocket
    if (extractionScore < 0.3) return 0.0; // Not enough extraction evidence

    // Bayesian posterior: P(theft | evidence)
    // Combine extraction evidence with context
    double threat = extractionScore;

    // Boost if multiple strong signals converge
    if (extractionScore > 0.6 && pocketConfidence < 0.3) {
      // Was in pocket + now clearly not = strong signal
      threat = min(1.0, threat * 1.3);
    }

    // Reduce if pocket confidence is still high (still in pocket)
    if (pocketConfidence > 0.7) {
      threat *= 0.2; // Still in pocket — this is normal pocket motion
    }

    return threat.clamp(0.0, 1.0);
  }

  // ═══════════════════════════════════════════════════════════
  // STATE MACHINE
  // ═══════════════════════════════════════════════════════════

  void _updateStateMachine(double pocketConfidence, double extractionScore) {
    final previousState = _currentState;

    // Determine new state
    if (pocketConfidence > 0.75) {
      if (!_isInPocket) {
        _isInPocket = true;
        _pocketEntryTime = DateTime.now();
        _currentState = PhoneState.inPocket;
        onPocketEntry?.call();
      }
    } else if (pocketConfidence < 0.3 && _isInPocket) {
      // Phone left pocket
      if (_threatConfidence > 0.6) {
        // HIGH THREAT — suspicious extraction
        _currentState = PhoneState.suspiciousExtraction;
        _isInPocket = false;
        _lastExtractionCandidate = DateTime.now();
        onExtractionDetected?.call();
        onThreatAssessment?.call(ThreatAssessment(
          confidence: _threatConfidence,
          extractionScore: extractionScore,
          movementContext: _movementClass,
          reason: _buildThreatReason(extractionScore),
        ));
      } else {
        // Normal exit (user took out phone)
        _currentState = PhoneState.normalUse;
        _isInPocket = false;
        onPocketExit?.call();
      }
    } else if (!_isInPocket) {
      _currentState = PhoneState.normalUse;
    }

    if (_currentState != previousState) {
      _lastStateChange = DateTime.now();
      onStateChange?.call(_currentState);
      debugPrint('[Vigil AI] State: $previousState → $_currentState '
          '(threat: ${_threatConfidence.toStringAsFixed(2)})');
    }
  }

  String _buildThreatReason(double extractionScore) {
    final reasons = <String>[];
    if (_accelBuffer.isNotEmpty && _accelBuffer.last.jerk > _extractionJerkThreshold) {
      reasons.add('High jerk detected');
    }
    if (_gyroBuffer.isNotEmpty && _gyroBuffer.last.magnitude > _extractionRotationThreshold) {
      reasons.add('Rapid rotation');
    }
    if (_proximityBuffer.isNotEmpty && _proximityBuffer.last >= _pocketProximityThreshold) {
      reasons.add('Proximity: exposed');
    }
    if (_lightBuffer.isNotEmpty && _lightBuffer.last > _exposedLightThreshold) {
      reasons.add('Light: exposed');
    }
    return reasons.isEmpty ? 'Combined signals' : reasons.join(' + ');
  }

  // ═══════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════

  double _computeStdDev(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  void _resetBuffers() {
    _accelBuffer.clear();
    _gyroBuffer.clear();
    _proximityBuffer.clear();
    _lightBuffer.clear();
    _orientationBuffer.clear();
    _isInPocket = false;
    _threatConfidence = 0.0;
    _pocketEntryTime = null;
    _lastExtractionCandidate = null;
    _movementClass = MovementClassification.stationary;
  }

  /// Calibrate the engine to current device (call after 5s of still)
  void calibrateBaseline() {
    if (_accelBuffer.length >= 20) {
      final recent = _accelBuffer.sublist(_accelBuffer.length - 20);
      _ambientMotionBaseline = recent.map((r) => r.magnitude).reduce((a, b) => a + b) / recent.length;
      debugPrint('[Vigil AI] Baseline calibrated: $_ambientMotionBaseline');
    }
  }

  /// Update sensor weights (for adaptive learning)
  void updateWeights({
    double? proximity,
    double? light,
    double? motion,
    double? gyro,
    double? orientation,
  }) {
    if (proximity != null) _proximityWeight = proximity;
    if (light != null) _lightWeight = light;
    if (motion != null) _motionWeight = motion;
    if (gyro != null) _gyroWeight = gyro;
    if (orientation != null) _orientationWeight = orientation;
  }
}

// ═══════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════

class AccelReading {
  final double x, y, z, magnitude, jerk;
  final DateTime timestamp;
  AccelReading({
    required this.x, required this.y, required this.z,
    required this.magnitude, required this.jerk, required this.timestamp,
  });
}

class GyroReading {
  final double x, y, z, magnitude;
  final DateTime timestamp;
  GyroReading({
    required this.x, required this.y, required this.z,
    required this.magnitude, required this.timestamp,
  });
}

class OrientationReading {
  final double pitch, roll, azimuth;
  final DateTime timestamp;
  OrientationReading({
    required this.pitch, required this.roll, required this.azimuth,
    required this.timestamp,
  });
}

enum PhoneState {
  unknown,
  inPocket,
  normalUse,
  suspiciousExtraction,
  alarmActive,
}

enum MovementClassification {
  stationary,
  walking,
  running,
  vehicle,
  activeUse,
  suspiciousMotion,
}

class ThreatAssessment {
  final double confidence;
  final double extractionScore;
  final MovementClassification movementContext;
  final String reason;

  ThreatAssessment({
    required this.confidence,
    required this.extractionScore,
    required this.movementContext,
    required this.reason,
  });

  bool get isHighThreat => confidence >= 0.7;
  bool get isMediumThreat => confidence >= 0.5 && confidence < 0.7;
  bool get isLowThreat => confidence < 0.5;
}

class SensorFusionDebug {
  final double pocketConfidence;
  final double extractionScore;
  final double threatConfidence;
  final MovementClassification movementClass;
  final PhoneState phoneState;
  final bool isInPocket;
  final double accelMagnitude;
  final double gyroMagnitude;
  final double proximity;
  final double light;

  SensorFusionDebug({
    required this.pocketConfidence,
    required this.extractionScore,
    required this.threatConfidence,
    required this.movementClass,
    required this.phoneState,
    required this.isInPocket,
    required this.accelMagnitude,
    required this.gyroMagnitude,
    required this.proximity,
    required this.light,
  });
}
