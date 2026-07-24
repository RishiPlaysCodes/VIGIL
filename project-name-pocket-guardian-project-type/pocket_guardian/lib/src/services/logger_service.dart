import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Centralized logging service with level-based filtering.
/// In production, only warnings and errors are logged.
/// In development, all levels are logged.
enum LogLevel { debug, info, warning, error }

class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  void debug(String message, {String? tag, Object? error}) {
    _log(LogLevel.debug, message, tag: tag, error: error);
  }

  void info(String message, {String? tag, Object? error}) {
    _log(LogLevel.info, message, tag: tag, error: error);
  }

  void warning(String message, {String? tag, Object? error}) {
    _log(LogLevel.warning, message, tag: tag, error: error);
  }

  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // In production, skip debug and info logs
    if (AppConfig.isProduction && (level == LogLevel.debug || level == LogLevel.info)) {
      return;
    }

    final prefix = switch (level) {
      LogLevel.debug => '[DEBUG]',
      LogLevel.info => '[INFO]',
      LogLevel.warning => '[WARN]',
      LogLevel.error => '[ERROR]',
    };

    final tagStr = tag != null ? '[$tag]' : '';
    final logMessage = '$prefix$tagStr $message';

    if (kDebugMode) {
      developer.log(
        logMessage,
        error: error,
        stackTrace: stackTrace,
        name: 'PocketGuardian',
      );
    }

    // In production, you would send errors to a crash reporting service
    // like Sentry, Firebase Crashlytics, etc.
    if (level == LogLevel.error && AppConfig.isProduction) {
      // TODO: Send to crash reporting service
      // CrashReportingService.report(message, error, stackTrace);
    }
  }
}
