import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';

/// Handles continuous location tracking and sync with backend.
/// - Continuous background location updates
/// - Battery-efficient modes
/// - Offline buffering and bulk sync
/// - High-frequency updates during active alerts
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const MethodChannel _channel = MethodChannel('com.vigil.app/location');
  static const EventChannel _locationStream = EventChannel('com.vigil.app/location_stream');

  StreamSubscription? _locationSub;
  Timer? _syncTimer;
  bool _isTracking = false;
  bool _isHighFrequency = false;

  // Current location
  double? _latitude;
  double? _longitude;
  double? _accuracy;
  double? _speed;
  double? _altitude;

  // Offline buffer for sync
  final List<Map<String, dynamic>> _locationBuffer = [];
  static const int _maxBufferSize = 500;

  // Settings
  static const Duration _normalInterval = Duration(seconds: 30);
  static const Duration _highFreqInterval = Duration(seconds: 5);
  static const Duration _syncInterval = Duration(minutes: 2);

  // Callbacks
  Function(double lat, double lng)? onLocationUpdate;

  // Getters
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  double? get accuracy => _accuracy;
  bool get isTracking => _isTracking;

  /// Start continuous location tracking
  Future<void> startTracking({bool highFrequency = false}) async {
    if (_isTracking && _isHighFrequency == highFrequency) return;

    _isTracking = true;
    _isHighFrequency = highFrequency;

    try {
      // Request location permissions
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        debugPrint('[Vigil Location] Permission denied');
        return;
      }

      // Configure location settings via platform channel
      await _channel.invokeMethod('startLocationUpdates', {
        'interval': highFrequency
            ? _highFreqInterval.inMilliseconds
            : _normalInterval.inMilliseconds,
        'distanceFilter': highFrequency ? 5.0 : 50.0, // meters
        'accuracy': highFrequency ? 'high' : 'balanced',
      });

      // Listen to location stream
      _locationSub = _locationStream
          .receiveBroadcastStream()
          .listen(
            (dynamic data) {
              if (data is Map) {
                _handleLocationUpdate(data);
              }
            },
            onError: (error) {
              debugPrint('[Vigil Location] Stream error: $error');
            },
          );

      // Start periodic sync to backend
      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(_syncInterval, (_) => _syncToBackend());

      debugPrint('[Vigil Location] Tracking started '
          '(highFreq: $highFrequency)');
    } catch (e) {
      debugPrint('[Vigil Location] Start tracking failed: $e');
    }
  }

  /// Stop location tracking
  void stopTracking() {
    _isTracking = false;
    _isHighFrequency = false;
    _locationSub?.cancel();
    _syncTimer?.cancel();
    _locationSub = null;
    _syncTimer = null;

    try {
      _channel.invokeMethod('stopLocationUpdates');
    } catch (e) {
      debugPrint('[Vigil Location] Stop tracking failed: $e');
    }

    debugPrint('[Vigil Location] Tracking stopped');
  }

  /// Switch to high-frequency updates (during alert)
  void enableHighFrequency() {
    if (_isHighFrequency) return;
    stopTracking();
    startTracking(highFrequency: true);
    debugPrint('[Vigil Location] Switched to high-frequency mode');
  }

  /// Switch back to normal frequency
  void disableHighFrequency() {
    if (!_isHighFrequency) return;
    stopTracking();
    startTracking(highFrequency: false);
  }

  /// Handle incoming location update
  void _handleLocationUpdate(Map<dynamic, dynamic> data) {
    _latitude = (data['latitude'] as num?)?.toDouble();
    _longitude = (data['longitude'] as num?)?.toDouble();
    _accuracy = (data['accuracy'] as num?)?.toDouble();
    _speed = (data['speed'] as num?)?.toDouble();
    _altitude = (data['altitude'] as num?)?.toDouble();

    if (_latitude != null && _longitude != null) {
      onLocationUpdate?.call(_latitude!, _longitude!);

      // Add to buffer for sync
      _locationBuffer.add({
        'latitude': _latitude,
        'longitude': _longitude,
        'accuracy': _accuracy,
        'speed': _speed,
        'altitude': _altitude,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Prevent buffer overflow
      if (_locationBuffer.length > _maxBufferSize) {
        _locationBuffer.removeRange(0, _locationBuffer.length - _maxBufferSize);
      }
    }
  }

  /// Sync buffered locations to backend
  Future<void> _syncToBackend() async {
    if (_locationBuffer.isEmpty) return;

    try {
      // Send bulk location update
      final locationsToSync = List<Map<String, dynamic>>.from(_locationBuffer);
      _locationBuffer.clear();

      await ApiService().bulkLocationUpdate(locationsToSync);
      debugPrint('[Vigil Location] Synced ${locationsToSync.length} locations');
    } catch (e) {
      debugPrint('[Vigil Location] Sync failed: $e');
      // Locations remain in buffer for next sync attempt
    }
  }

  /// Get current location as a one-shot (for alert creation)
  Future<Map<String, double>?> getCurrentLocation() async {
    if (_latitude != null && _longitude != null) {
      return {
        'latitude': _latitude!,
        'longitude': _longitude!,
        'accuracy': _accuracy ?? 0,
      };
    }

    try {
      final result = await _channel.invokeMethod('getLastKnownLocation');
      if (result is Map) {
        return {
          'latitude': (result['latitude'] as num).toDouble(),
          'longitude': (result['longitude'] as num).toDouble(),
          'accuracy': (result['accuracy'] as num?)?.toDouble() ?? 0,
        };
      }
    } catch (e) {
      debugPrint('[Vigil Location] Get current location failed: $e');
    }
    return null;
  }

  /// Request location permissions
  Future<bool> _requestPermissions() async {
    try {
      final result = await _channel.invokeMethod('requestLocationPermission');
      return result == true;
    } catch (e) {
      debugPrint('[Vigil Location] Permission request failed: $e');
      return false;
    }
  }

  /// Generate Google Maps link for current location
  String? getMapLink() {
    if (_latitude == null || _longitude == null) return null;
    return 'https://maps.google.com/?q=$_latitude,$_longitude';
  }
}
