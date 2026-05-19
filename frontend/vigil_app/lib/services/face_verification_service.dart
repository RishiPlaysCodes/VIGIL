import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Face Verification Service for Vigil.
///
/// When the AI fusion engine detects a suspicious extraction:
/// 1. Screen wakes automatically
/// 2. Front camera activates for face detection
/// 3. If the AUTHORIZED user's face is detected → auto-cancel alert silently
/// 4. If face is NOT detected or NOT recognized → proceed to multi-layer auth
///
/// This service handles:
/// - Face enrollment (storing owner's face embedding during setup)
/// - Real-time face detection from camera preview
/// - Face matching against stored embedding
/// - Confidence scoring for face match
/// - Liveness detection (anti-spoofing with photo/video)
///
/// Implementation uses Google ML Kit Face Detection on-device.
/// No cloud processing — all face data stays on device (encrypted).
class FaceVerificationService {
  static final FaceVerificationService _instance = FaceVerificationService._internal();
  factory FaceVerificationService() => _instance;
  FaceVerificationService._internal();

  static const MethodChannel _channel = MethodChannel('com.vigil.app/face_verification');

  // State
  bool _isInitialized = false;
  bool _isEnrolled = false;
  bool _isVerifying = false;
  FaceVerificationResult? _lastResult;

  // Configuration
  double _matchThreshold = 0.75; // 75% similarity required
  int _maxVerificationTimeMs = 3000; // 3 seconds max to detect face
  bool _livenessCheckEnabled = true;

  // Callbacks
  Function(FaceVerificationResult)? onVerificationComplete;
  Function(FaceDetectionEvent)? onFaceDetected;
  VoidCallback? onOwnerRecognized;
  VoidCallback? onUnknownFace;
  VoidCallback? onNoFaceDetected;
  VoidCallback? onTimeout;

  // Getters
  bool get isEnrolled => _isEnrolled;
  bool get isVerifying => _isVerifying;
  FaceVerificationResult? get lastResult => _lastResult;

  /// Initialize the face verification system
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final result = await _channel.invokeMethod('initializeFaceDetection');
      _isInitialized = result == true;

      // Check if face is already enrolled
      _isEnrolled = await _checkEnrollmentStatus();

      // Listen for face detection events from native
      _channel.setMethodCallHandler(_handleNativeCallback);

