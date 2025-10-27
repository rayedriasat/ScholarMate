import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring network connectivity
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Stream of connectivity status changes
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  ConnectivityService() {
    _initConnectivity();
    _startMonitoring();
  }

  /// Initialize connectivity status
  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error checking initial connectivity: $e');
      // Assume online if we can't check
      _isOnline = true;
    }
  }

  /// Start monitoring connectivity changes
  void _startMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        debugPrint('Connectivity monitoring error: $error');
      },
    );
  }

  /// Update connection status based on connectivity results
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    // Consider online if any connection type is available (except none)
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    // Notify listeners if status changed
    if (wasOnline != _isOnline) {
      debugPrint('Connectivity changed: ${_isOnline ? 'ONLINE' : 'OFFLINE'}');
      notifyListeners();
      _connectivityController.add(_isOnline);
    }
  }

  /// Manually check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      return _isOnline;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return _isOnline; // Return cached status
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    super.dispose();
  }
}
