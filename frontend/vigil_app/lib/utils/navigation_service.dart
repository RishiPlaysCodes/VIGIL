import 'package:flutter/material.dart';

/// Global navigator key so services (running outside the widget tree)
/// can navigate to screens — e.g., AlertCoordinatorV2 opening the lock-screen
/// safety check when sensors detect an extraction.
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;
  static BuildContext? get context => navigatorKey.currentContext;

  /// Push a route from anywhere
  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) async {
    return navigator?.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Replace the current route
  static Future<T?> pushReplacementNamed<T, TO>(String routeName,
      {Object? arguments, TO? result}) async {
    return navigator?.pushReplacementNamed<T, TO>(routeName,
        arguments: arguments, result: result);
  }

  /// Push and remove all previous routes
  static Future<T?> pushNamedAndRemoveUntil<T>(String routeName) async {
    return navigator?.pushNamedAndRemoveUntil<T>(routeName, (route) => false);
  }

  /// Pop current route
  static void pop<T>([T? result]) {
    navigator?.pop<T>(result);
  }
}
