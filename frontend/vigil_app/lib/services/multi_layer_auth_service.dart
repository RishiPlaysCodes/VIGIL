import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'face_verification_service.dart';

/// Multi-Layer Authentication Service for Vigil.
///
/// Replaces the insecure single "I Am Safe" button with a proper
/// authentication stack. An intruder cannot cancel the alarm by simply
/// tapping a button — they need to pass AT LEAST ONE verified auth method.
///
/// Authentication layers (in priority order):
/// 1. Face Verification (automatic, fastest) → auto-cancels if owner recognized
/// 2. Fingerprint/Biometric (user taps sensor) → cancels on match
/// 3. Voice Password (custom phrase + voiceprint matching)
/// 4. PIN/Pattern backup (last resort, always available)
///
/// The user configures which methods are active. At least ONE must pass.
/// For maximum security, user can require 2-of-4 methods (configurable).
///
/// Voice Password feature:
/// - User records a secret phrase (e.g., "VIGIL CHUP" or any custom phrase)
/// - System stores both the PHRASE TEXT and the VOICEPRINT (speaker embedding)
/// - Verification requires: correct phrase + matching voice = owner confirmed
/// - An intruder saying the same phrase won't match the voiceprint
class MultiLayerAuthService {
  static final MultiLayerAuthService _instance = MultiLayerAuthService._internal();
  factory MultiLayerAuthService() => _instance;
  MultiLayerAuthService._internal();

  static const MethodChannel _biometricChannel = MethodChannel('com.vigil.app/biometrics');
  static const MethodChannel _voiceChannel = MethodChannel('com.vigil.app/voice_auth');

  // Sub-services
  final FaceVerificationService _faceService = FaceVerificationService();

  // Configuration
  AuthConfiguration _config = AuthConfiguration();
  bool _isInitialized = false;

  // State
  AuthenticationState _state = AuthenticationState.idle;
  final List<AuthMethod> _completedMethods = [];
  Timer? _authTimeout;

  // Callbacks
  Function(AuthenticationResult)? onAuthComplete;
  Function(AuthenticationState)? onStateChange;
  Function(AuthMethod, bool)? onMethodAttempt;
  VoidCallback? onAuthTimeout;

  // Getters
  AuthenticationState get state => _state;
  AuthConfiguration get config => _config;
  bool get isAnyMethodEnrolled =>
      _config.faceEnabled || _config.fingerprintEnabled ||
      _config.voicePasswordEnabled || _config.pinEnabled;

  /// Initialize the authentication service
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _faceService.initialize();

    // Check biometric availability
    try {
      final bioAvailable = await _biometricChannel.invokeMethod('checkBiometricAvailability');
      _config = _config.copyWith(
        fingerprintAvailable: bioAvailable?['fingerprint'] == true,
        faceIdAvailable: bioAvailable?['faceId'] == true,
      );
    } catch (e) {
      debugPrint('[Vigil Auth] Biometric check failed: $e');
    }

