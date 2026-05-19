import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';

/// Handles front camera photo capture for intruder evidence.
/// 
/// IMPORTANT ANDROID LIMITATIONS:
/// - Background camera access is restricted on Android 10+.
/// - Photo capture must happen through a visible activity/flow.
/// - Vigil uses the safety check screen as the trigger for photo capture
///   (screen is already visible and woken up).
/// - The photo is captured silently while the "Are you safe?" screen is shown.
class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  static const MethodChannel _channel = MethodChannel('com.vigil.app/camera');

  bool _isCapturing = false;
  String? _lastPhotoPath;

  bool get isCapturing => _isCapturing;
  String? get lastPhotoPath => _lastPhotoPath;

  /// Capture front camera photo (called when safety screen is shown).
  /// This is done through a visible emergency flow to comply with Android restrictions.
  Future<String?> captureIntruderPhoto() async {
    if (_isCapturing) return null;
    _isCapturing = true;

    try {
      debugPrint('[Vigil Camera] Capturing intruder photo...');

      // Use platform channel to capture via native camera API
      final String? photoPath = await _channel.invokeMethod('capturePhoto', {
        'camera': 'front',
        'quality': 80,
        'flash': false, // No flash to avoid alerting intruder
        'silent': true, // No shutter sound
        'saveToGallery': false, // Private capture
      });

      if (photoPath != null && photoPath.isNotEmpty) {
        _lastPhotoPath = photoPath;
        debugPrint('[Vigil Camera] Photo captured: $photoPath');
        return photoPath;
      } else {
        debugPrint('[Vigil Camera] Photo capture returned null');
        return null;
      }
    } catch (e) {
      debugPrint('[Vigil Camera] Capture failed: $e');
      return null;
    } finally {
      _isCapturing = false;
    }
  }

  /// Upload captured photo to backend for the alert record
  Future<bool> uploadIntruderPhoto({
    required int alertId,
    required String photoPath,
  }) async {
    try {
      final file = File(photoPath);
      if (!await file.exists()) {
        debugPrint('[Vigil Camera] Photo file not found: $photoPath');
        return false;
      }

      final success = await ApiService().uploadAlertPhoto(
        alertId: alertId,
        photoFile: file,
      );

      if (success) {
        debugPrint('[Vigil Camera] Photo uploaded for alert $alertId');
        // Delete local copy after successful upload
        await file.delete();
      }

      return success;
    } catch (e) {
      debugPrint('[Vigil Camera] Upload failed: $e');
      return false;
    }
  }

  /// Capture and upload in one step (convenience method during alert)
  Future<bool> captureAndUpload(int alertId) async {
    final photoPath = await captureIntruderPhoto();
    if (photoPath == null) return false;
    return uploadIntruderPhoto(alertId: alertId, photoPath: photoPath);
  }

  /// Request camera permission
  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod('requestCameraPermission');
      return result == true;
    } catch (e) {
      debugPrint('[Vigil Camera] Permission request failed: $e');
      return false;
    }
  }

  /// Check if camera permission is granted
  Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod('hasCameraPermission');
      return result == true;
    } catch (e) {
      return false;
    }
  }
}
