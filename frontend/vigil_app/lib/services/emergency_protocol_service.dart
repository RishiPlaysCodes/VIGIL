import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'camera_service.dart';
import 'location_service.dart';

/// Full Emergency Protocol Service for Vigil.
///
/// Activated when multi-layer authentication FAILS (intruder confirmed).
/// This is the nuclear option — maximum deterrence and evidence collection.
///
/// Emergency Protocol Actions (all simultaneous):
/// 1. Continuous front camera photo capture (every 3s) + optional video clips
/// 2. Maximize screen brightness (makes phone visible/hard to hide)
/// 3. Maximize volume to 100%
/// 4. Trigger continuous non-stop alarm siren (user-selected tone)
/// 5. Activate SOS flashlight blinking pattern
/// 6. Begin continuous live location streaming to contacts
/// 7. Upload all evidence (photos, location, sensor data) to backend in real-time
/// 8. Send emergency SMS/Email with live tracking link to all contacts
/// 9. Log all sensor data for forensic analysis
/// 10. Resist easy shutdown (foreground service, device admin if available)
///
/// The protocol runs until:
/// - Owner verifies identity through multi-layer auth
/// - Remote deactivation from parent/guardian dashboard
/// - Battery dies (captured data already uploaded)
class EmergencyProtocolService {
  static final EmergencyProtocolService _instance = EmergencyProtocolService._internal();
  factory EmergencyProtocolService() => _instance;
  EmergencyProtocolService._internal();

  static const MethodChannel _channel = MethodChannel('com.vigil.app/emergency');
  static const MethodChannel _flashChannel = MethodChannel('com.vigil.app/flashlight');
  static const MethodChannel _brightnessChannel = MethodChannel('com.vigil.app/brightness');

  // State
  bool _isActive = false;
  int _photosCaptured = 0;
  int _photosUploaded = 0;
  int _locationUpdates = 0;
  DateTime? _activatedAt;
  Timer? _photoCaptureTimer;
  Timer? _evidenceSyncTimer;
  Timer? _flashlightTimer;

  // Services
  final CameraService _camera = CameraService();
  final LocationService _location = LocationService();
  final ApiService _api = ApiService();

  // Evidence buffer (for offline resilience)
  final List<EvidenceItem> _evidenceBuffer = [];
  static const int _maxEvidenceBuffer = 100;

  // Configuration
  Duration _photoCaptureInterval = const Duration(seconds: 3);
  Duration _evidenceSyncInterval = const Duration(seconds: 10);
  bool _videoCapture = false;
  bool _flashlightSOS = true;
  bool _maxBrightness = true;
  bool _maxVolume = true;

  // Callbacks
  Function(EmergencyStatus)? onStatusUpdate;
  VoidCallback? onProtocolActivated;
  VoidCallback? onProtocolDeactivated;
  Function(int)? onPhotoCaptured;
  Function(String)? onError;

  // Getters
  bool get isActive => _isActive;
  int get photosCaptured => _photosCaptured;
  int get photosUploaded => _photosUploaded;
  DateTime? get activatedAt => _activatedAt;
  Duration get uptime => _activatedAt != null
      ? DateTime.now().difference(_activatedAt!)
      : Duration.zero;

  /// Activate the FULL emergency protocol
  Future<void> activate({
    required int alertId,
    bool enableVideo = false,
    bool enableFlashlight = true,
    bool enableMaxBrightness = true,
  }) async {
    if (_isActive) return;
    _isActive = true;
    _activatedAt = DateTime.now();
    _photosCaptured = 0;
    _photosUploaded = 0;
    _locationUpdates = 0;
    _videoCapture = enableVideo;
    _flashlightSOS = enableFlashlight;
    _maxBrightness = enableMaxBrightness;

    debugPrint('[Vigil Emergency] PROTOCOL ACTIVATED at $_activatedAt');
    onProtocolActivated?.call();

    // === LAUNCH ALL EMERGENCY ACTIONS SIMULTANEOUSLY ===

    // 1. Maximize brightness
    if (_maxBrightness) {
      _setMaxBrightness();
    }

    // 2. Maximize volume (already done by alarm service, reinforce here)
    if (_maxVolume) {
      _setMaxVolume();
    }

    // 3. Start continuous photo capture
    _startPhotoCaptureLoop(alertId);

    // 4. Start SOS flashlight blinking
    if (_flashlightSOS) {
      _startSOSFlashlight();
    }

    // 5. Switch location to maximum frequency (every 3s)
    _location.enableHighFrequency();

    // 6. Start evidence sync loop (upload to backend)
    _startEvidenceSyncLoop(alertId);

    // 7. Emit initial status
    _emitStatus();
  }

