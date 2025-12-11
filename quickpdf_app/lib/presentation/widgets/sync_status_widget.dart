import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/sync_service.dart';
import '../../core/services/connectivity_service.dart';

/// Widget that displays sync status and connectivity information
class SyncStatusWidget extends StatelessWidget {
  final bool showDetails;
  final VoidCallback? onTap;

  const SyncStatusWidget({
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
        final hasConflicts = syncService.hasConflicts;
        final lastSyncTime = syncService.lastFullSync;
        final syncError = syncService.syncStatus == SyncStatus.error ? 'Sync error' : null;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(isOnline, isSyncing, hasConflicts, syncError).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getStatusColor(isOnline, isSyncing, hasConflicts, syncError).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusIcon(isOnline, isSyncing, hasConflicts, syncError),
                const SizedBox(width: 8),
                if (showDetails) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getStatusText(isOnline, isSyncing, hasConflicts, syncError),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (lastSyncTime != null && !isSyncing) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Son senkronizasyon: ${_formatLastSync(lastSyncTime)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (syncError != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            syncError,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    _getStatusText(isOnline, isSyncing, hasConflicts, syncError),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (hasConflicts) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${syncService.conflicts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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

  Widget _buildStatusIcon(bool isOnline, bool isSyncing, bool hasConflicts, String? syncError) {
    if (isSyncing) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    IconData iconData;
    Color iconColor;

    if (hasConflicts) {
      iconData = Icons.warning;
      iconColor = Colors.orange;
    } else if (syncError != null) {
      iconData = Icons.error;
      iconColor = Colors.red;
    } else if (isOnline) {
      iconData = Icons.cloud_done;
      iconColor = Colors.green;
    } else {
      iconData = Icons.cloud_off;
      iconColor = Colors.grey;
    }

    return Icon(
      iconData,
      size: 16,
      color: iconColor,
    );
  }

  String _getStatusText(bool isOnline, bool isSyncing, bool hasConflicts, String? syncError) {
    if (isSyncing) {
      return 'Senkronize ediliyor...';
    }

    if (hasConflicts) {
      return 'Çakışma var';
    }

    if (syncError != null) {
      return 'Senkronizasyon hatası';
    }

    if (isOnline) {
      return 'Çevrimiçi';
    } else {
      return 'Çevrimdışı';
    }
  }

  Color _getStatusColor(bool isOnline, bool isSyncing, bool hasConflicts, String? syncError) {
    if (isSyncing) {
      return Colors.blue;
    }

    if (hasConflicts) {
      return Colors.orange;
    }

    if (syncError != null) {
      return Colors.red;
    }

    if (isOnline) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else {
      return '${difference.inDays} gün önce';
    }
  }
}

/// Floating sync status indicator
class FloatingSyncStatus extends StatelessWidget {
  const FloatingSyncStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, child) {
        // Only show if there are issues or actively syncing
        if (!syncService.isSyncing && 
            !syncService.hasConflicts && 
            syncService.syncStatus != SyncStatus.error) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: SyncStatusWidget(
              showDetails: true,
              onTap: () => _showSyncDetails(context),
            ),
          ),
        );
      },
    );
  }

  void _showSyncDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const SyncDetailsSheet(),
    );
  }
}

/// Bottom sheet showing detailed sync information
class SyncDetailsSheet extends StatelessWidget {
  const SyncDetailsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, child) {
        return FutureBuilder<SyncStats>(
          future: syncService.getSyncStats(),
          builder: (context, snapshot) {
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sync, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Senkronizasyon Durumu',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatusItem(
                context,
                'Bağlantı Durumu',
                'Çevrimiçi', // Simplified for now
                Colors.green,
              ),
              _buildStatusItem(
                context,
                'Senkronizasyon',
                syncService.isSyncing ? 'Devam ediyor' : 'Tamamlandı',
                syncService.isSyncing ? Colors.blue : Colors.green,
              ),
              _buildStatusItem(
                context,
                'Otomatik Senkronizasyon',
                syncService.autoSyncEnabled ? 'Açık' : 'Kapalı',
                syncService.autoSyncEnabled ? Colors.green : Colors.orange,
              ),
              if (syncService.lastFullSync != null)
                _buildStatusItem(
                  context,
                  'Son Senkronizasyon',
                  _formatDateTime(syncService.lastFullSync!),
                  Colors.grey,
                ),
              if (syncService.hasConflicts)
                _buildStatusItem(
                  context,
                  'Çakışmalar',
                  '${syncService.conflicts.length} çakışma',
                  Colors.orange,
                ),
              if (syncService.syncStatus == SyncStatus.error) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hata:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text('Senkronizasyon hatası oluştu'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: syncService.isSyncing ? null : () async {
                        try {
                          await syncService.syncNow();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Senkronizasyon tamamlandı'),
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
                      },
                      child: Text(syncService.isSyncing ? 'Senkronize ediliyor...' : 'Şimdi Senkronize Et'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      syncService.setAutoSyncEnabled(!syncService.autoSyncEnabled);
                    },
                    icon: Icon(
                      syncService.autoSyncEnabled ? Icons.sync : Icons.sync_disabled,
                    ),
                    tooltip: syncService.autoSyncEnabled 
                        ? 'Otomatik senkronizasyonu kapat' 
                        : 'Otomatik senkronizasyonu aç',
                  ),
                ],
              ),
              if (syncService.hasConflicts) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showConflictResolution(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Çakışmaları Çöz (${syncService.conflicts.length})'),
                ),
              ],
            ],
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildStatusItem(BuildContext context, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showConflictResolution(BuildContext context) {
    // Implementation for conflict resolution UI
    // This would show a detailed view of conflicts and resolution options
  }
}