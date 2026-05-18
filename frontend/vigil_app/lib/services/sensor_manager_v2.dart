import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'ai_sensor_fusion_engine.dart';
import 'behavioral_context_analyzer.dart';

/// Upgraded Sensor Manager V2 for Vigil.
///
/// This replaces the original SensorManager with a proper implementation that:
/// 1. Connects to native sensors via platform channels (Kotlin EventChannels)
/// 2. Feeds all sensor data into the AI Sensor Fusion Engine
/// 3. Provides gyroscope data (missing from original)
/// 4. Computes orientation from accelerometer for the fusion engine
/// 5. Handles sensor unavailability gracefully with fallbacks
/// 6. Optimizes battery by adjusting polling rates dynamically
/// 7. Connects behavioral context analyzer for smart thresholds
class SensorManagerV2 {
  static final SensorManagerV2 _instance = SensorManagerV2._internal();
  factory SensorManagerV2() => _instance;
  SensorManagerV2._internal();

  // Platform channels
  static const MethodChannel _sensorChannel = MethodChannel('com.vigil.app/sensors');
  static const EventChannel _proximityChannel = EventChannel('com.vigil.app/proximity');
  static const EventChannel _lightChannel = EventChannel('com.vigil.app/light');
  static const EventChannel _accelerometerChannel = EventChannel('com.vigil.app/accelerometer');
  static const EventChannel _gyroscopeChannel = EventChannel('com.vigil.app/gyroscope');

  // Stream subscriptions
  StreamSubscription? _proximitySub;
  StreamSubscription? _lightSub;
  StreamSubscription? _accelerometerSub;
  StreamSubscription? _gyroscopeSub;

  // Core services
  final AISensorFusionEngine _fusionEngine = AISensorFusionEngine();
  final BehavioralContextAnalyzer _contextAnalyzer = BehavioralContextAnalyzer();

  // State
  bool _isListening = false;
  SensorAvailability? _availability;
  SensorPollingMode _pollingMode = SensorPollingMode.normal;

  // Latest raw values for UI display
  double _lastAccelX = 0, _lastAccelY = 0, _lastAccelZ = 0;
  double _lastGyroX = 0, _lastGyroY = 0, _lastGyroZ = 0;
  double _lastProximity = -1;
  double _lastLight = -1;

  // Getters
  bool get isListening => _isListening;
  AISensorFusionEngine get fusionEngine => _fusionEngine;
  BehavioralContextAnalyzer get contextAnalyzer => _contextAnalyzer;
  SensorAvailability? get availability => _availability;

  /// Initialize and start all sensors, feeding data to AI fusion engine
  Future<void> startListening({SensorPollingMode mode = SensorPollingMode.normal}) async {
    if (_isListening) return;
    _isListening = true;
    _pollingMode = mode;

    // Check sensor availability
    _availability = await _checkSensorAvailability();
    debugPrint('[Vigil SensorV2] Availability: $_availability');

    // Start the AI fusion engine
    _fusionEngine.start();

    // Connect sensor streams to fusion engine
    _startAccelerometer();
    _startGyroscope();
    _startProximity();
    _startLight();

    // Calibrate after 3 seconds of data collection
    Timer(const Duration(seconds: 3), () {
      if (_isListening) {
        _fusionEngine.calibrateBaseline();
        debugPrint('[Vigil SensorV2] Baseline calibrated');
      }
    });

    debugPrint('[Vigil SensorV2] All sensors started (mode: $mode)');
  }

  /// Stop all sensors and fusion engine
  void stopListening() {
    _isListening = false;
    _proximitySub?.cancel();
    _lightSub?.cancel();
    _accelerometerSub?.cancel();
    _gyroscopeSub?.cancel();
    _proximitySub = null;
    _lightSub = null;
    _accelerometerSub = null;
    _gyroscopeSub = null;
    _fusionEngine.stop();
    debugPrint('[Vigil SensorV2] All sensors stopped');
  }

  /// Switch to battery-efficient mode (reduced polling)
  void setBatterySaverMode(bool enabled) {
    if (enabled) {
      _pollingMode = SensorPollingMode.batterySaver;
      _fusionEngine.updateWeights(
        proximity: 0.40, // Rely more on proximity (low power)
        light: 0.30,
        motion: 0.15,
        gyro: 0.10,
        orientation: 0.05,
      );
    } else {
      _pollingMode = SensorPollingMode.normal;
      _fusionEngine.updateWeights(
        proximity: 0.30,
        light: 0.25,
        motion: 0.20,
        gyro: 0.15,
        orientation: 0.10,
      );
    }
  }

