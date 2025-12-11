import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/services/sync_service.dart';
import '../../core/services/connectivity_service.dart';

/// Widget that shows sync status and allows manual sync
class SyncStatusIndicator extends StatelessWidget {
  final bool showDetails;
  final VoidCallback? onTap;

  const SyncStatusIndicator({
    super.key,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SyncService, ConnectivityService>(
      builder: (context, syncService, connectivityService, child) {
        final isOnline = connectivityService.isOnline;
        final isSyncing = syncService.isSyncing;
        final syncStatus = syncService.syncStatus;
        final pendingCount = syncService.pendingOperationsCount;
        final hasConflicts = syncService.hasConflicts;

        return GestureDetector(
          onTap: onTap ?? () => _showSyncDetails(context, syncService),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(syncStatus, isOnline, hasConflicts).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor(syncStatus, isOnline, hasConflicts),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _getStatusIcon(syncStatus, isOnline, hasConflicts),
                    size: 16,
                    color: _getStatusColor(syncStatus, isOnline, hasConflicts),
                  ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(syncStatus, isOnline, isSyncing, pendingCount, hasConflicts),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(syncStatus, isOnline, hasConflicts),
                  ),
                ),
                if (showDetails && (pendingCount > 0 || hasConflicts)) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasConflicts ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      hasConflicts ? '!' : pendingCount.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(SyncStatus status, bool isOnline, bool hasConflicts) {
    if (hasConflicts) return Colors.red;
    if (!isOnline) return Colors.orange;
    
    switch (status) {
      case SyncStatus.idle:
        return Colors.grey;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.conflict:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(SyncStatus status, bool isOnline, bool hasConflicts) {
    if (hasConflicts) return Icons.warning;
    if (!isOnline) return Icons.cloud_off;
    
    switch (status) {
      case SyncStatus.idle:
        return Icons.cloud_queue;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.success:
        return Icons.cloud_done;
      case SyncStatus.error:
        return Icons.error;
      case SyncStatus.conflict:
        return Icons.warning;
    }
  }

  String _getStatusText(SyncStatus status, bool isOnline, bool isSyncing, int pendingCount, bool hasConflicts) {
    if (hasConflicts) return 'Çakışma var';
    if (!isOnline && pendingCount > 0) return 'Beklemede ($pendingCount)';
    if (!isOnline) return 'Çevrimdışı';
    if (isSyncing) return 'Senkronize ediliyor...';
    
    switch (status) {
      case SyncStatus.idle:
        return pendingCount > 0 ? 'Beklemede ($pendingCount)' : 'Güncel';
      case SyncStatus.syncing:
        return 'Senkronize ediliyor...';
      case SyncStatus.success:
        return 'Senkronize edildi';
      case SyncStatus.error:
        return 'Hata oluştu';
      case SyncStatus.conflict:
        return 'Çakışma var';
    }
  }

  void _showSyncDetails(BuildContext context, SyncService syncService) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SyncDetailsSheet(syncService: syncService),
    );
  }
}

/// Bottom sheet showing detailed sync information
class SyncDetailsSheet extends StatelessWidget {
  final SyncService syncService;

  const SyncDetailsSheet({
    super.key,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    final lastSync = syncService.lastFullSync;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Senkronizasyon Durumu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FutureBuilder<SyncStats>(
            future: syncService.getSyncStats(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return _buildSyncStats(snapshot.data!, lastSync);
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
          const SizedBox(height: 16),
          _buildActionButtons(context),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStats(SyncStats stats, DateTime? lastSync) {
    return Column(
      children: [
        _buildStatRow('Toplam İşlem', '${stats.totalOperations}'),
        _buildStatRow('Başarılı', '${stats.successfulOperations}'),
        _buildStatRow('Başarısız', '${stats.failedOperations}'),
        _buildStatRow('Çakışma', '${stats.conflictOperations}'),
        if (lastSync != null)
          _buildStatRow(
            'Son Tam Senkronizasyon',
            DateFormat('dd.MM.yyyy HH:mm').format(lastSync),
          ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: syncService.isSyncing ? null : () => _performFullSync(context),
          icon: const Icon(Icons.sync),
          label: const Text('Tam Senkronizasyon'),
        ),
        const SizedBox(height: 8),
        if (syncService.hasConflicts)
          OutlinedButton.icon(
            onPressed: () => _showConflictResolution(context),
            icon: const Icon(Icons.warning, color: Colors.red),
            label: const Text('Çakışmaları Çöz'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _clearPendingOperations(context),
          icon: const Icon(Icons.clear_all),
          label: const Text('Bekleyen İşlemleri Temizle'),
        ),
      ],
    );
  }

  Future<void> _performFullSync(BuildContext context) async {
    try {
      Navigator.pop(context);
      await syncService.forceFullSync();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tam senkronizasyon tamamlandı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Senkronizasyon hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConflictResolution(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => const ConflictResolutionDialog(),
    );
  }

  Future<void> _clearPendingOperations(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bekleyen İşlemleri Temizle'),
        content: const Text(
          'Tüm bekleyen senkronizasyon işlemleri silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await syncService.clearPendingOperations();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bekleyen işlemler temizlendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }


}

/// Dialog for resolving sync conflicts
class ConflictResolutionDialog extends StatelessWidget {
  const ConflictResolutionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Çakışma Çözümü'),
      content: const Text(
        'Senkronizasyon çakışmaları tespit edildi. Çakışmaları nasıl çözmek istiyorsunuz?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // TODO: Implement conflict resolution UI
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Çakışma çözümü özelliği yakında eklenecek'),
                backgroundColor: Colors.orange,
              ),
            );
          },
          child: const Text('Çöz'),
        ),
      ],
    );
  }
}