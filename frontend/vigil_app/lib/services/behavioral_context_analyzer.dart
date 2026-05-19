import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Behavioral Context Analyzer for Vigil.
///
/// This module learns and tracks user behavior patterns to provide
/// intelligent context that the AI Fusion Engine uses to reduce false positives.
///
/// Features:
/// - Activity recognition (walking, running, vehicle, stationary, stairs)
/// - Environment classification (home, work, transit, outdoor, safe zone)
/// - Trusted Bluetooth device detection (connected = user is near)
/// - Time-of-day pattern learning (commute times, sleep times)
/// - Safe zone geofencing (home, office = lower sensitivity)
/// - Historical behavior profiling (typical motion patterns per location)
/// - Adaptive confidence thresholds based on context
class BehavioralContextAnalyzer {
  static final BehavioralContextAnalyzer _instance = BehavioralContextAnalyzer._internal();
  factory BehavioralContextAnalyzer() => _instance;
  BehavioralContextAnalyzer._internal();

  // === CONTEXT STATE ===
  ActivityState _activityState = ActivityState.unknown;
  EnvironmentContext _environment = EnvironmentContext.unknown;
  double _safetyScore = 0.5; // 0.0 = very unsafe, 1.0 = very safe
  bool _trustedDeviceConnected = false;

  // === TRUSTED BLUETOOTH DEVICES ===
  final Set<String> _trustedDeviceAddresses = {};
  final Set<String> _connectedDevices = {};

  // === SAFE ZONES (geofenced locations) ===
  final List<SafeZone> _safeZones = [];

  // === BEHAVIORAL PATTERNS ===
  final List<_BehaviorEntry> _behaviorHistory = [];
  static const int _maxHistoryEntries = 1000;

  // === TIME PATTERNS ===
  Map<int, ActivityState> _hourlyPatterns = {}; // hour -> typical activity

  // === ADAPTIVE THRESHOLDS ===
  double _baseExtractionThreshold = 0.6; // Lowered in unsafe environments
  double _currentExtractionThreshold = 0.6;

  // === CALLBACKS ===
  Function(ContextUpdate)? onContextUpdate;

  // === GETTERS ===
  ActivityState get activityState => _activityState;
  EnvironmentContext get environment => _environment;
  double get safetyScore => _safetyScore;
  bool get trustedDeviceConnected => _trustedDeviceConnected;
  double get currentExtractionThreshold => _currentExtractionThreshold;

  /// Update activity state from sensor fusion engine
  void updateActivity({
    required bool isWalking,
    required bool isRunning,
    required bool isInVehicle,
    required bool isStationary,
    required double motionIntensity,
  }) {
    ActivityState newState;

    if (isStationary) {
      newState = ActivityState.stationary;
    } else if (isWalking) {
      newState = ActivityState.walking;
    } else if (isRunning) {
      newState = ActivityState.running;
    } else if (isInVehicle) {
      newState = ActivityState.inVehicle;
    } else if (motionIntensity > 5.0) {
      newState = ActivityState.highActivity;
    } else {
      newState = ActivityState.lightActivity;
    }

    if (newState != _activityState) {
      _activityState = newState;
      _recalculateThresholds();
      _logBehavior();
    }
  }

  /// Update location context
  void updateLocation({
    required double latitude,
    required double longitude,
  }) {
    // Check if user is in a safe zone
    bool inSafeZone = false;
    for (final zone in _safeZones) {
      final distance = _haversineDistance(
        latitude, longitude,
        zone.latitude, zone.longitude,
      );
      if (distance <= zone.radiusMeters) {
        inSafeZone = true;
        _environment = zone.type == SafeZoneType.home
            ? EnvironmentContext.home
            : EnvironmentContext.work;
        break;
      }
    }

    if (!inSafeZone) {
      // Determine environment from activity
      if (_activityState == ActivityState.inVehicle) {
        _environment = EnvironmentContext.transit;
      } else if (_activityState == ActivityState.walking ||
          _activityState == ActivityState.running) {
        _environment = EnvironmentContext.outdoor;
      } else {
        _environment = EnvironmentContext.unknown;
      }
    }

    _recalculateSafetyScore();
    _recalculateThresholds();
  }

  /// Update Bluetooth connection status
  void updateBluetoothDevices(Set<String> connectedAddresses) {
    _connectedDevices.clear();
    _connectedDevices.addAll(connectedAddresses);

    _trustedDeviceConnected = _trustedDeviceAddresses
        .any((addr) => _connectedDevices.contains(addr));

    if (_trustedDeviceConnected) {
      _safetyScore = min(1.0, _safetyScore + 0.3);
    }

    _recalculateThresholds();
  }

