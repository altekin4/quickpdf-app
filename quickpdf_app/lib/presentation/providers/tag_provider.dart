import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../domain/entities/tag.dart';
import '../../core/app_config.dart';

class TagProvider extends ChangeNotifier {
  List<Tag> _tags = [];
  List<Tag> _popularTags = [];
  bool _isLoading = false;
  String? _error;
  final Map<String, List<Tag>> _templateTags = {};

  List<Tag> get tags => _tags;
  List<Tag> get popularTags => _popularTags;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Load all tags
  Future<void> loadTags() async {
    setLoading(true);
    setError(null);

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/tags'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> tagList = data['data']['tags'];
          _tags = tagList.map((json) => Tag.fromJson(json)).toList();
          
          // Sort by usage count for popular tags
          _popularTags = List.from(_tags)
            ..sort((a, b) => b.usageCount.compareTo(a.usageCount))
            ..take(10).toList();
        } else {
          throw Exception(data['error']['message'] ?? 'Failed to load tags');
        }
      } else {
        throw Exception('Failed to load tags');
      }
    } catch (e) {
      setError(e.toString());
      // Fallback to mock data
      _loadMockTags();
    } finally {
      setLoading(false);
    }
  }

  // Load tags for a specific template
  Future<List<Tag>> getTemplateTags(String templateId) async {
    if (_templateTags.containsKey(templateId)) {
      return _templateTags[templateId]!;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/templates/$templateId/tags'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> tagList = data['data']['tags'];
          final tags = tagList.map((json) => Tag.fromJson(json)).toList();
          _templateTags[templateId] = tags;
          return tags;
        }
      }
    } catch (e) {
      debugPrint('Error loading template tags: $e');
    }

    return [];
  }

  // Add tag to template
  Future<bool> addTagToTemplate(String templateId, String tagName) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/v1/templates/$templateId/tags'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'tagName': tagName}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Refresh template tags
          _templateTags.remove(templateId);
          await getTemplateTags(templateId);
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      setError(e.toString());
    }
    return false;
  }

  // Remove tag from template
  Future<bool> removeTagFromTemplate(String templateId, String tagId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/api/v1/templates/$templateId/tags/$tagId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Refresh template tags
          _templateTags.remove(templateId);
          await getTemplateTags(templateId);
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      setError(e.toString());
    }
    return false;
  }

  // Search tags
  List<Tag> searchTags(String query) {
    if (query.isEmpty) return _tags;
    
    return _tags.where((tag) => 
      tag.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Create new tag
  Future<Tag?> createTag(String name) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/v1/tags'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success']) {
          final tag = Tag.fromJson(data['data']['tag']);
          _tags.add(tag);
          notifyListeners();
          return tag;
        }
      }
    } catch (e) {
      setError(e.toString());
    }
    return null;
  }

  void _loadMockTags() {
    _tags = [
      Tag(
        id: '1',
        name: 'İş',
        slug: 'is',
        usageCount: 45,
        createdAt: DateTime.now(),
      ),
      Tag(
        id: '2',
        name: 'Eğitim',
        slug: 'egitim',
        usageCount: 38,
        createdAt: DateTime.now(),
      ),
      Tag(
        id: '3',
        name: 'Sağlık',
        slug: 'saglik',
        usageCount: 32,
        createdAt: DateTime.now(),
      ),
      Tag(
        id: '4',
        name: 'Finans',
        slug: 'finans',
        usageCount: 28,
        createdAt: DateTime.now(),
      ),
      Tag(
        id: '5',
        name: 'Teknoloji',
        slug: 'teknoloji',
        usageCount: 25,
        createdAt: DateTime.now(),
      ),
      Tag(
        id: '6',
        name: 'Hukuk',
        slug: 'hukuk',
        usageCount: 22,
        createdAt: DateTime.now(),
      ),
      Tag(
        id: '7',
        name: 'Pazarlama',
        slug: 'pazarlama',
        usageCount: 20,
        createdAt: DateTime.now(),
      ),
      Tag(
        id: '8',
        name: 'İnsan Kaynakları',
        slug: 'insan-kaynaklari',
        usageCount: 18,
        createdAt: DateTime.now(),
      ),
    ];

    _popularTags = List.from(_tags)
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount))
      ..take(6).toList();
  }
}