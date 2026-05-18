import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'pocket_detection_service.dart';

/// Manages native sensor connections and feeds data to PocketDetectionService.
/// Uses platform channels to access proximity and light sensors on Android.
class SensorManager {
  static final SensorManager _instance = SensorManager._internal();
  factory SensorManager() => _instance;
  SensorManager._internal();

  // Platform channels for native sensor access
  static const MethodChannel _channel = MethodChannel('com.vigil.app/sensors');
  static const EventChannel _proximityChannel = EventChannel('com.vigil.app/proximity');
  static const EventChannel _lightChannel = EventChannel('com.vigil.app/light');
  static const EventChannel _accelerometerChannel = EventChannel('com.vigil.app/accelerometer');

  StreamSubscription? _proximitySub;
  StreamSubscription? _lightSub;
  StreamSubscription? _accelerometerSub;

  final PocketDetectionService _detectionService = PocketDetectionService();

  bool _isListening = false;
  bool get isListening => _isListening;

  /// Start listening to all sensors
  Future<void> startListening() async {
    if (_isListening) return;
    _isListening = true;

    try {
      // Check sensor availability
      final sensorsAvailable = await _checkSensors();
      debugPrint('[Vigil SensorManager] Sensors available: $sensorsAvailable');

      // Start proximity sensor stream
      _proximitySub = _proximityChannel
          .receiveBroadcastStream()
          .listen(
            (dynamic value) {
              final double proximity = (value as num).toDouble();
              _detectionService.updateProximity(proximity);
            },
            onError: (error) {
              debugPrint('[Vigil] Proximity sensor error: $error');
            },
          );

      // Start light sensor stream
      _lightSub = _lightChannel
          .receiveBroadcastStream()
          .listen(
            (dynamic value) {
              final double light = (value as num).toDouble();
              _detectionService.updateLight(light);
            },
            onError: (error) {
              debugPrint('[Vigil] Light sensor error: $error');
            },
          );

      // Start accelerometer stream
      _accelerometerSub = _accelerometerChannel
          .receiveBroadcastStream()
          .listen(
            (dynamic value) {
              if (value is Map) {
                final x = (value['x'] as num).toDouble();
                final y = (value['y'] as num).toDouble();
                final z = (value['z'] as num).toDouble();
                _detectionService.updateAccelerometer(x, y, z);
              }
            },
            onError: (error) {
              debugPrint('[Vigil] Accelerometer error: $error');
            },
          );

      debugPrint('[Vigil SensorManager] All sensors started');
    } catch (e) {
      debugPrint('[Vigil SensorManager] Error starting sensors: $e');
      // Fallback: use sensors_plus package if platform channels fail
      _startFallbackSensors();
    }
  }

  /// Stop listening to all sensors
  void stopListening() {
    _isListening = false;
    _proximitySub?.cancel();
    _lightSub?.cancel();
    _accelerometerSub?.cancel();
    _proximitySub = null;
    _lightSub = null;
    _accelerometerSub = null;
    debugPrint('[Vigil SensorManager] All sensors stopped');
  }

  /// Check which sensors are available on the device
  Future<Map<String, bool>> _checkSensors() async {
    try {
      final result = await _channel.invokeMethod('checkSensors');
      return Map<String, bool>.from(result);
    } catch (e) {
      debugPrint('[Vigil] Sensor check failed: $e');
      return {
        'proximity': false,
        'light': false,
        'accelerometer': false,
      };
    }
  }

  /// Fallback using sensors_plus package
  void _startFallbackSensors() {
    debugPrint('[Vigil SensorManager] Using fallback sensor approach');
    // In production, this would use:
    // - sensors_plus for accelerometer/gyroscope
    // - proximity_sensor for proximity
    // - light for light sensor
    // These packages need to be added to pubspec.yaml
  }

  /// Get current sensor status for UI display
  SensorStatus getSensorStatus() {
    return SensorStatus(
      proximityActive: _proximitySub != null,
      lightActive: _lightSub != null,
      accelerometerActive: _accelerometerSub != null,
      isListening: _isListening,
    );
  }
}

/// Status of all sensors for UI display
class SensorStatus {
  final bool proximityActive;
  final bool lightActive;
  final bool accelerometerActive;
  final bool isListening;

  SensorStatus({
    required this.proximityActive,
    required this.lightActive,
    required this.accelerometerActive,
    required this.isListening,
  });

  bool get allActive => proximityActive && lightActive && accelerometerActive;
  int get activeCount =>
      (proximityActive ? 1 : 0) +
      (lightActive ? 1 : 0) +
      (accelerometerActive ? 1 : 0);
}