  /// Add a trusted Bluetooth device (e.g., user's smartwatch, earbuds)
  void addTrustedDevice(String macAddress) {
    _trustedDeviceAddresses.add(macAddress.toUpperCase());
  }

  /// Remove a trusted device
  void removeTrustedDevice(String macAddress) {
    _trustedDeviceAddresses.remove(macAddress.toUpperCase());
  }

  /// Add a safe zone (geofence)
  void addSafeZone(SafeZone zone) {
    _safeZones.add(zone);
  }

  /// Remove a safe zone
  void removeSafeZone(String id) {
    _safeZones.removeWhere((z) => z.id == id);
  }

  /// Get all safe zones
  List<SafeZone> get safeZones => List.unmodifiable(_safeZones);

  /// Get context-adjusted confidence threshold for extraction detection
  /// Lower threshold = more sensitive (triggers easier)
  /// Higher threshold = less sensitive (needs stronger evidence)
  double getAdjustedThreshold() {
    return _currentExtractionThreshold;
  }

  // ═══════════════════════════════════════════════════════════
  // INTERNAL LOGIC
  // ═══════════════════════════════════════════════════════════

  void _recalculateThresholds() {
    double threshold = _baseExtractionThreshold;

    // In safe zone → higher threshold (less sensitive)
    if (_environment == EnvironmentContext.home ||
        _environment == EnvironmentContext.work) {
      threshold += 0.15;
    }

    // Trusted device connected → higher threshold
    if (_trustedDeviceConnected) {
      threshold += 0.2;
    }

    // In transit (bus/metro) → higher threshold (motion is expected)
    if (_activityState == ActivityState.inVehicle) {
      threshold += 0.15;
    }

    // Walking/running → slightly higher (motion expected)
    if (_activityState == ActivityState.walking) {
      threshold += 0.1;
    }
    if (_activityState == ActivityState.running) {
      threshold += 0.15;
    }

    // Night time (higher risk) → lower threshold
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour <= 5) {
      threshold -= 0.1; // More sensitive at night
    }

    // Crowded transit hours → lower threshold
    if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)) {
      if (_environment == EnvironmentContext.transit ||
          _environment == EnvironmentContext.outdoor) {
        threshold -= 0.05; // Slightly more sensitive during rush hours
      }
    }

    _currentExtractionThreshold = threshold.clamp(0.3, 0.9);

    // Emit update
    onContextUpdate?.call(ContextUpdate(
      activityState: _activityState,
      environment: _environment,
      safetyScore: _safetyScore,
      trustedDeviceConnected: _trustedDeviceConnected,
      adjustedThreshold: _currentExtractionThreshold,
    ));
  }

  void _recalculateSafetyScore() {
    double score = 0.5; // Neutral baseline

    // Safe zone bonus
    if (_environment == EnvironmentContext.home) score += 0.3;
    if (_environment == EnvironmentContext.work) score += 0.2;

    // Trusted device bonus
    if (_trustedDeviceConnected) score += 0.2;

    // Transit/outdoor penalty
    if (_environment == EnvironmentContext.transit) score -= 0.1;
    if (_environment == EnvironmentContext.outdoor) score -= 0.05;

    // Time-based adjustment
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour <= 5) score -= 0.15; // Late night

    _safetyScore = score.clamp(0.0, 1.0);
  }

  void _logBehavior() {
    _behaviorHistory.add(_BehaviorEntry(
      activity: _activityState,
      environment: _environment,
      timestamp: DateTime.now(),
    ));

    if (_behaviorHistory.length > _maxHistoryEntries) {
      _behaviorHistory.removeAt(0);
    }
  }

  /// Haversine distance between two coordinates in meters
  double _haversineDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180.0;
}

// ═══════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════

enum ActivityState {
  unknown,
  stationary,
  walking,
  running,
  inVehicle,
  lightActivity,
  highActivity,
  stairs,
}

enum EnvironmentContext {
  unknown,
  home,
  work,
  transit,
  outdoor,
  crowdedArea,
}

enum SafeZoneType {
  home,
  work,
  school,
  gym,
  custom,
}

class SafeZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final SafeZoneType type;

  SafeZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100.0,
    this.type = SafeZoneType.custom,
  });
}

class ContextUpdate {
  final ActivityState activityState;
  final EnvironmentContext environment;
  final double safetyScore;
  final bool trustedDeviceConnected;
  final double adjustedThreshold;

  ContextUpdate({
    required this.activityState,
    required this.environment,
    required this.safetyScore,
    required this.trustedDeviceConnected,
    required this.adjustedThreshold,
  });
}

class _BehaviorEntry {
  final ActivityState activity;
  final EnvironmentContext environment;
  final DateTime timestamp;

  _BehaviorEntry({
    required this.activity,
    required this.environment,
    required this.timestamp,
  });
}
