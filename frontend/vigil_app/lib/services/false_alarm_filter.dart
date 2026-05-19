import 'dart:math';
import 'package:flutter/foundation.dart';

/// Advanced false alarm filtering system.
/// Distinguishes between genuine pocket removal and common false triggers:
/// - Bus/metro brakes (sudden deceleration without pocket exit)
/// - Walking/running motion (rhythmic, predictable)
/// - Normal pocket shifting (minor proximity changes)
/// - Bending over / sitting down (temporary light/proximity changes)
class FalseAlarmFilter {
  static final FalseAlarmFilter _instance = FalseAlarmFilter._internal();
  factory FalseAlarmFilter() => _instance;
  FalseAlarmFilter._internal();

  // Motion pattern history for analysis
  final List<_MotionReading> _motionBuffer = [];
  static const int _bufferSize = 50; // ~5 seconds at 10Hz
  static const int _patternWindowSize = 20; // Recent readings for pattern

  // Calibration values (learned from user behavior)
  double _baselineMotion = 9.8; // Gravity baseline
  double _walkingFrequency = 0.0; // Detected walking cadence
  bool _isUserWalking = false;
  bool _isInVehicle = false;

  /// Add a motion reading to the buffer
  void addMotionReading(double x, double y, double z, DateTime timestamp) {
    final magnitude = sqrt(x * x + y * y + z * z);
    _motionBuffer.add(_MotionReading(
      magnitude: magnitude,
      x: x,
      y: y,
      z: z,
      timestamp: timestamp,
    ));

    if (_motionBuffer.length > _bufferSize) {
      _motionBuffer.removeAt(0);
    }

    // Update motion patterns
    _analyzeMotionPattern();
  }

  /// Determine if the current removal signal should be filtered (is a false alarm)
  FalseAlarmResult shouldFilter({
    required double proximityChange,
    required double lightChange,
    required double motionSpike,
  }) {
    final reasons = <String>[];
    double falseAlarmScore = 0.0;

    // Check 1: Walking pattern detected
    if (_isUserWalking && motionSpike < 12.0) {
      falseAlarmScore += 0.3;
      reasons.add('Walking pattern detected');
    }

    // Check 2: Vehicle motion (constant vibration + occasional spikes)
    if (_isInVehicle && motionSpike < 15.0) {
      falseAlarmScore += 0.35;
      reasons.add('Vehicle motion pattern');
    }

    // Check 3: Only motion spike without light/proximity change
    if (motionSpike > 8.0 && proximityChange < 0.5 && lightChange < 20) {
      falseAlarmScore += 0.25;
      reasons.add('Motion-only spike (no pocket exit signals)');
    }

    // Check 4: Gradual light change (not sudden exposure)
    if (lightChange > 0 && lightChange < 30 && _isGradualLightChange()) {
      falseAlarmScore += 0.2;
      reasons.add('Gradual light change (not sudden)');
    }

    // Check 5: Repeated short proximity changes (shifting in pocket)
    if (_hasRepeatedProximityChanges()) {
      falseAlarmScore += 0.25;
      reasons.add('Repeated short proximity fluctuations');
    }

    // Check 6: Rhythmic motion (exercise, walking, running)
    if (_hasRhythmicMotion()) {
      falseAlarmScore += 0.2;
      reasons.add('Rhythmic motion detected');
    }

    final shouldFilter = falseAlarmScore >= 0.5;

    if (shouldFilter) {
      debugPrint('[Vigil Filter] FALSE ALARM blocked (score: $falseAlarmScore). '
          'Reasons: ${reasons.join(", ")}');
    }

    return FalseAlarmResult(
      isFalseAlarm: shouldFilter,
      confidence: falseAlarmScore,
      reasons: reasons,
    );
  }

  /// Analyze motion buffer for patterns
  void _analyzeMotionPattern() {
    if (_motionBuffer.length < _patternWindowSize) return;

    final recent = _motionBuffer.sublist(_motionBuffer.length - _patternWindowSize);

    // Detect walking: rhythmic ~1.5-2.5Hz oscillation
    _isUserWalking = _detectWalkingPattern(recent);

    // Detect vehicle: constant low-frequency vibration with occasional spikes
    _isInVehicle = _detectVehiclePattern(recent);
  }

  /// Detect walking using motion frequency analysis
  bool _detectWalkingPattern(List<_MotionReading> readings) {
    if (readings.length < 10) return false;

    // Count zero-crossings around baseline (simplified frequency detection)
    int crossings = 0;
    for (int i = 1; i < readings.length; i++) {
      final prev = readings[i - 1].magnitude - _baselineMotion;
      final curr = readings[i].magnitude - _baselineMotion;
      if ((prev > 0 && curr < 0) || (prev < 0 && curr > 0)) {
        crossings++;
      }
    }

    // Walking typically has 3-5 crossings per second
    final duration = readings.last.timestamp
        .difference(readings.first.timestamp)
        .inMilliseconds;
    if (duration <= 0) return false;

    final frequency = crossings / (duration / 1000.0);
    _walkingFrequency = frequency;

    return frequency >= 1.5 && frequency <= 4.0;
  }

  /// Detect vehicle motion pattern
  bool _detectVehiclePattern(List<_MotionReading> readings) {
    if (readings.length < 10) return false;

    // Vehicle: relatively constant with small vibrations
    final magnitudes = readings.map((r) => r.magnitude).toList();
    final avg = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final variance = magnitudes
            .map((m) => (m - avg) * (m - avg))
            .reduce((a, b) => a + b) /
        magnitudes.length;
    final stdDev = sqrt(variance);

    // Low std deviation + close to gravity = stationary in vehicle
    // Moderate std deviation + occasional spikes = moving vehicle
    return stdDev > 0.3 && stdDev < 2.0 && avg < 11.0;
  }

  /// Check if light change is gradual (over many readings) vs sudden
  bool _isGradualLightChange() {
    // Would analyze light sensor history - simplified for now
    return false;
  }

  /// Check for repeated short proximity fluctuations (phone shifting in pocket)
  bool _hasRepeatedProximityChanges() {
    // Would analyze proximity history - simplified for now
    return false;
  }

  /// Check for rhythmic motion patterns (exercise, walking, etc.)
  bool _hasRhythmicMotion() {
    return _isUserWalking;
  }

  /// Get current motion analysis for debugging/UI
  MotionAnalysis getMotionAnalysis() {
    return MotionAnalysis(
      isWalking: _isUserWalking,
      isInVehicle: _isInVehicle,
      walkingFrequency: _walkingFrequency,
      baselineMotion: _baselineMotion,
      bufferSize: _motionBuffer.length,
    );
  }

  /// Reset the filter (on pocket mode activation)
  void reset() {
    _motionBuffer.clear();
    _isUserWalking = false;
    _isInVehicle = false;
    _walkingFrequency = 0.0;
  }
}

class _MotionReading {
  final double magnitude;
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  _MotionReading({
    required this.magnitude,
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });
}

/// Result from false alarm check
class FalseAlarmResult {
  final bool isFalseAlarm;
  final double confidence;
  final List<String> reasons;

  FalseAlarmResult({
    required this.isFalseAlarm,
    required this.confidence,
    required this.reasons,
  });
}

/// Motion analysis data for UI/debugging
class MotionAnalysis {
  final bool isWalking;
  final bool isInVehicle;
  final double walkingFrequency;
  final double baselineMotion;
  final int bufferSize;

  MotionAnalysis({
    required this.isWalking,
    required this.isInVehicle,
    required this.walkingFrequency,
    required this.baselineMotion,
    required this.bufferSize,
  });
}
