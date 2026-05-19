import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Handles local notifications including:
/// - "Using phone - pause 5 min" action notification during pocket mode
/// - Alert notifications
/// - Background service notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const MethodChannel _channel =
      MethodChannel('com.vigil.app/notifications');

  // Notification IDs
  static const int pocketModeNotificationId = 1001;
  static const int alertNotificationId = 1002;
  static const int locationTrackingNotificationId = 1003;

  // Action identifiers
  static const String actionPause5Min = 'ACTION_PAUSE_5_MIN';
  static const String actionStopPocketMode = 'ACTION_STOP_POCKET_MODE';
  static const String actionImSafe = 'ACTION_IM_SAFE';

  // Callbacks
  VoidCallback? onPause5MinTapped;
  VoidCallback? onStopPocketModeTapped;
  VoidCallback? onImSafeTapped;

  /// Initialize notification channels and permissions
  Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
      _channel.setMethodCallHandler(_handleMethod);
      debugPrint('[Vigil Notifications] Initialized');
    } catch (e) {
      debugPrint('[Vigil Notifications] Init failed: $e');
    }
  }

  /// Handle notification action callbacks from native
  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onNotificationAction':
        final action = call.arguments as String;
        _handleAction(action);
        break;
    }
  }

  void _handleAction(String action) {
    switch (action) {
      case actionPause5Min:
        debugPrint('[Vigil] User tapped: Pause 5 min');
        onPause5MinTapped?.call();
        break;
      case actionStopPocketMode:
        debugPrint('[Vigil] User tapped: Stop pocket mode');
        onStopPocketModeTapped?.call();
        break;
      case actionImSafe:
        debugPrint('[Vigil] User tapped: I am safe');
        onImSafeTapped?.call();
        break;
    }
  }

  /// Show persistent notification during pocket mode with action buttons
  Future<void> showPocketModeNotification() async {
    try {
      await _channel.invokeMethod('showNotification', {
        'id': pocketModeNotificationId,
        'title': 'Vigil - Pocket Mode Active',
        'body': 'Your phone is being protected',
        'ongoing': true,
        'actions': [
          {'id': actionPause5Min, 'title': 'Using phone - pause 5 min'},
          {'id': actionStopPocketMode, 'title': 'Stop Protection'},
        ],
        'channelId': 'vigil_pocket_mode',
        'channelName': 'Pocket Mode',
        'importance': 'low', // Silent persistent notification
      });
    } catch (e) {
      debugPrint('[Vigil] Show pocket mode notification failed: $e');
    }
  }

  /// Show alert notification (high priority)
  Future<void> showAlertNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _channel.invokeMethod('showNotification', {
        'id': alertNotificationId,
        'title': title,
        'body': body,
        'ongoing': false,
        'actions': [
          {'id': actionImSafe, 'title': 'I Am Safe'},
        ],
        'channelId': 'vigil_alerts',
        'channelName': 'Safety Alerts',
        'importance': 'high',
        'sound': 'alarm_sound',
        'vibrate': true,
      });
    } catch (e) {
      debugPrint('[Vigil] Show alert notification failed: $e');
    }
  }

  /// Show background location tracking notification
  Future<void> showLocationTrackingNotification() async {
    try {
      await _channel.invokeMethod('showNotification', {
        'id': locationTrackingNotificationId,
        'title': 'Vigil - Location Active',
        'body': 'Sharing your location with trusted contacts',
        'ongoing': true,
        'channelId': 'vigil_location',
        'channelName': 'Location Tracking',
        'importance': 'low',
      });
    } catch (e) {
      debugPrint('[Vigil] Show location notification failed: $e');
    }
  }

  /// Cancel a notification
  Future<void> cancelNotification(int id) async {
    try {
      await _channel.invokeMethod('cancelNotification', {'id': id});
    } catch (e) {
      debugPrint('[Vigil] Cancel notification failed: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    try {
      await _channel.invokeMethod('cancelAllNotifications');
    } catch (e) {
      debugPrint('[Vigil] Cancel all notifications failed: $e');
    }
  }

  /// Request notification permission (Android 13+)
  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod('requestPermission');
      return result == true;
    } catch (e) {
      debugPrint('[Vigil] Request notification permission failed: $e');
      return false;
    }
  }
}
