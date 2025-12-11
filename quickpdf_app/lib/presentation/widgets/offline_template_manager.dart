import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/template_provider.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';
import '../../domain/entities/template.dart';
import 'sync_status_indicator.dart';

/// Widget for managing offline template cache
class OfflineTemplateManager extends StatefulWidget {
  const OfflineTemplateManager({super.key});

  @override
  State<OfflineTemplateManager> createState() => _OfflineTemplateManagerState();
}

class _OfflineTemplateManagerState extends State<OfflineTemplateManager> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer3<TemplateProvider, ConnectivityService, SyncService>(
      builder: (context, templateProvider, connectivityService, syncService, child) {
        final cacheStats = templateProvider.getCacheStats();
        final isOnline = connectivityService.isOnline;
        final isSyncing = templateProvider.isSyncing;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: isOnline ? Colors.green : Colors.orange,
                ),
                title: Text(
                  isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${cacheStats['validCount']} şablon önbellekte',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SyncStatusIndicator(showDetails: true),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
              if (_isExpanded) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCacheStats(cacheStats),
                      const SizedBox(height: 16),
                      _buildActionButtons(
                        context,
                        templateProvider,
                        isOnline,
                        isSyncing,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCacheStats(Map<String, dynamic> stats) {
    final lastSyncTime = stats['lastSyncTime'] as String?;
    final lastSyncDate = lastSyncTime != null 
        ? DateTime.parse(lastSyncTime)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Önbellek Durumu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildStatRow('Toplam Şablon', '${stats['totalCached']}'),
        _buildStatRow('Geçerli Şablon', '${stats['validCount']}'),
        _buildStatRow('Süresi Dolmuş', '${stats['expiredCount']}'),
        _buildStatRow(
          'Önbellek Boyutu', 
          '${((stats['cacheSize'] as int) / 1024).toStringAsFixed(1)} KB',
        ),
        if (lastSyncDate != null)
          _buildStatRow(
            'Son Senkronizasyon',
            DateFormat('dd.MM.yyyy HH:mm').format(lastSyncDate),
          ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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

  Widget _buildActionButtons(
    BuildContext context,
    TemplateProvider templateProvider,
    bool isOnline,
    bool isSyncing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOnline) ...[
          ElevatedButton.icon(
            onPressed: isSyncing ? null : () => _syncTemplates(templateProvider),
            icon: const Icon(Icons.sync),
            label: const Text('Şablonları Senkronize Et'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isSyncing ? null : () => _downloadPopularTemplates(templateProvider),
            icon: const Icon(Icons.download),
            label: const Text('Popüler Şablonları İndir'),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showCacheManagement(context, templateProvider),
          icon: const Icon(Icons.storage),
          label: const Text('Önbellek Yönetimi'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
          ),
        ),
      ],
    );
  }

  Future<void> _syncTemplates(TemplateProvider templateProvider) async {
    try {
      await templateProvider.syncTemplates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şablonlar başarıyla senkronize edildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Senkronizasyon hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadPopularTemplates(TemplateProvider templateProvider) async {
    try {
      // Get popular template IDs (mock for now)
      final popularTemplateIds = templateProvider.templates
          .where((t) => t.isFeatured || t.rating >= 4.0)
          .take(10)
          .map((t) => t.id)
          .toList();

      if (popularTemplateIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İndirilecek popüler şablon bulunamadı'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await templateProvider.downloadTemplatesForOffline(popularTemplateIds);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${popularTemplateIds.length} popüler şablon indirildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İndirme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCacheManagement(BuildContext context, TemplateProvider templateProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => CacheManagementSheet(templateProvider: templateProvider),
    );
  }
}

/// Bottom sheet for cache management options
class CacheManagementSheet extends StatelessWidget {
  final TemplateProvider templateProvider;

  const CacheManagementSheet({
    super.key,
    required this.templateProvider,
  });

  @override
  Widget build(BuildContext context) {
    final offlineTemplates = templateProvider.getOfflineTemplates();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Önbellek Yönetimi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Önbellekteki Şablonlar'),
            subtitle: Text('${offlineTemplates.length} şablon mevcut'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pop(context);
              _showCachedTemplatesList(context, offlineTemplates);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text('Önbelleği Temizle'),
            subtitle: const Text('Tüm önbellekteki şablonları sil'),
            onTap: () => _confirmClearCache(context),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showCachedTemplatesList(BuildContext context, List<Template> templates) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Önbellekteki Şablonlar'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                title: Text(template.title),
                subtitle: Text(template.description),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeFromCache(context, template.id),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Önbelleği Temizle'),
        content: const Text(
          'Tüm önbellekteki şablonlar silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              
              try {
                await templateProvider.clearCache();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Önbellek temizlendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Temizleme hatası: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _removeFromCache(BuildContext context, String templateId) {
    // TODO: Implement individual template removal from cache
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tekil şablon silme özelliği yakında eklenecek'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}