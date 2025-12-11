import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/template_cache_service.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';
import '../../presentation/widgets/sync_status_widget.dart';
import '../../domain/entities/template.dart';

/// Example demonstrating offline functionality and synchronization
class OfflineSyncExample extends StatefulWidget {
  const OfflineSyncExample({super.key});

  @override
  State<OfflineSyncExample> createState() => _OfflineSyncExampleState();
}

class _OfflineSyncExampleState extends State<OfflineSyncExample> {
  final TemplateCacheService _cacheService = TemplateCacheService();
  final SyncService _syncService = SyncService();
  final ConnectivityService _connectivityService = ConnectivityService();

  List<Template> _cachedTemplates = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize all services
      await _connectivityService.initialize();
      await _cacheService.initialize();
      await _syncService.initialize();
      
      // Load cached templates
      await _loadCachedTemplates();
      
      setState(() => _error = null);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCachedTemplates() async {
    try {
      final templates = await _cacheService.getAllTemplates();
      setState(() => _cachedTemplates = templates);
    } catch (e) {
      setState(() => _error = 'Şablonlar yüklenemedi: $e');
    }
  }

  Future<void> _syncNow() async {
    if (!_connectivityService.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İnternet bağlantısı gerekli'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await _syncService.syncNow();
      await _loadCachedTemplates();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senkronizasyon tamamlandı'),
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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _preloadPopularTemplates() async {
    if (!_connectivityService.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İnternet bağlantısı gerekli'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await _cacheService.preloadPopularTemplates();
      await _loadCachedTemplates();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Popüler şablonlar önbelleğe alındı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Önbellekleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearCache() async {
    setState(() => _isLoading = true);
    
    try {
      await _cacheService.clearAllCache();
      await _loadCachedTemplates();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Önbellek temizlendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Önbellek temizleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _connectivityService),
        ChangeNotifierProvider.value(value: _cacheService),
        ChangeNotifierProvider.value(value: _syncService),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Çevrimdışı Senkronizasyon Örneği'),
          actions: [
            Consumer<ConnectivityService>(
              builder: (context, connectivity, child) {
                return Icon(
                  connectivity.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: connectivity.isOnline ? Colors.green : Colors.red,
                );
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Sync Status Widget
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  child: const SyncStatusWidget(showDetails: true),
                ),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _syncNow,
                          icon: const Icon(Icons.sync),
                          label: const Text('Senkronize Et'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _preloadPopularTemplates,
                          icon: const Icon(Icons.download),
                          label: const Text('Popülerleri Yükle'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _clearCache,
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Önbelleği Temizle'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Consumer<SyncService>(
                          builder: (context, syncService, child) {
                            return OutlinedButton.icon(
                              onPressed: () {
                                syncService.setAutoSyncEnabled(!syncService.autoSyncEnabled);
                              },
                              icon: Icon(
                                syncService.autoSyncEnabled ? Icons.sync : Icons.sync_disabled,
                              ),
                              label: Text(
                                syncService.autoSyncEnabled ? 'Otomatik Açık' : 'Otomatik Kapalı',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Cache Statistics
                FutureBuilder<Map<String, dynamic>>(
                  future: _cacheService.getCacheStats(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final stats = snapshot.data!;
                      return Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Önbellek İstatistikleri',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text('Toplam şablon: ${stats['totalCached']}'),
                            Text('Satın alınan: ${stats['purchasedCached']}'),
                            if (stats['lastSyncTime'] != null)
                              Text('Son senkronizasyon: ${stats['lastSyncTime']}'),
                            Text('Bağlantı durumu: ${stats['isOnline'] ? 'Çevrimiçi' : 'Çevrimdışı'}'),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                // Cached Templates List
                Expanded(
                  child: _buildTemplatesList(),
                ),
              ],
            ),
            
            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            
            // Floating Sync Status
            const FloatingSyncStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesList() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Hata',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeServices,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_cachedTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Önbellekte Şablon Yok',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'İnternet bağlantınız varsa şablonları senkronize edin',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cachedTemplates.length,
      itemBuilder: (context, index) {
        final template = _cachedTemplates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: template.isFree ? Colors.green : Colors.blue,
              child: Icon(
                template.isFree ? Icons.free_breakfast : Icons.attach_money,
                color: Colors.white,
              ),
            ),
            title: Text(template.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${template.rating.toStringAsFixed(1)} (${template.totalRatings})'),
                    const SizedBox(width: 16),
                    const Icon(Icons.download, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${template.downloadCount}'),
                  ],
                ),
              ],
            ),
            trailing: template.isFree 
                ? const Icon(Icons.check_circle, color: Colors.green)
                : Text(
                    '${template.price.toStringAsFixed(0)} ₺',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
            onTap: () {
              // Navigate to template detail or use template
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${template.title} şablonu seçildi'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Usage example in main app
class OfflineSyncUsageExample {
  /// Initialize offline functionality in your app
  static Future<void> initializeOfflineSupport() async {
    final connectivityService = ConnectivityService();
    final cacheService = TemplateCacheService();
    final syncService = SyncService();

    // Initialize services
    await connectivityService.initialize();
    await cacheService.initialize();
    await syncService.initialize();

    // Preload popular templates for offline access
    if (connectivityService.isOnline) {
      await cacheService.preloadPopularTemplates();
    }
  }

  /// Example of using cached templates in offline mode
  static Future<List<Template>> getAvailableTemplates() async {
    final cacheService = TemplateCacheService();
    
    // This will return cached templates if offline, or sync and return if online
    return await cacheService.getAllTemplates();
  }

  /// Example of checking if a template is available offline
  static Future<bool> isTemplateAvailableOffline(String templateId) async {
    final cacheService = TemplateCacheService();
    return await cacheService.isTemplateAvailableOffline(templateId);
  }

  /// Example of handling sync conflicts
  static Future<void> handleSyncConflicts() async {
    final syncService = SyncService();
    
    if (syncService.hasConflicts) {
      for (final conflict in syncService.conflicts) {
        // Resolve conflict based on your app's logic
        // For example, always use local version:
        await syncService.resolveConflict(conflict.id, SyncResolution.useLocal.name);
      }
    }
  }
}