    debugPrint('[Vigil Auth] Initialized (config: $_config)');
  }

  /// Start the full authentication flow (called when extraction detected)
  /// Returns true if owner is verified, false if authentication fails.
  Future<AuthenticationResult> startAuthentication({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    _setState(AuthenticationState.verifying);
    _completedMethods.clear();

    // Start timeout timer
    _authTimeout?.cancel();
    _authTimeout = Timer(timeout, () {
      if (_state == AuthenticationState.verifying) {
        _setState(AuthenticationState.failed);
        onAuthTimeout?.call();
        onAuthComplete?.call(AuthenticationResult(
          success: false,
          method: AuthMethod.none,
          message: 'Authentication timed out',
        ));
      }
    });

    // === LAYER 1: Face Verification (automatic, silent) ===
    if (_config.faceEnabled && _faceService.isEnrolled) {
      debugPrint('[Vigil Auth] Layer 1: Face verification...');
      _setState(AuthenticationState.faceVerification);

      final faceResult = await _faceService.startVerification();
      onMethodAttempt?.call(AuthMethod.face, faceResult.isOwner);

      if (faceResult.shouldAutoCancel) {
        return _authSuccess(AuthMethod.face, faceResult.confidence);
      }
      // Face failed — continue to next layer
      debugPrint('[Vigil Auth] Face verification failed: ${faceResult.message}');
    }

    // === LAYER 2: Fingerprint (wait for user to touch sensor) ===
    if (_config.fingerprintEnabled && _config.fingerprintAvailable) {
      debugPrint('[Vigil Auth] Layer 2: Waiting for fingerprint...');
      _setState(AuthenticationState.fingerprintWaiting);

      // Don't block here — fingerprint runs in parallel with other options
      _startFingerprintListener();
    }

    // At this point, we wait for user interaction:
    // - They can use fingerprint (already listening)
    // - They can use voice password
    // - They can use PIN
    // The UI will show all available options

    _setState(AuthenticationState.waitingForUser);

    // Return a "pending" result — actual auth will come from user action
    return AuthenticationResult(
      success: false,
      method: AuthMethod.none,
      message: 'Waiting for user authentication',
      isPending: true,
    );
  }

  /// Verify fingerprint (called when biometric prompt returns)
  Future<AuthenticationResult> verifyFingerprint() async {
    try {
      _setState(AuthenticationState.fingerprintVerifying);
      final result = await _biometricChannel.invokeMethod('authenticateFingerprint', {
        'title': 'Vigil Safety Verification',
        'subtitle': 'Verify your identity to cancel the alert',
        'negativeButtonText': 'Use other method',
      });

      final success = result == true;
      onMethodAttempt?.call(AuthMethod.fingerprint, success);

      if (success) {
        return _authSuccess(AuthMethod.fingerprint, 1.0);
      } else {
        debugPrint('[Vigil Auth] Fingerprint failed');
        _setState(AuthenticationState.waitingForUser);
        return AuthenticationResult(
          success: false,
          method: AuthMethod.fingerprint,
          message: 'Fingerprint not recognized',
        );
      }
    } catch (e) {
      debugPrint('[Vigil Auth] Fingerprint error: $e');
      _setState(AuthenticationState.waitingForUser);
      return AuthenticationResult(
        success: false,
        method: AuthMethod.fingerprint,
        message: 'Fingerprint error: $e',
      );
    }
  }

  /// Verify voice password
  /// User speaks their secret phrase; system checks both phrase content and voiceprint.
  Future<AuthenticationResult> verifyVoicePassword() async {
    if (!_config.voicePasswordEnabled) {
      return AuthenticationResult(
        success: false,
        method: AuthMethod.voicePassword,
        message: 'Voice password not configured',
      );
    }

    try {
      _setState(AuthenticationState.voiceListening);
      debugPrint('[Vigil Auth] Layer 3: Voice password verification...');

      // Start recording and analyze
      final result = await _voiceChannel.invokeMethod('verifyVoicePassword', {
        'maxListenDurationMs': 5000,
        'minConfidence': 0.7,
      });

      if (result == null) {
        _setState(AuthenticationState.waitingForUser);
        return AuthenticationResult(
          success: false,
          method: AuthMethod.voicePassword,
          message: 'No voice detected',
        );
      }

      final map = Map<String, dynamic>.from(result);
      final phraseMatch = map['phraseMatch'] == true;
      final voiceprintMatch = map['voiceprintMatch'] == true;
      final confidence = (map['confidence'] as num?)?.toDouble() ?? 0.0;

      // BOTH phrase AND voiceprint must match
      final success = phraseMatch && voiceprintMatch;
      onMethodAttempt?.call(AuthMethod.voicePassword, success);

      if (success) {
        return _authSuccess(AuthMethod.voicePassword, confidence);
      } else {
        String failReason = '';
        if (!phraseMatch) failReason += 'Wrong phrase. ';
        if (!voiceprintMatch) failReason += 'Voice not recognized. ';

        debugPrint('[Vigil Auth] Voice password failed: $failReason');
        _setState(AuthenticationState.waitingForUser);
        return AuthenticationResult(
          success: false,
          method: AuthMethod.voicePassword,
          message: failReason.trim(),
        );
      }
    } catch (e) {
      debugPrint('[Vigil Auth] Voice error: $e');
      _setState(AuthenticationState.waitingForUser);
      return AuthenticationResult(
        success: false,
        method: AuthMethod.voicePassword,
        message: 'Voice verification error',
      );
    }
  }

  /// Verify PIN code (backup method, always available)
  AuthenticationResult verifyPin(String enteredPin) {
    if (!_config.pinEnabled || _config.pinHash == null) {
      return AuthenticationResult(
        success: false,
        method: AuthMethod.pin,
        message: 'PIN not configured',
      );
    }

    // Simple hash comparison (in production, use proper PBKDF2/bcrypt)
    final enteredHash = _simpleHash(enteredPin);
    final success = enteredHash == _config.pinHash;
    onMethodAttempt?.call(AuthMethod.pin, success);

    if (success) {
      return _authSuccess(AuthMethod.pin, 1.0);
    } else {
      return AuthenticationResult(
        success: false,
        method: AuthMethod.pin,
        message: 'Incorrect PIN',
      );
    }
  }

  /// Verify pattern (alternative to PIN)
  AuthenticationResult verifyPattern(String enteredPattern) {
    if (_config.patternHash == null) {
      return AuthenticationResult(
        success: false,
        method: AuthMethod.pattern,
        message: 'Pattern not configured',
      );
    }

    final enteredHash = _simpleHash(enteredPattern);
    final success = enteredHash == _config.patternHash;
    onMethodAttempt?.call(AuthMethod.pattern, success);

    if (success) {
      return _authSuccess(AuthMethod.pattern, 1.0);
    } else {
      return AuthenticationResult(
        success: false,
        method: AuthMethod.pattern,
        message: 'Incorrect pattern',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ENROLLMENT METHODS (called during setup)
  // ═══════════════════════════════════════════════════════════

  /// Enroll face for verification
  Future<FaceEnrollmentResult> enrollFace() async {
    final result = await _faceService.enrollFace();
    if (result.success) {
      _config = _config.copyWith(faceEnabled: true);
    }
    return result;
  }

  /// Enroll voice password
  /// User speaks their secret phrase multiple times for voiceprint training.
  Future<VoiceEnrollmentResult> enrollVoicePassword(String secretPhrase) async {
    try {
      debugPrint('[Vigil Auth] Enrolling voice password...');

      final result = await _voiceChannel.invokeMethod('enrollVoicePassword', {
        'phrase': secretPhrase,
        'recordingsRequired': 3, // Record 3 times for robust voiceprint
      });

      if (result != null && result['success'] == true) {
        _config = _config.copyWith(
          voicePasswordEnabled: true,
          voicePhrase: secretPhrase,
        );
        return VoiceEnrollmentResult(
          success: true,
          message: 'Voice password enrolled successfully',
          recordingsCompleted: result['recordingsCompleted'] ?? 3,
        );
      }

      return VoiceEnrollmentResult(
        success: false,
        message: result?['error'] ?? 'Enrollment failed',
        recordingsCompleted: 0,
      );
    } catch (e) {
      return VoiceEnrollmentResult(
        success: false,
        message: 'Error: $e',
        recordingsCompleted: 0,
      );
    }
  }

  /// Set PIN code
  void setPin(String pin) {
    _config = _config.copyWith(
      pinEnabled: true,
      pinHash: _simpleHash(pin),
    );
  }

  /// Set pattern
  void setPattern(String pattern) {
    _config = _config.copyWith(
      patternHash: _simpleHash(pattern),
    );
  }

  /// Enable/disable fingerprint
  void setFingerprintEnabled(bool enabled) {
    _config = _config.copyWith(fingerprintEnabled: enabled);
  }

  /// Update required auth count (1 = any single method, 2 = two methods required)
  void setRequiredMethodCount(int count) {
    _config = _config.copyWith(requiredMethodCount: count.clamp(1, 3));
  }

  // ═══════════════════════════════════════════════════════════
  // INTERNAL METHODS
  // ═══════════════════════════════════════════════════════════

  AuthenticationResult _authSuccess(AuthMethod method, double confidence) {
    _completedMethods.add(method);
    _authTimeout?.cancel();

    // Check if enough methods are completed
    if (_completedMethods.length >= _config.requiredMethodCount) {
      _setState(AuthenticationState.verified);
      final result = AuthenticationResult(
        success: true,
        method: method,
        confidence: confidence,
        message: 'Owner verified via ${method.displayName}',
      );
      onAuthComplete?.call(result);
      debugPrint('[Vigil Auth] SUCCESS via ${method.displayName} '
          '(confidence: ${confidence.toStringAsFixed(2)})');
      return result;
    } else {
      // Need more methods
      final remaining = _config.requiredMethodCount - _completedMethods.length;
      _setState(AuthenticationState.waitingForUser);
      return AuthenticationResult(
        success: false,
        method: method,
        confidence: confidence,
        message: '$remaining more verification(s) needed',
        isPending: true,
      );
    }
  }

  void _setState(AuthenticationState newState) {
    if (_state == newState) return;
    _state = newState;
    onStateChange?.call(newState);
  }

  void _startFingerprintListener() {
    // Fingerprint runs asynchronously — result comes via callback
    verifyFingerprint().then((result) {
      if (result.success && _state != AuthenticationState.verified) {
        // Already handled in verifyFingerprint
      }
    });
  }

  /// Simple hash for PIN/pattern (in production, use PBKDF2 with salt)
  String _simpleHash(String input) {
    // Basic hash — replace with proper crypto in production
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash) + input.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  /// Cancel ongoing authentication
  void cancelAuthentication() {
    _authTimeout?.cancel();
    _faceService.stopVerification();
    _completedMethods.clear();
    _setState(AuthenticationState.idle);
  }

  /// Get available auth methods for UI display
  List<AuthMethodInfo> getAvailableMethods() {
    return [
      if (_config.faceEnabled)
        AuthMethodInfo(
          method: AuthMethod.face,
          label: 'Face Recognition',
          icon: 'face',
          isAutomatic: true,
        ),
      if (_config.fingerprintEnabled && _config.fingerprintAvailable)
        AuthMethodInfo(
          method: AuthMethod.fingerprint,
          label: 'Fingerprint',
          icon: 'fingerprint',
          isAutomatic: false,
        ),
      if (_config.voicePasswordEnabled)
        AuthMethodInfo(
          method: AuthMethod.voicePassword,
          label: 'Voice Password',
          icon: 'mic',
          isAutomatic: false,
        ),
      if (_config.pinEnabled)
        AuthMethodInfo(
          method: AuthMethod.pin,
          label: 'PIN Code',
          icon: 'pin',
          isAutomatic: false,
        ),
    ];
  }
}

// ═══════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════

enum AuthMethod {
  none,
  face,
  fingerprint,
  voicePassword,
  pin,
  pattern,
}

extension AuthMethodExtension on AuthMethod {
  String get displayName {
    switch (this) {
      case AuthMethod.none: return 'None';
      case AuthMethod.face: return 'Face Recognition';
      case AuthMethod.fingerprint: return 'Fingerprint';
      case AuthMethod.voicePassword: return 'Voice Password';
      case AuthMethod.pin: return 'PIN Code';
      case AuthMethod.pattern: return 'Pattern';
    }
  }
}

enum AuthenticationState {
  idle,
  verifying,
  faceVerification,
  fingerprintWaiting,
  fingerprintVerifying,
  voiceListening,
  waitingForUser,
  verified,
  failed,
}

class AuthenticationResult {
  final bool success;
  final AuthMethod method;
  final double confidence;
  final String message;
  final bool isPending;

  AuthenticationResult({
    required this.success,
    required this.method,
    this.confidence = 0.0,
    required this.message,
    this.isPending = false,
  });
}

class AuthConfiguration {
  final bool faceEnabled;
  final bool fingerprintEnabled;
  final bool fingerprintAvailable;
  final bool faceIdAvailable;
  final bool voicePasswordEnabled;
  final String? voicePhrase;
  final bool pinEnabled;
  final String? pinHash;
  final String? patternHash;
  final int requiredMethodCount; // How many methods must pass (1, 2, or 3)

  AuthConfiguration({
    this.faceEnabled = false,
    this.fingerprintEnabled = true,
    this.fingerprintAvailable = false,
    this.faceIdAvailable = false,
    this.voicePasswordEnabled = false,
    this.voicePhrase,
    this.pinEnabled = false,
    this.pinHash,
    this.patternHash,
    this.requiredMethodCount = 1,
  });

  AuthConfiguration copyWith({
    bool? faceEnabled,
    bool? fingerprintEnabled,
    bool? fingerprintAvailable,
    bool? faceIdAvailable,
    bool? voicePasswordEnabled,
    String? voicePhrase,
    bool? pinEnabled,
    String? pinHash,
    String? patternHash,
    int? requiredMethodCount,
  }) {
    return AuthConfiguration(
      faceEnabled: faceEnabled ?? this.faceEnabled,
      fingerprintEnabled: fingerprintEnabled ?? this.fingerprintEnabled,
      fingerprintAvailable: fingerprintAvailable ?? this.fingerprintAvailable,
      faceIdAvailable: faceIdAvailable ?? this.faceIdAvailable,
      voicePasswordEnabled: voicePasswordEnabled ?? this.voicePasswordEnabled,
      voicePhrase: voicePhrase ?? this.voicePhrase,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pinHash: pinHash ?? this.pinHash,
      patternHash: patternHash ?? this.patternHash,
      requiredMethodCount: requiredMethodCount ?? this.requiredMethodCount,
    );
  }

  @override
  String toString() => 'AuthConfig(face: $faceEnabled, fp: $fingerprintEnabled, '
      'voice: $voicePasswordEnabled, pin: $pinEnabled, required: $requiredMethodCount)';
}

class VoiceEnrollmentResult {
  final bool success;
  final String message;
  final int recordingsCompleted;

  VoiceEnrollmentResult({
    required this.success,
    required this.message,
    required this.recordingsCompleted,
  });
}

class AuthMethodInfo {
  final AuthMethod method;
  final String label;
  final String icon;
  final bool isAutomatic;

  AuthMethodInfo({
    required this.method,
    required this.label,
    required this.icon,
    required this.isAutomatic,
  });
}
