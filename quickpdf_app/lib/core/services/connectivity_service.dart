import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for managing network connectivity status
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isOnline = true;
  bool _hasBeenInitialized = false;

  /// Current connectivity status
  bool get isOnline => _isOnline;
  
  /// Whether the service has been initialized
  bool get hasBeenInitialized => _hasBeenInitialized;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    if (_hasBeenInitialized) return;

    // Check initial connectivity status
    await _updateConnectivityStatus();

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
    );

    _hasBeenInitialized = true;
  }

  /// Dispose of resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = _hasInternetConnection(results);
    
    if (wasOnline != _isOnline) {
      notifyListeners();
      
      if (kDebugMode) {
        print('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
      }
    }
  }

  /// Update connectivity status
  Future<void> _updateConnectivityStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = _hasInternetConnection(results);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
      _isOnline = false;
    }
  }

  /// Check if any of the connectivity results indicate internet connection
  bool _hasInternetConnection(List<ConnectivityResult> results) {
    return results.any((result) => 
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet ||
      result == ConnectivityResult.vpn
    );
  }

  /// Manually refresh connectivity status
  Future<void> refresh() async {
    await _updateConnectivityStatus();
    notifyListeners();
  }

  /// Get connectivity status as string for display
  String get statusText => _isOnline ? 'Çevrimiçi' : 'Çevrimdışı';

  /// Get connectivity icon name
  String get statusIcon => _isOnline ? 'wifi' : 'wifi_off';
}