  /// Deactivate the emergency protocol (owner verified)
  Future<void> deactivate() async {
    if (!_isActive) return;
    _isActive = false;

    debugPrint('[Vigil Emergency] Protocol deactivated '
        '(duration: ${uptime.inSeconds}s, photos: $_photosCaptured)');

    // Stop all timers
    _photoCaptureTimer?.cancel();
    _evidenceSyncTimer?.cancel();
    _flashlightTimer?.cancel();
    _photoCaptureTimer = null;
    _evidenceSyncTimer = null;
    _flashlightTimer = null;

    // Restore brightness
    _restoreBrightness();

    // Stop flashlight
    _stopFlashlight();

    // Switch location back to normal
    _location.disableHighFrequency();

    // Final evidence sync
    await _syncEvidenceToBackend();

    onProtocolDeactivated?.call();
  }

  // ═══════════════════════════════════════════════════════════
  // CONTINUOUS PHOTO CAPTURE
  // ═══════════════════════════════════════════════════════════

  void _startPhotoCaptureLoop(int alertId) {
    _photoCaptureTimer?.cancel();
    _photoCaptureTimer = Timer.periodic(_photoCaptureInterval, (_) async {
      if (!_isActive) return;

      try {
        // Capture front camera photo (silent, no flash)
        final photoPath = await _camera.captureIntruderPhoto();

        if (photoPath != null) {
          _photosCaptured++;
          onPhotoCaptured?.call(_photosCaptured);

          // Add to evidence buffer
          _evidenceBuffer.add(EvidenceItem(
            type: EvidenceType.photo,
            filePath: photoPath,
            timestamp: DateTime.now(),
            alertId: alertId,
            uploaded: false,
          ));

          // Trim buffer if too large
          if (_evidenceBuffer.length > _maxEvidenceBuffer) {
            _evidenceBuffer.removeAt(0);
          }

          debugPrint('[Vigil Emergency] Photo #$_photosCaptured captured');
        }
      } catch (e) {
        onError?.call('Photo capture failed: $e');
      }

      _emitStatus();
    });
  }

  // ═══════════════════════════════════════════════════════════
  // EVIDENCE SYNC (upload to backend)
  // ═══════════════════════════════════════════════════════════

  void _startEvidenceSyncLoop(int alertId) {
    _evidenceSyncTimer?.cancel();
    _evidenceSyncTimer = Timer.periodic(_evidenceSyncInterval, (_) {
      if (!_isActive) return;
      _syncEvidenceToBackend();
    });
  }

