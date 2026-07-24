import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitors network connectivity and provides utilities for offline handling.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  /// Start monitoring connectivity changes.
  void startMonitoring({void Function(bool isConnected)? onChanged}) {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final connected = !results.contains(ConnectivityResult.none);
      if (connected != _isConnected) {
        _isConnected = connected;
        onChanged?.call(connected);
      }
    });
  }

  /// Check current connectivity status.
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isConnected = !results.contains(ConnectivityResult.none);
    return _isConnected;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
