import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for checking network connectivity
class ConnectivityService {
  final Connectivity _connectivity;
  StreamSubscription<bool>? _subscription;

  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Check if device is currently connected to the internet
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );
    } catch (e) {
      // If we can't check connectivity, assume we're offline
      return false;
    }
  }

  /// Get a stream of connectivity changes
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );
    });
  }

  /// Wait for connection to be available
  /// Returns true if connection is established within timeout
  /// Returns false if timeout is reached
  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (await isConnected()) {
      return true;
    }

    final completer = Completer<bool>();
    Timer? timeoutTimer;

    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    _subscription = connectivityStream.listen((isConnected) {
      if (isConnected && !completer.isCompleted) {
        timeoutTimer?.cancel();
        completer.complete(true);
      }
    });

    final result = await completer.future;
    await _subscription?.cancel();
    _subscription = null;

    return result;
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
  }
}