      debugPrint('[Vigil Face] Initialized (enrolled: $_isEnrolled)');
      return _isInitialized;
    } catch (e) {
      debugPrint('[Vigil Face] Init failed: $e');
      return false;
    }
  }

  /// Enroll the owner's face (called during initial setup)
  /// Captures multiple angles for robust recognition.
  Future<FaceEnrollmentResult> enrollFace() async {
    try {
      debugPrint('[Vigil Face] Starting face enrollment...');

      final result = await _channel.invokeMethod('enrollFace', {
        'captureCount': 5, // Take 5 photos from different angles
        'quality': 'high',
        'livenessCheck': true, // Ensure it's a real face, not a photo
      });

      if (result != null && result['success'] == true) {
        _isEnrolled = true;
        debugPrint('[Vigil Face] Enrollment successful');
        return FaceEnrollmentResult(
          success: true,
          message: 'Face enrolled successfully',
          capturedFrames: result['capturedFrames'] ?? 5,
        );
      } else {
        return FaceEnrollmentResult(
          success: false,
          message: result?['error'] ?? 'Enrollment failed',
          capturedFrames: 0,
        );
      }
    } catch (e) {
      debugPrint('[Vigil Face] Enrollment error: $e');
      return FaceEnrollmentResult(
        success: false,
        message: 'Error: $e',
        capturedFrames: 0,
      );
    }
  }

  /// Start face verification (called when extraction detected).
  /// Opens front camera, attempts to detect and match face.
  /// Auto-cancels alert if owner's face is recognized.
  Future<FaceVerificationResult> startVerification() async {
    if (!_isEnrolled) {
      debugPrint('[Vigil Face] Not enrolled — skipping verification');
      return FaceVerificationResult(
        status: FaceVerificationStatus.notEnrolled,
        confidence: 0.0,
        isOwner: false,
        message: 'Face not enrolled',
      );
    }

    if (_isVerifying) {
      return FaceVerificationResult(
        status: FaceVerificationStatus.alreadyVerifying,
        confidence: 0.0,
        isOwner: false,
        message: 'Already verifying',
      );
    }

    _isVerifying = true;
    debugPrint('[Vigil Face] Starting verification (timeout: ${_maxVerificationTimeMs}ms)');

    try {
      // Call native face verification with timeout
      final result = await _channel.invokeMethod('verifyFace', {
        'timeoutMs': _maxVerificationTimeMs,
        'matchThreshold': _matchThreshold,
        'livenessCheck': _livenessCheckEnabled,
        'captureIntruderPhoto': true, // Save photo regardless for evidence
      }).timeout(
        Duration(milliseconds: _maxVerificationTimeMs + 1000),
        onTimeout: () => {'status': 'timeout'},
      );

      final verificationResult = _parseVerificationResult(result);
      _lastResult = verificationResult;
      _isVerifying = false;

      // Trigger appropriate callback
      switch (verificationResult.status) {
        case FaceVerificationStatus.ownerRecognized:
          onOwnerRecognized?.call();
          debugPrint('[Vigil Face] OWNER RECOGNIZED (confidence: '
              '${verificationResult.confidence.toStringAsFixed(2)})');
          break;
        case FaceVerificationStatus.unknownFace:
          onUnknownFace?.call();
          debugPrint('[Vigil Face] UNKNOWN FACE detected');
          break;
        case FaceVerificationStatus.noFaceDetected:
          onNoFaceDetected?.call();
          debugPrint('[Vigil Face] No face detected in frame');
          break;
        case FaceVerificationStatus.timeout:
          onTimeout?.call();
          debugPrint('[Vigil Face] Verification timed out');
          break;
        default:
          break;
      }

      onVerificationComplete?.call(verificationResult);
      return verificationResult;
    } catch (e) {
      _isVerifying = false;
      debugPrint('[Vigil Face] Verification error: $e');
      return FaceVerificationResult(
        status: FaceVerificationStatus.error,
        confidence: 0.0,
        isOwner: false,
        message: 'Error: $e',
      );
    }
  }

  /// Stop ongoing verification (e.g., user authenticated via other method)
  void stopVerification() {
    if (!_isVerifying) return;
    _isVerifying = false;
    try {
      _channel.invokeMethod('stopVerification');
    } catch (e) {
      debugPrint('[Vigil Face] Stop verification error: $e');
    }
  }

  /// Delete enrolled face data
  Future<bool> deleteEnrollment() async {
    try {
      await _channel.invokeMethod('deleteEnrollment');
      _isEnrolled = false;
      return true;
    } catch (e) {
      debugPrint('[Vigil Face] Delete enrollment error: $e');
      return false;
    }
  }

  /// Update match threshold (0.0 - 1.0)
  void setMatchThreshold(double threshold) {
    _matchThreshold = threshold.clamp(0.5, 0.99);
  }

  /// Update verification timeout
  void setVerificationTimeout(int milliseconds) {
    _maxVerificationTimeMs = milliseconds.clamp(1000, 10000);
  }

  /// Enable/disable liveness check (anti-spoofing)
  void setLivenessCheck(bool enabled) {
    _livenessCheckEnabled = enabled;
  }

  // ═══════════════════════════════════════════════════════════
  // PRIVATE METHODS
  // ═══════════════════════════════════════════════════════════

  Future<bool> _checkEnrollmentStatus() async {
    try {
      final result = await _channel.invokeMethod('isEnrolled');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  FaceVerificationResult _parseVerificationResult(dynamic result) {
    if (result == null) {
      return FaceVerificationResult(
        status: FaceVerificationStatus.error,
        confidence: 0.0,
        isOwner: false,
        message: 'Null result from native',
      );
    }

    final map = Map<String, dynamic>.from(result);
    final status = map['status'] as String? ?? 'error';
    final confidence = (map['confidence'] as num?)?.toDouble() ?? 0.0;
    final intruderPhotoPath = map['intruderPhotoPath'] as String?;

    switch (status) {
      case 'owner_recognized':
        return FaceVerificationResult(
          status: FaceVerificationStatus.ownerRecognized,
          confidence: confidence,
          isOwner: true,
          message: 'Owner face recognized',
          intruderPhotoPath: intruderPhotoPath,
        );
      case 'unknown_face':
        return FaceVerificationResult(
          status: FaceVerificationStatus.unknownFace,
          confidence: confidence,
          isOwner: false,
          message: 'Unknown face detected',
          intruderPhotoPath: intruderPhotoPath,
        );
      case 'no_face':
        return FaceVerificationResult(
          status: FaceVerificationStatus.noFaceDetected,
          confidence: 0.0,
          isOwner: false,
          message: 'No face in frame',
          intruderPhotoPath: intruderPhotoPath,
        );
      case 'timeout':
        return FaceVerificationResult(
          status: FaceVerificationStatus.timeout,
          confidence: 0.0,
          isOwner: false,
          message: 'Verification timed out',
          intruderPhotoPath: intruderPhotoPath,
        );
      case 'liveness_failed':
        return FaceVerificationResult(
          status: FaceVerificationStatus.livenessFailed,
          confidence: confidence,
          isOwner: false,
          message: 'Liveness check failed (possible photo/video spoof)',
          intruderPhotoPath: intruderPhotoPath,
        );
      default:
        return FaceVerificationResult(
          status: FaceVerificationStatus.error,
          confidence: 0.0,
          isOwner: false,
          message: 'Unknown status: $status',
        );
    }
  }

  /// Handle callbacks from native face detection
  Future<dynamic> _handleNativeCallback(MethodCall call) async {
    switch (call.method) {
      case 'onFaceDetected':
        final args = Map<String, dynamic>.from(call.arguments ?? {});
        onFaceDetected?.call(FaceDetectionEvent(
          faceCount: args['faceCount'] ?? 0,
          confidence: (args['confidence'] as num?)?.toDouble() ?? 0.0,
          isSmiling: args['isSmiling'] ?? false,
          eyesOpen: args['eyesOpen'] ?? false,
        ));
        break;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════

enum FaceVerificationStatus {
  ownerRecognized,
  unknownFace,
  noFaceDetected,
  timeout,
  livenessFailed,
  notEnrolled,
  alreadyVerifying,
  error,
}

class FaceVerificationResult {
  final FaceVerificationStatus status;
  final double confidence;
  final bool isOwner;
  final String message;
  final String? intruderPhotoPath;

  FaceVerificationResult({
    required this.status,
    required this.confidence,
    required this.isOwner,
    required this.message,
    this.intruderPhotoPath,
  });

  bool get shouldAutoCancel => status == FaceVerificationStatus.ownerRecognized;
  bool get shouldProceedToAuth =>
      status == FaceVerificationStatus.unknownFace ||
      status == FaceVerificationStatus.noFaceDetected ||
      status == FaceVerificationStatus.timeout ||
      status == FaceVerificationStatus.livenessFailed;
}

class FaceEnrollmentResult {
  final bool success;
  final String message;
  final int capturedFrames;

  FaceEnrollmentResult({
    required this.success,
    required this.message,
    required this.capturedFrames,
  });
}

class FaceDetectionEvent {
  final int faceCount;
  final double confidence;
  final bool isSmiling;
  final bool eyesOpen;

  FaceDetectionEvent({
    required this.faceCount,
    required this.confidence,
    required this.isSmiling,
    required this.eyesOpen,
  });
}
