import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'connectivity_service.dart';

/// Sync status enumeration
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  conflict
}

/// Sync resolution enumeration
enum SyncResolution {
  useLocal,
  useRemote,
  merge
}

/// Sync conflict model
class SyncConflict {
  final String id;
  final String type;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime timestamp;

  SyncConflict({
    required this.id,
    required this.type,
    required this.localData,
    required this.remoteData,
    required this.timestamp,
  });
}

/// Sync statistics model
class SyncStats {
  final int totalOperations;
  final int successfulOperations;
  final int failedOperations;
  final int conflictOperations;
  final DateTime lastSync;

  SyncStats({
    required this.totalOperations,
    required this.successfulOperations,
    required this.failedOperations,
    required this.conflictOperations,
    required this.lastSync,
  });
}

/// Service for managing data synchronization between local and remote storage
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isInitialized = false;
  bool _isSyncing = false;
  bool _autoSyncEnabled = true;
  DateTime? _lastSyncTime;
  String? _syncError;
  final List<SyncConflict> _conflicts = [];
  Timer? _syncTimer;

  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;
  
  /// Whether sync is currently in progress
  bool get isSyncing => _isSyncing;
  
  /// Current sync status
  SyncStatus get syncStatus {
    if (_isSyncing) return SyncStatus.syncing;
    if (_syncError != null) return SyncStatus.error;
    if (_conflicts.isNotEmpty) return SyncStatus.conflict;
    if (_lastSyncTime != null) return SyncStatus.success;
    return SyncStatus.idle;
  }
  
  /// Number of pending operations
  int get pendingOperationsCount => _conflicts.length;
  
  /// Last sync time
  DateTime? get lastFullSync => _lastSyncTime;

  /// Auto sync enabled status
  bool get autoSyncEnabled => _autoSyncEnabled;
  
  /// Whether there are conflicts
  bool get hasConflicts => _conflicts.isNotEmpty;
  
  /// Get conflicts list
  List<SyncConflict> get conflicts => List.unmodifiable(_conflicts);

  /// Initialize the sync service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadSyncPreferences();
    await _connectivityService.initialize();

    // Start periodic sync if auto-sync is enabled
    if (_autoSyncEnabled) {
      _startPeriodicSync();
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Set auto sync enabled
  void setAutoSyncEnabled(bool enabled) {
    _autoSyncEnabled = enabled;
    if (enabled) {
      _startPeriodicSync();
    } else {
      _syncTimer?.cancel();
    }
    _saveSyncPreferences();
    notifyListeners();
  }

  /// Sync now (alias for forceFullSync)
  Future<void> syncNow() async {
    await forceFullSync();
  }

  /// Get sync statistics
  Future<SyncStats> getSyncStats() async {
    return SyncStats(
      totalOperations: _conflicts.length,
      successfulOperations: 0,
      failedOperations: _syncError != null ? 1 : 0,
      conflictOperations: _conflicts.length,
      lastSync: _lastSyncTime ?? DateTime.now(),
    );
  }
  
  /// Force a full synchronization
  Future<void> forceFullSync() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    _syncError = null;
    notifyListeners();
    
    try {
      await _performFullSync();
      _lastSyncTime = DateTime.now();
      await _saveSyncPreferences();
    } catch (e) {
      _syncError = e.toString();
      if (kDebugMode) {
        print('Force full sync error: $e');
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  /// Clear all pending operations
  Future<void> clearPendingOperations() async {
    _conflicts.clear();
    _syncError = null;
    notifyListeners();
  }

  /// Resolve conflict
  Future<void> resolveConflict(String conflictId, String resolution) async {
    _conflicts.removeWhere((conflict) => conflict.id == conflictId);
    notifyListeners();
  }
  
  /// Perform full synchronization
  Future<void> _performFullSync() async {
    // Sync templates
    await _syncTemplates();
    
    // Sync documents
    await _syncDocuments();
    
    // Clear resolved conflicts
    _conflicts.removeWhere((conflict) => conflict.timestamp.isBefore(
      DateTime.now().subtract(const Duration(days: 7))
    ));
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (_connectivityService.isOnline && !_isSyncing) {
        _performSync();
      }
    });
  }

  /// Perform sync operation
  Future<void> _performSync() async {
    if (!_connectivityService.isOnline || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await _syncTemplates();
      await _syncDocuments();
      _lastSyncTime = DateTime.now();
      await _saveSyncPreferences();
    } catch (e) {
      _syncError = e.toString();
      if (kDebugMode) {
        print('Sync error: $e');
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Sync templates with server
  Future<void> _syncTemplates() async {
    // Implementation for template synchronization
  }

  /// Sync documents with server
  Future<void> _syncDocuments() async {
    // Implementation for document synchronization
  }

  /// Load sync preferences from storage
  Future<void> _loadSyncPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? true;
      
      final lastSyncString = prefs.getString('last_sync_time');
      if (lastSyncString != null) {
        _lastSyncTime = DateTime.parse(lastSyncString);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading sync preferences: $e');
      }
    }
  }

  /// Save sync preferences to storage
  Future<void> _saveSyncPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_sync_enabled', _autoSyncEnabled);
      
      if (_lastSyncTime != null) {
        await prefs.setString('last_sync_time', _lastSyncTime!.toIso8601String());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving sync preferences: $e');
      }
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}