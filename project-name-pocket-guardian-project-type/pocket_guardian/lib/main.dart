import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'src/app.dart';
import 'src/config/app_config.dart';
import 'src/services/logger_service.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized before any async operations.
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handling.
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.instance.error(
      'Flutter framework error: ${details.exceptionAsString()}',
      tag: 'Flutter',
      error: details.exception,
      stackTrace: details.stack,
    );
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  // Handle errors that occur outside of the Flutter framework.
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.instance.error(
      'Unhandled platform error',
      tag: 'Platform',
      error: error,
      stackTrace: stack,
    );
    return true; // Prevent the error from propagating.
  };

  // Initialize services
  await AndroidAlarmManager.initialize();

  AppLogger.instance.info(
    'App starting (env: ${AppConfig.isProduction ? "production" : "development"})',
    tag: 'App',
  );

  runApp(const PocketGuardianApp());
}