  Future<void> _syncEvidenceToBackend() async {
    final pendingItems = _evidenceBuffer.where((e) => !e.uploaded).toList();
    if (pendingItems.isEmpty) return;

    for (final item in pendingItems) {
      try {
        if (item.type == EvidenceType.photo && item.filePath != null) {
          final success = await _camera.uploadIntruderPhoto(
            alertId: item.alertId,
            photoPath: item.filePath!,
          );
          if (success) {
            item.uploaded = true;
            _photosUploaded++;
          }
        }
      } catch (e) {
        debugPrint('[Vigil Emergency] Evidence sync failed: $e');
        // Will retry on next cycle
      }
    }

    // Also send current location with evidence
    final location = await _location.getCurrentLocation();
    if (location != null) {
      _locationUpdates++;
      await _api.updateLocation({
        'latitude': location['latitude'],
        'longitude': location['longitude'],
        'accuracy': location['accuracy'],
        'speed': 0,
        'altitude': 0,
        'battery_level': 0,
        'is_moving': true,
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SOS FLASHLIGHT
  // ═══════════════════════════════════════════════════════════

  void _startSOSFlashlight() {
    // SOS pattern in Morse code: ... --- ...
    // Short (dot) = 200ms, Long (dash) = 600ms, gap = 200ms
    final sosPattern = [
      200, 200, 200, 200, 200, 200, // S: ...
      400, // letter gap
      600, 200, 600, 200, 600, 200, // O: ---
      400, // letter gap
      200, 200, 200, 200, 200, 200, // S: ...
      1000, // word gap
    ];

    int patternIndex = 0;
    bool isOn = false;

    void _nextFlash() {
      if (!_isActive || !_flashlightSOS) return;

      if (patternIndex >= sosPattern.length) {
        patternIndex = 0;
      }

      isOn = !isOn;
      if (isOn) {
        _setFlashlight(true);
      } else {
        _setFlashlight(false);
      }

      _flashlightTimer = Timer(
        Duration(milliseconds: sosPattern[patternIndex]),
        _nextFlash,
      );
      patternIndex++;
    }

    _nextFlash();
  }

  void _stopFlashlight() {
    _flashlightTimer?.cancel();
    _setFlashlight(false);
  }

  // ═══════════════════════════════════════════════════════════
  // DEVICE CONTROL (brightness, volume, flashlight)
  // ═══════════════════════════════════════════════════════════

  Future<void> _setMaxBrightness() async {
    try {
      await _brightnessChannel.invokeMethod('setMaxBrightness');
    } catch (e) {
      debugPrint('[Vigil Emergency] Set brightness failed: $e');
    }
  }

  Future<void> _restoreBrightness() async {
    try {
      await _brightnessChannel.invokeMethod('restoreBrightness');
    } catch (e) {
      debugPrint('[Vigil Emergency] Restore brightness failed: $e');
    }
  }

  Future<void> _setMaxVolume() async {
    try {
      await _channel.invokeMethod('setMaxVolume');
    } catch (e) {
      debugPrint('[Vigil Emergency] Set volume failed: $e');
    }
  }

  Future<void> _setFlashlight(bool on) async {
    try {
      await _flashChannel.invokeMethod(on ? 'turnOn' : 'turnOff');
    } catch (e) {
      // Flashlight might not be available
    }
  }

  // ═══════════════════════════════════════════════════════════
  // STATUS REPORTING
  // ═══════════════════════════════════════════════════════════

  void _emitStatus() {
    onStatusUpdate?.call(EmergencyStatus(
      isActive: _isActive,
      activatedAt: _activatedAt,
      photosCaptured: _photosCaptured,
      photosUploaded: _photosUploaded,
      locationUpdates: _locationUpdates,
      flashlightActive: _flashlightSOS && _isActive,
      maxBrightnessActive: _maxBrightness && _isActive,
      uptime: uptime,
    ));
  }

  /// Get current emergency status
  EmergencyStatus getStatus() {
    return EmergencyStatus(
      isActive: _isActive,
      activatedAt: _activatedAt,
      photosCaptured: _photosCaptured,
      photosUploaded: _photosUploaded,
      locationUpdates: _locationUpdates,
      flashlightActive: _flashlightSOS && _isActive,
      maxBrightnessActive: _maxBrightness && _isActive,
      uptime: uptime,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════

enum EvidenceType {
  photo,
  video,
  audio,
  location,
  sensorData,
}

class EvidenceItem {
  final EvidenceType type;
  final String? filePath;
  final DateTime timestamp;
  final int alertId;
  bool uploaded;

  EvidenceItem({
    required this.type,
    this.filePath,
    required this.timestamp,
    required this.alertId,
    this.uploaded = false,
  });
}

class EmergencyStatus {
  final bool isActive;
  final DateTime? activatedAt;
  final int photosCaptured;
  final int photosUploaded;
  final int locationUpdates;
  final bool flashlightActive;
  final bool maxBrightnessActive;
  final Duration uptime;

  EmergencyStatus({
    required this.isActive,
    this.activatedAt,
    required this.photosCaptured,
    required this.photosUploaded,
    required this.locationUpdates,
    required this.flashlightActive,
    required this.maxBrightnessActive,
    required this.uptime,
  });
}
