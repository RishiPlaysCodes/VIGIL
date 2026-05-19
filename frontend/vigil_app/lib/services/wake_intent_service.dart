import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/navigation_service.dart';

/// WakeIntentService — bridges native wake intents to Flutter navigation.
///
/// Flow:
/// 1. AI Fusion Engine detects extraction (in Dart)
/// 2. AlertCoordinatorV2 calls AlarmService.launchWakeActivity('lock-screen')
/// 3. Native MainActivity launches with EXTRA_LAUNCH_ROUTE='lock-screen'
/// 4. Native applies showWhenLocked + turnScreenOn flags
/// 5. Native sends 'onWakeIntent' on this channel
/// 6. WakeIntentService routes via NavigationService to /lock-screen-safety
///
/// Also handles cold start (app launched from wake intent) — when Flutter is
/// ready it calls 'ready' to flush any pending route from native.
class WakeIntentService {
  static final WakeIntentService _instance = WakeIntentService._internal();
  factory WakeIntentService() => _instance;
  WakeIntentService._internal();

  static const MethodChannel _channel = MethodChannel('com.vigil.app/wake_intent');

  bool _initialized = false;

  /// Initialize listener — call once after Flutter engine is ready.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler(_handleNativeCall);

    // Tell native we're ready — flushes any buffered launch route
    try {
      await _channel.invokeMethod('ready');
    } catch (e) {
      debugPrint('[Vigil WakeIntent] ready() failed: $e');
    }

    debugPrint('[Vigil WakeIntent] Initialized');
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onWakeIntent') {
      final args = Map<String, dynamic>.from(call.arguments ?? {});
      final route = args['route'] as String?;
      if (route != null) {
        _navigateToRoute(route);
      }
    }
  }

  /// Map native route names → Flutter routes
  void _navigateToRoute(String route) {
    debugPrint('[Vigil WakeIntent] Wake intent received: $route');

    String flutterRoute;
    switch (route) {
      case 'lock-screen':
      case 'safety':
        flutterRoute = '/lock-screen-safety';
        break;
      case 'emergency':
        flutterRoute = '/emergency-active';
        break;
      default:
        flutterRoute = '/lock-screen-safety';
    }

    // Push if not already on the route
    final navigator = NavigationService.navigator;
    if (navigator == null) {
      debugPrint('[Vigil WakeIntent] Navigator not ready — buffering route');
      // Retry after a frame
      Future.delayed(const Duration(milliseconds: 200), () {
        _navigateToRoute(route);
      });
      return;
    }

    navigator.pushNamedAndRemoveUntil(flutterRoute, (r) => r.isFirst);
  }

  /// Trigger a wake intent manually from Dart (used by AlertCoordinatorV2
  /// when extraction is detected and we want native to wake the screen).
  Future<void> launchSafetyCheck() async {
    try {
      await _channel.invokeMethod('launchSafetyCheck');
    } catch (e) {
      debugPrint('[Vigil WakeIntent] launchSafetyCheck failed: $e');
    }
  }
}
