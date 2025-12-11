import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/template.dart';
import '../../data/datasources/local/template_cache_datasource.dart';
import '../app_config.dart';
import 'connectivity_service.dart';

/// Service for managing template caching and offline access
class TemplateCacheService extends ChangeNotifier {
  static final TemplateCacheService _instance = TemplateCacheService._internal();
  factory TemplateCacheService() => _instance;
  TemplateCacheService._internal();

  final TemplateCacheDataSource _cacheDataSource = TemplateCacheDataSource();
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isInitialized = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _syncError;

  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;
  
  /// Whether sync is currently in progress
  bool get isSyncing => _isSyncing;
  
  /// Last successful sync time
  DateTime? get lastSyncTime => _lastSyncTime;
  
  /// Last sync error message
  String? get syncError => _syncError;

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize connectivity service
      await _connectivityService.initialize();
      
      // Listen for connectivity changes
      _connectivityService.addListener(_onConnectivityChanged);
      
      // Perform initial sync if online
      if (_connectivityService.isOnline) {
        await _performBackgroundSync();
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing template cache service: $e');
      }
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged() {
    if (_connectivityService.isOnline && _lastSyncTime == null) {
      // First time online, perform sync
      _performBackgroundSync();
    } else if (_connectivityService.isOnline) {
      // Check if we need to sync (every 30 minutes)
      final now = DateTime.now();
      if (_lastSyncTime == null || 
          now.difference(_lastSyncTime!).inMinutes > 30) {
        _performBackgroundSync();
      }
    }
  }

  /// Perform background sync without blocking UI
  Future<void> _performBackgroundSync() async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      _syncError = null;
      notifyListeners();

      // Sync templates and categories
      await _syncTemplatesFromServer();
      await _syncCategoriesFromServer();
      
      _lastSyncTime = DateTime.now();
      
