import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../domain/entities/template.dart';
import '../../core/app_config.dart';

class Category {
  final String id;
  final String name;
  final String slug;
  final String? parentId;
  final String? description;
  final String? icon;
  final int orderIndex;
  final bool isActive;
  final int templateCount;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.description,
    this.icon,
    required this.orderIndex,
    required this.isActive,
    required this.templateCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      parentId: json['parent_id'],
      description: json['description'],
      icon: json['icon'],
      orderIndex: json['order_index'] ?? 0,
      isActive: json['is_active'] ?? true,
      templateCount: json['template_count'] ?? 0,
    );
  }
}

class TemplateProvider extends ChangeNotifier {
  List<Template> _templates = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  String? _searchQuery;
  String? _selectedCategory;
  bool _isSyncing = false;
  final Map<String, dynamic> _cacheStats = {};

  List<Template> get templates => _templates;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  bool get isSyncing => _isSyncing;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Load templates from API
  Future<void> loadTemplates({
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    setLoading(true);
    setError(null);

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null && category != 'Tümü') {
        queryParams['category'] = category;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}/api/v1/templates').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(uri);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final templatesData = data['data']['templates'] as List;
        _templates = templatesData.map((templateJson) {
          return Template(
            id: templateJson['id'],
            title: templateJson['title'],
            description: templateJson['description'],
            categoryId: templateJson['category_id'],
            body: templateJson['body'],
            placeholders: _parsePlaceholders(templateJson['placeholders'] ?? {}),
            createdBy: templateJson['created_by'],
            price: double.tryParse(templateJson['price']?.toString() ?? '0') ?? 0.0,
            isVerified: templateJson['is_verified'] ?? false,
            isFeatured: templateJson['is_featured'] ?? false,
            status: _parseTemplateStatus(templateJson['status'] ?? 'published'),
            rating: double.tryParse(templateJson['rating']?.toString() ?? '0') ?? 0.0,
            totalRatings: templateJson['total_ratings'] ?? 0,
            downloadCount: templateJson['download_count'] ?? 0,
            purchaseCount: templateJson['purchase_count'] ?? 0,
            version: templateJson['version'] ?? '1.0',
            previewImageUrl: templateJson['preview_image_url'],
            createdAt: DateTime.tryParse(templateJson['created_at'] ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(templateJson['updated_at'] ?? '') ?? DateTime.now(),
          );
        }).toList();

        _searchQuery = search;
        _selectedCategory = category;
      } else {
        setError(data['error']?['message'] ?? 'Şablonlar yüklenemedi');
      }
    } catch (e) {
      debugPrint('Load templates error: $e');
      setError('Bağlantı hatası: $e');
    } finally {
      setLoading(false);
    }
  }

  // Load categories from API
  Future<void> loadCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/categories'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final categoriesData = data['data'] as List;
        _categories = categoriesData.map((categoryJson) {
          return Category.fromJson(categoryJson);
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load categories error: $e');
    }
  }

  // Get template by ID
  Future<Template?> getTemplateById(String templateId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/templates/$templateId'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final templateJson = data['data'];
        return Template(
          id: templateJson['id'],
          title: templateJson['title'],
          description: templateJson['description'],
          categoryId: templateJson['category_id'],
          body: templateJson['body'],
          placeholders: _parsePlaceholders(templateJson['placeholders'] ?? {}),
          createdBy: templateJson['created_by'],
          price: double.tryParse(templateJson['price']?.toString() ?? '0') ?? 0.0,
          isVerified: templateJson['is_verified'] ?? false,
          isFeatured: templateJson['is_featured'] ?? false,
          status: _parseTemplateStatus(templateJson['status'] ?? 'published'),
          rating: double.tryParse(templateJson['rating']?.toString() ?? '0') ?? 0.0,
          totalRatings: templateJson['total_ratings'] ?? 0,
          downloadCount: templateJson['download_count'] ?? 0,
          purchaseCount: templateJson['purchase_count'] ?? 0,
          version: templateJson['version'] ?? '1.0',
          previewImageUrl: templateJson['preview_image_url'],
          createdAt: DateTime.tryParse(templateJson['created_at'] ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(templateJson['updated_at'] ?? '') ?? DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Get template error: $e');
    }
    return null;
  }

  // Search templates
  Future<void> searchTemplates({
    String? query,
    String? category,
    String? priceFilter,
    String? sortBy,
    String? tag,
  }) async {
    await loadTemplates(
      search: query,
      category: category,
    );
  }

  // Clear search
  void clearSearch() {
    _searchQuery = null;
    _selectedCategory = null;
    loadTemplates();
  }

  // Get popular templates
  List<Template> get popularTemplates {
    final sorted = List<Template>.from(_templates);
    sorted.sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
    return sorted.take(10).toList();
  }

  // Get featured templates
  List<Template> get featuredTemplates {
    return _templates.where((template) => template.isFeatured).toList();
  }

  // Get free templates
  List<Template> get freeTemplates {
    return _templates.where((template) => template.price == 0).toList();
  }

  // Get templates by category
  List<Template> getTemplatesByCategory(String categoryId) {
    return _templates.where((template) => template.categoryId == categoryId).toList();
  }

  // Get template preview
  Future<Map<String, dynamic>> getTemplatePreview(String templateId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/templates/$templateId/preview'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      }
    } catch (e) {
      debugPrint('Get template preview error: $e');
    }
    
    // Return mock preview data
    return {
      'previewText': 'Örnek önizleme metni...\n\nBu şablon için örnek içerik burada görünecektir.',
    };
  }

  // Get template ratings
  Future<Map<String, dynamic>> getTemplateRatings(String templateId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/templates/$templateId/ratings'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      }
    } catch (e) {
      debugPrint('Get template ratings error: $e');
    }
    
    // Return mock ratings data
    return {
      'ratings': [
        {
          'id': '1',
          'userName': 'Ahmet Y.',
          'rating': 5,
          'comment': 'Çok kullanışlı bir şablon, teşekkürler!',
          'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        },
        {
          'id': '2',
          'userName': 'Fatma K.',
          'rating': 4,
          'comment': 'Güzel tasarım, sadece birkaç küçük düzeltme gerekiyor.',
          'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        },
      ],
      'summary': {
        'averageRating': 4.5,
        'totalRatings': 2,
        'ratingDistribution': {
          '5': 1,
          '4': 1,
          '3': 0,
          '2': 0,
          '1': 0,
        },
      },
    };
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalTemplates': _templates.length,
      'cachedTemplates': _templates.where((t) => t.isCached ?? false).length,
      'lastUpdate': DateTime.now().toIso8601String(),
      'cacheSize': _calculateCacheSize(),
      ..._cacheStats,
    };
  }
  
  /// Sync templates with server
  Future<void> syncTemplates() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      await loadTemplates();
      await loadCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  /// Download templates for offline use
  Future<void> downloadTemplatesForOffline(List<String> templateIds) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      for (String templateId in templateIds) {
        final template = _templates.firstWhere((t) => t.id == templateId);
        // Mark as cached (in real implementation, would download assets)
        final updatedTemplate = Template(
          id: template.id,
          title: template.title,
          description: template.description,
          categoryId: template.categoryId,
          body: template.body,
          placeholders: template.placeholders,
          createdBy: template.createdBy,
          price: template.price,
          status: template.status,
          isVerified: template.isVerified,
          isFeatured: template.isFeatured,
          rating: template.rating,
          totalRatings: template.totalRatings,
          downloadCount: template.downloadCount,
          purchaseCount: template.purchaseCount,
          version: template.version,
          previewImageUrl: template.previewImageUrl,
          createdAt: template.createdAt,
          updatedAt: template.updatedAt,
          isCached: true,
        );
        
        final index = _templates.indexWhere((t) => t.id == templateId);
        if (index != -1) {
          _templates[index] = updatedTemplate;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get offline templates
  List<Template> getOfflineTemplates() {
    return _templates.where((template) => template.isCached ?? false).toList();
  }
  
  /// Clear cache
  Future<void> clearCache() async {
    _templates.clear();
    _categories.clear();
    _cacheStats.clear();
    notifyListeners();
  }
  
  /// Set selected category
  void setSelectedCategory(String? categoryId) {
    _selectedCategory = categoryId;
    notifyListeners();
  }
  
  /// Generate form configuration for template
  Map<String, dynamic> generateFormConfig(Template template) {
    final List<Map<String, dynamic>> fields = [];
    
    template.placeholders.forEach((key, config) {
      fields.add({
        'key': key,
        'type': config.type.name,
        'label': config.label,
        'required': config.required,
        'order': config.order,
        'defaultValue': config.defaultValue,
        'options': config.options,
      });
    });
    
    // Sort by order
    fields.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
    
    return {
      'templateId': template.id,
      'templateTitle': template.title,
      'fields': fields,
    };
  }
  
  /// Validate user data against template
  Map<String, String> validateUserData(Template template, Map<String, dynamic> userData) {
    final Map<String, String> errors = {};
    
    template.placeholders.forEach((key, config) {
      final value = userData[key];
      
      // Check required fields
      if (config.required && (value == null || value.toString().isEmpty)) {
        errors[key] = '${config.label} is required';
        return;
      }
      
      // Type-specific validation
      if (value != null && value.toString().isNotEmpty) {
        switch (config.type) {
          case PlaceholderType.email:
            if (!_isValidEmail(value.toString())) {
              errors[key] = 'Invalid email format';
            }
            break;
          case PlaceholderType.phone:
            if (!_isValidPhone(value.toString())) {
              errors[key] = 'Invalid phone format';
            }
            break;
          case PlaceholderType.number:
            if (double.tryParse(value.toString()) == null) {
              errors[key] = 'Must be a valid number';
            }
            break;
          case PlaceholderType.date:
            if (DateTime.tryParse(value.toString()) == null) {
              errors[key] = 'Invalid date format';
            }
            break;
          default:
            break;
        }
      }
    });
    
    return errors;
  }

  // Helper method to parse template status
  TemplateStatus _parseTemplateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return TemplateStatus.draft;
      case 'published':
        return TemplateStatus.published;
      case 'archived':
        return TemplateStatus.archived;
      default:
        return TemplateStatus.published;
    }
  }

  // Helper method to parse placeholders
  Map<String, PlaceholderConfig> _parsePlaceholders(Map<String, dynamic> placeholdersJson) {
    final Map<String, PlaceholderConfig> placeholders = {};
    
    placeholdersJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        placeholders[key] = PlaceholderConfig(
          type: _parsePlaceholderType(value['type'] ?? 'string'),
          label: value['label'] ?? key,
          required: value['required'] ?? false,
          order: value['order'] ?? 0,
          defaultValue: value['defaultValue'],
          options: value['options'] != null ? List<String>.from(value['options']) : null,
        );
      }
    });
    
    return placeholders;
  }

  // Helper method to parse placeholder type
  PlaceholderType _parsePlaceholderType(String type) {
    switch (type.toLowerCase()) {
      case 'string':
        return PlaceholderType.string;
      case 'text':
        return PlaceholderType.text;
      case 'textarea':
        return PlaceholderType.textarea;
      case 'date':
        return PlaceholderType.date;
      case 'number':
        return PlaceholderType.number;
      case 'phone':
        return PlaceholderType.phone;
      case 'email':
        return PlaceholderType.email;
      case 'select':
        return PlaceholderType.select;
      case 'checkbox':
        return PlaceholderType.checkbox;
      case 'radio':
        return PlaceholderType.radio;
      default:
        return PlaceholderType.string;
    }
  }
  
  /// Calculate cache size
  double _calculateCacheSize() {
    // Simplified calculation - in real implementation would calculate actual file sizes
    return _templates.length * 0.1; // MB per template
  }
  
  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  /// Validate phone format
  bool _isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone);
  }
}