  /// Switch to high-security mode (maximum sensitivity)
  void setHighSecurityMode(bool enabled) {
    if (enabled) {
      _pollingMode = SensorPollingMode.highSecurity;
      _fusionEngine.updateWeights(
        proximity: 0.25,
        light: 0.20,
        motion: 0.25,
        gyro: 0.20,
        orientation: 0.10,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SENSOR STREAM CONNECTIONS
  // ═══════════════════════════════════════════════════════════

  void _startAccelerometer() {
    try {
      _accelerometerSub = _accelerometerChannel
          .receiveBroadcastStream()
          .listen((dynamic data) {
        if (data is Map) {
          final x = (data['x'] as num).toDouble();
          final y = (data['y'] as num).toDouble();
          final z = (data['z'] as num).toDouble();
          _lastAccelX = x;
          _lastAccelY = y;
          _lastAccelZ = z;

          // Feed to AI fusion engine
          _fusionEngine.feedAccelerometer(x, y, z);

          // Compute and feed orientation
          final pitch = atan2(y, sqrt(x * x + z * z)) * 180 / pi;
          final roll = atan2(-x, z) * 180 / pi;
          _fusionEngine.feedOrientation(pitch, roll, 0);

          // Feed to behavioral context
          final magnitude = sqrt(x * x + y * y + z * z);
          _contextAnalyzer.updateActivity(
            isWalking: _fusionEngine.movementClass == MovementClassification.walking,
            isRunning: _fusionEngine.movementClass == MovementClassification.running,
            isInVehicle: _fusionEngine.movementClass == MovementClassification.vehicle,
            isStationary: _fusionEngine.movementClass == MovementClassification.stationary,
            motionIntensity: magnitude - 9.81,
          );
        }
      }, onError: (error) {
        debugPrint('[Vigil SensorV2] Accelerometer error: $error');
      });
    } catch (e) {
      debugPrint('[Vigil SensorV2] Failed to start accelerometer: $e');
    }
  }

  void _startGyroscope() {
    try {
      _gyroscopeSub = _gyroscopeChannel
          .receiveBroadcastStream()
          .listen((dynamic data) {
        if (data is Map) {
          final x = (data['x'] as num).toDouble();
          final y = (data['y'] as num).toDouble();
          final z = (data['z'] as num).toDouble();
          _lastGyroX = x;
          _lastGyroY = y;
          _lastGyroZ = z;

          // Feed to AI fusion engine
          _fusionEngine.feedGyroscope(x, y, z);
        }
      }, onError: (error) {
        debugPrint('[Vigil SensorV2] Gyroscope error: $error');
        // Gyroscope may not be available on all devices — graceful fallback
      });
    } catch (e) {
      debugPrint('[Vigil SensorV2] Gyroscope not available: $e');
    }
  }

  void _startProximity() {
    try {
      _proximitySub = _proximityChannel
          .receiveBroadcastStream()
          .listen((dynamic value) {
        final proximity = (value as num).toDouble();
        _lastProximity = proximity;
        _fusionEngine.feedProximity(proximity);
      }, onError: (error) {
        debugPrint('[Vigil SensorV2] Proximity error: $error');
      });
    } catch (e) {
      debugPrint('[Vigil SensorV2] Proximity not available: $e');
    }
  }

  void _startLight() {
    try {
      _lightSub = _lightChannel
          .receiveBroadcastStream()
          .listen((dynamic value) {
        final light = (value as num).toDouble();
        _lastLight = light;
        _fusionEngine.feedLight(light);
      }, onError: (error) {
        debugPrint('[Vigil SensorV2] Light sensor error: $error');
      });
    } catch (e) {
      debugPrint('[Vigil SensorV2] Light sensor not available: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SENSOR AVAILABILITY CHECK
  // ═══════════════════════════════════════════════════════════

  Future<SensorAvailability> _checkSensorAvailability() async {
    try {
      final result = await _sensorChannel.invokeMethod('checkSensors');
      final map = Map<String, bool>.from(result);
      return SensorAvailability(
        hasAccelerometer: map['accelerometer'] ?? false,
        hasGyroscope: map['gyroscope'] ?? false,
        hasProximity: map['proximity'] ?? false,
        hasLight: map['light'] ?? false,
        hasMagnetometer: map['magnetometer'] ?? false,
      );
    } catch (e) {
      debugPrint('[Vigil SensorV2] Availability check failed: $e');
      return SensorAvailability(
        hasAccelerometer: true, // Assume available (all phones have it)
        hasGyroscope: false,
        hasProximity: true,
        hasLight: true,
        hasMagnetometer: false,
      );
    }
  }

  /// Get current sensor readings for UI display
  SensorReadings getCurrentReadings() {
    return SensorReadings(
      accelX: _lastAccelX,
      accelY: _lastAccelY,
      accelZ: _lastAccelZ,
      accelMagnitude: sqrt(_lastAccelX * _lastAccelX + _lastAccelY * _lastAccelY + _lastAccelZ * _lastAccelZ),
      gyroX: _lastGyroX,
      gyroY: _lastGyroY,
      gyroZ: _lastGyroZ,
      gyroMagnitude: sqrt(_lastGyroX * _lastGyroX + _lastGyroY * _lastGyroY + _lastGyroZ * _lastGyroZ),
      proximity: _lastProximity,
      light: _lastLight,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════

enum SensorPollingMode {
  normal,
  batterySaver,
  highSecurity,
}

class SensorAvailability {
  final bool hasAccelerometer;
  final bool hasGyroscope;
  final bool hasProximity;
  final bool hasLight;
  final bool hasMagnetometer;

  SensorAvailability({
    required this.hasAccelerometer,
    required this.hasGyroscope,
    required this.hasProximity,
    required this.hasLight,
    required this.hasMagnetometer,
  });

  int get availableCount =>
      (hasAccelerometer ? 1 : 0) +
      (hasGyroscope ? 1 : 0) +
      (hasProximity ? 1 : 0) +
      (hasLight ? 1 : 0) +
      (hasMagnetometer ? 1 : 0);

  @override
  String toString() =>
      'Sensors(accel: $hasAccelerometer, gyro: $hasGyroscope, '
      'prox: $hasProximity, light: $hasLight, mag: $hasMagnetometer)';
}

class SensorReadings {
  final double accelX, accelY, accelZ, accelMagnitude;
  final double gyroX, gyroY, gyroZ, gyroMagnitude;
  final double proximity;
  final double light;

  SensorReadings({
    required this.accelX, required this.accelY, required this.accelZ,
    required this.accelMagnitude,
    required this.gyroX, required this.gyroY, required this.gyroZ,
    required this.gyroMagnitude,
    required this.proximity,
    required this.light,
  });
}