      if (kDebugMode) {
        print('Background sync completed successfully');
      }
    } catch (e) {
      _syncError = e.toString();
      if (kDebugMode) {
        print('Background sync failed: $e');
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Manually trigger sync
  Future<void> syncNow() async {
    if (!_connectivityService.isOnline) {
      throw Exception('İnternet bağlantısı gerekli');
    }

    await _performBackgroundSync();
  }

  /// Get template by ID (cache first, then network)
  Future<Template?> getTemplate(String templateId) async {
    // Try cache first
    final cachedTemplate = await _cacheDataSource.getCachedTemplate(templateId);
    if (cachedTemplate != null) {
      return cachedTemplate;
    }

    // If not in cache and online, fetch from network
    if (_connectivityService.isOnline) {
      try {
        final template = await _fetchTemplateFromServer(templateId);
        if (template != null) {
          // Cache the template
          await _cacheDataSource.cacheTemplate(template);
          return template;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching template from server: $e');
        }
      }
    }

    return null;
  }

  /// Get all available templates (cache first, then network)
  Future<List<Template>> getAllTemplates() async {
    // Always return cached templates first
    final cachedTemplates = await _cacheDataSource.getAllCachedTemplates();
    
    // If online, try to sync in background
    if (_connectivityService.isOnline && !_isSyncing) {
      _performBackgroundSync();
    }
    
    return cachedTemplates;
  }

  /// Get templates by category
  Future<List<Template>> getTemplatesByCategory(String categoryId) async {
    final cachedTemplates = await _cacheDataSource.getCachedTemplatesByCategory(categoryId);
    
    // If online and no cached templates, try to fetch from server
    if (cachedTemplates.isEmpty && _connectivityService.isOnline) {
      try {
        await _syncTemplatesFromServer();
        return await _cacheDataSource.getCachedTemplatesByCategory(categoryId);
      } catch (e) {
        if (kDebugMode) {
          print('Error syncing templates: $e');
        }
      }
    }
    
    return cachedTemplates;
  }

  /// Search templates in cache
  Future<List<Template>> searchTemplates(String query) async {
    return await _cacheDataSource.searchCachedTemplates(query);
  }

  /// Get purchased templates
  Future<List<Template>> getPurchasedTemplates() async {
    return await _cacheDataSource.getPurchasedTemplates();
  }

  /// Mark template as purchased and cache it
  Future<void> markTemplateAsPurchased(String templateId) async {
    await _cacheDataSource.markTemplateAsPurchased(templateId);
    
    // If template is not cached, try to fetch and cache it
    if (!await _cacheDataSource.isTemplateCached(templateId) && _connectivityService.isOnline) {
      final template = await _fetchTemplateFromServer(templateId);
      if (template != null) {
        await _cacheDataSource.cacheTemplate(template, isPurchased: true);
      }
    }
    
    notifyListeners();
  }

  /// Get cached categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final cachedCategories = await _cacheDataSource.getCachedCategories();
    
    // If no cached categories and online, sync from server
    if (cachedCategories.isEmpty && _connectivityService.isOnline) {
      try {
        await _syncCategoriesFromServer();
        return await _cacheDataSource.getCachedCategories();
      } catch (e) {
        if (kDebugMode) {
          print('Error syncing categories: $e');
        }
      }
    }
    
    return cachedCategories;
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final stats = await _cacheDataSource.getCacheStats();
    return {
      ...stats,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'isOnline': _connectivityService.isOnline,
      'syncError': _syncError,
    };
  }

  /// Clean old cache entries
  Future<void> cleanCache() async {
    await _cacheDataSource.cleanOldCache();
    notifyListeners();
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    await _cacheDataSource.clearCache();
    _lastSyncTime = null;
    notifyListeners();
  }

  /// Check if template is available offline
  Future<bool> isTemplateAvailableOffline(String templateId) async {
    return await _cacheDataSource.isTemplateCached(templateId);
  }

  /// Preload popular templates for offline access
  Future<void> preloadPopularTemplates({int limit = 20}) async {
    if (!_connectivityService.isOnline) return;

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/templates/popular?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final templatesData = data['data']['templates'] as List;
          final templates = templatesData.map((json) => _templateFromJson(json)).toList();
          
          await _cacheDataSource.cacheTemplates(templates);
          
          if (kDebugMode) {
            print('Preloaded ${templates.length} popular templates');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error preloading popular templates: $e');
      }
    }
  }

  /// Sync templates from server
  Future<void> _syncTemplatesFromServer() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/templates'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final templatesData = data['data']['templates'] as List;
          final templates = templatesData.map((json) => _templateFromJson(json)).toList();
          
          // Get purchased template IDs (this would come from user's purchase history)
          final purchasedIds = await _getPurchasedTemplateIds();
          
          await _cacheDataSource.cacheTemplates(templates, purchasedTemplateIds: purchasedIds);
          
          if (kDebugMode) {
            print('Synced ${templates.length} templates from server');
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to sync templates: $e');
    }
  }

  /// Sync categories from server
  Future<void> _syncCategoriesFromServer() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final categoriesData = data['data']['categories'] as List;
          await _cacheDataSource.cacheCategories(categoriesData.cast<Map<String, dynamic>>());
          
          if (kDebugMode) {
            print('Synced ${categoriesData.length} categories from server');
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to sync categories: $e');
    }
  }

  /// Fetch single template from server
  Future<Template?> _fetchTemplateFromServer(String templateId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/templates/$templateId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return _templateFromJson(data['data']['template']);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch template: $e');
    }
  }

  /// Get purchased template IDs for current user
  Future<List<String>> _getPurchasedTemplateIds() async {
    try {
      // This would typically require authentication
      // For now, return empty list
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Convert JSON to Template object
  Template _templateFromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      categoryId: json['categoryId'],
      body: json['body'],
      placeholders: (json['placeholders'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, _placeholderConfigFromJson(value)),
      ),
      createdBy: json['createdBy'],
      price: (json['price'] as num).toDouble(),
      status: TemplateStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TemplateStatus.pending,
      ),
      isVerified: json['isVerified'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      rating: (json['rating'] as num).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      downloadCount: json['downloadCount'] ?? 0,
      purchaseCount: json['purchaseCount'] ?? 0,
      version: json['version'] ?? '1.0',
      previewImageUrl: json['previewImageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Convert JSON to PlaceholderConfig object
  PlaceholderConfig _placeholderConfigFromJson(Map<String, dynamic> json) {
    return PlaceholderConfig(
      type: PlaceholderType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PlaceholderType.string,
      ),
      label: json['label'],
      required: json['required'] ?? false,
      validation: json['validation'] != null
          ? ValidationRules(
              minLength: json['validation']['minLength'],
              maxLength: json['validation']['maxLength'],
              minValue: json['validation']['minValue']?.toDouble(),
              maxValue: json['validation']['maxValue']?.toDouble(),
              pattern: json['validation']['pattern'],
            )
          : null,
      defaultValue: json['defaultValue'],
      options: json['options']?.cast<String>(),
      order: json['order'] ?? 0,
    );
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    _cacheDataSource.close();
    super.dispose();
  }
}