import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../domain/entities/template.dart';

/// Local data source for caching templates offline
class TemplateCacheDataSource {
  static const String _tableName = 'cached_templates';
  static const String _categoriesTableName = 'cached_categories';
  
  // Template table columns
  static const String _columnId = 'id';
  static const String _columnTitle = 'title';
  static const String _columnDescription = 'description';
  static const String _columnCategoryId = 'category_id';
  static const String _columnBody = 'body';
  static const String _columnPlaceholders = 'placeholders';
  static const String _columnCreatedBy = 'created_by';
  static const String _columnPrice = 'price';
  static const String _columnStatus = 'status';
  static const String _columnIsVerified = 'is_verified';
  static const String _columnIsFeatured = 'is_featured';
  static const String _columnRating = 'rating';
  static const String _columnTotalRatings = 'total_ratings';
  static const String _columnDownloadCount = 'download_count';
  static const String _columnPurchaseCount = 'purchase_count';
  static const String _columnVersion = 'version';
  static const String _columnPreviewImageUrl = 'preview_image_url';
  static const String _columnCreatedAt = 'created_at';
  static const String _columnUpdatedAt = 'updated_at';
  static const String _columnCachedAt = 'cached_at';
  static const String _columnLastAccessed = 'last_accessed';
  static const String _columnIsPurchased = 'is_purchased';
  
  // Category table columns
  static const String _catColumnId = 'id';
  static const String _catColumnName = 'name';
  static const String _catColumnSlug = 'slug';
  static const String _catColumnParentId = 'parent_id';
  static const String _catColumnDescription = 'description';
  static const String _catColumnIcon = 'icon';
  static const String _catColumnOrderIndex = 'order_index';
  static const String _catColumnIsActive = 'is_active';
  static const String _catColumnTemplateCount = 'template_count';
  static const String _catColumnCachedAt = 'cached_at';

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'template_cache.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create templates cache table
    await db.execute('''
      CREATE TABLE $_tableName (
        $_columnId TEXT PRIMARY KEY,
        $_columnTitle TEXT NOT NULL,
        $_columnDescription TEXT NOT NULL,
        $_columnCategoryId TEXT NOT NULL,
        $_columnBody TEXT NOT NULL,
        $_columnPlaceholders TEXT NOT NULL,
        $_columnCreatedBy TEXT NOT NULL,
        $_columnPrice REAL NOT NULL,
        $_columnStatus TEXT NOT NULL,
        $_columnIsVerified INTEGER NOT NULL,
        $_columnIsFeatured INTEGER NOT NULL,
        $_columnRating REAL NOT NULL,
        $_columnTotalRatings INTEGER NOT NULL,
        $_columnDownloadCount INTEGER NOT NULL,
        $_columnPurchaseCount INTEGER NOT NULL,
        $_columnVersion TEXT NOT NULL,
        $_columnPreviewImageUrl TEXT,
        $_columnCreatedAt INTEGER NOT NULL,
        $_columnUpdatedAt INTEGER NOT NULL,
        $_columnCachedAt INTEGER NOT NULL,
        $_columnLastAccessed INTEGER NOT NULL,
        $_columnIsPurchased INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create categories cache table
    await db.execute('''
      CREATE TABLE $_categoriesTableName (
        $_catColumnId TEXT PRIMARY KEY,
        $_catColumnName TEXT NOT NULL,
        $_catColumnSlug TEXT NOT NULL,
        $_catColumnParentId TEXT,
        $_catColumnDescription TEXT,
        $_catColumnIcon TEXT,
        $_catColumnOrderIndex INTEGER NOT NULL,
        $_catColumnIsActive INTEGER NOT NULL,
        $_catColumnTemplateCount INTEGER NOT NULL,
        $_catColumnCachedAt INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_templates_category ON $_tableName($_columnCategoryId)');
    await db.execute('CREATE INDEX idx_templates_cached_at ON $_tableName($_columnCachedAt)');
    await db.execute('CREATE INDEX idx_templates_last_accessed ON $_tableName($_columnLastAccessed)');
    await db.execute('CREATE INDEX idx_templates_purchased ON $_tableName($_columnIsPurchased)');
    await db.execute('CREATE INDEX idx_categories_parent ON $_categoriesTableName($_catColumnParentId)');
  }

  /// Cache a single template
  Future<void> cacheTemplate(Template template, {bool isPurchased = false}) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert(
      _tableName,
      {
        _columnId: template.id,
        _columnTitle: template.title,
        _columnDescription: template.description,
        _columnCategoryId: template.categoryId,
        _columnBody: template.body,
        _columnPlaceholders: json.encode(_placeholdersToJson(template.placeholders)),
        _columnCreatedBy: template.createdBy,
        _columnPrice: template.price,
        _columnStatus: template.status.name,
        _columnIsVerified: template.isVerified ? 1 : 0,
        _columnIsFeatured: template.isFeatured ? 1 : 0,
        _columnRating: template.rating,
        _columnTotalRatings: template.totalRatings,
        _columnDownloadCount: template.downloadCount,
        _columnPurchaseCount: template.purchaseCount,
        _columnVersion: template.version,
        _columnPreviewImageUrl: template.previewImageUrl,
        _columnCreatedAt: template.createdAt.millisecondsSinceEpoch,
        _columnUpdatedAt: template.updatedAt.millisecondsSinceEpoch,
        _columnCachedAt: now,
        _columnLastAccessed: now,
        _columnIsPurchased: isPurchased ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cache multiple templates
  Future<void> cacheTemplates(List<Template> templates, {List<String>? purchasedTemplateIds}) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    for (final template in templates) {
      final isPurchased = purchasedTemplateIds?.contains(template.id) ?? false;
      
      batch.insert(
        _tableName,
        {
          _columnId: template.id,
          _columnTitle: template.title,
          _columnDescription: template.description,
          _columnCategoryId: template.categoryId,
          _columnBody: template.body,
          _columnPlaceholders: json.encode(_placeholdersToJson(template.placeholders)),
          _columnCreatedBy: template.createdBy,
          _columnPrice: template.price,
          _columnStatus: template.status.name,
          _columnIsVerified: template.isVerified ? 1 : 0,
          _columnIsFeatured: template.isFeatured ? 1 : 0,
          _columnRating: template.rating,
          _columnTotalRatings: template.totalRatings,
          _columnDownloadCount: template.downloadCount,
          _columnPurchaseCount: template.purchaseCount,
          _columnVersion: template.version,
          _columnPreviewImageUrl: template.previewImageUrl,
          _columnCreatedAt: template.createdAt.millisecondsSinceEpoch,
          _columnUpdatedAt: template.updatedAt.millisecondsSinceEpoch,
          _columnCachedAt: now,
          _columnLastAccessed: now,
          _columnIsPurchased: isPurchased ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }

  /// Get cached template by ID
  Future<Template?> getCachedTemplate(String id) async {
    final db = await database;
    
    // Update last accessed time
    await db.update(
      _tableName,
      {_columnLastAccessed: DateTime.now().millisecondsSinceEpoch},
      where: '$_columnId = ?',
      whereArgs: [id],
    );
    
    final results = await db.query(
      _tableName,
      where: '$_columnId = ?',
      whereArgs: [id],
    );
    
    if (results.isEmpty) return null;
    
    return _templateFromMap(results.first);
  }

  /// Get all cached templates
  Future<List<Template>> getAllCachedTemplates() async {
    final db = await database;
    final results = await db.query(
      _tableName,
      orderBy: '$_columnLastAccessed DESC',
    );
    
    return results.map(_templateFromMap).toList();
  }

  /// Get cached templates by category
  Future<List<Template>> getCachedTemplatesByCategory(String categoryId) async {
    final db = await database;
    final results = await db.query(
      _tableName,
      where: '$_columnCategoryId = ?',
      whereArgs: [categoryId],
      orderBy: '$_columnRating DESC, $_columnDownloadCount DESC',
    );
    
    return results.map(_templateFromMap).toList();
  }

  /// Get purchased templates from cache
  Future<List<Template>> getPurchasedTemplates() async {
    final db = await database;
    final results = await db.query(
      _tableName,
      where: '$_columnIsPurchased = ?',
      whereArgs: [1],
      orderBy: '$_columnLastAccessed DESC',
    );
    
    return results.map(_templateFromMap).toList();
  }

  /// Search cached templates
  Future<List<Template>> searchCachedTemplates(String query) async {
    final db = await database;
    final results = await db.query(
      _tableName,
      where: '$_columnTitle LIKE ? OR $_columnDescription LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: '$_columnRating DESC, $_columnDownloadCount DESC',
    );
    
    return results.map(_templateFromMap).toList();
  }

  /// Mark template as purchased
  Future<void> markTemplateAsPurchased(String templateId) async {
    final db = await database;
    await db.update(
      _tableName,
      {_columnIsPurchased: 1},
      where: '$_columnId = ?',
      whereArgs: [templateId],
    );
  }

  /// Check if template is cached
  Future<bool> isTemplateCached(String templateId) async {
    final db = await database;
    final results = await db.query(
      _tableName,
      columns: [_columnId],
      where: '$_columnId = ?',
      whereArgs: [templateId],
    );
    
    return results.isNotEmpty;
  }

  /// Get cache statistics
  Future<Map<String, int>> getCacheStats() async {
    final db = await database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    final purchasedResult = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE $_columnIsPurchased = 1');
    
    return {
      'totalCached': totalResult.first['count'] as int,
      'purchasedCached': purchasedResult.first['count'] as int,
    };
  }

  /// Clean old cache entries (keep only last 100 templates)
  Future<void> cleanOldCache({int maxEntries = 100}) async {
    final db = await database;
    
    // Get count of cached templates
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    final totalCount = countResult.first['count'] as int;
    
    if (totalCount <= maxEntries) return;
    
    // Keep purchased templates and most recently accessed ones
    final entriesToDelete = totalCount - maxEntries;
    
    await db.rawDelete('''
      DELETE FROM $_tableName 
      WHERE $_columnId IN (
        SELECT $_columnId FROM $_tableName 
        WHERE $_columnIsPurchased = 0 
        ORDER BY $_columnLastAccessed ASC 
        LIMIT ?
      )
    ''', [entriesToDelete]);
  }

  /// Clear all cached templates
  Future<void> clearCache() async {
    final db = await database;
    await db.delete(_tableName);
    await db.delete(_categoriesTableName);
  }

  /// Cache categories
  Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    for (final category in categories) {
      batch.insert(
        _categoriesTableName,
        {
          _catColumnId: category['id'],
          _catColumnName: category['name'],
          _catColumnSlug: category['slug'],
          _catColumnParentId: category['parentId'],
          _catColumnDescription: category['description'],
          _catColumnIcon: category['icon'],
          _catColumnOrderIndex: category['orderIndex'] ?? 0,
          _catColumnIsActive: category['isActive'] == true ? 1 : 0,
          _catColumnTemplateCount: category['templateCount'] ?? 0,
          _catColumnCachedAt: now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }

  /// Get cached categories
  Future<List<Map<String, dynamic>>> getCachedCategories() async {
    final db = await database;
    final results = await db.query(
      _categoriesTableName,
      orderBy: '$_catColumnOrderIndex ASC',
    );
    
    return results.map((row) => {
      'id': row[_catColumnId],
      'name': row[_catColumnName],
      'slug': row[_catColumnSlug],
      'parentId': row[_catColumnParentId],
      'description': row[_catColumnDescription],
      'icon': row[_catColumnIcon],
      'orderIndex': row[_catColumnOrderIndex],
      'isActive': row[_catColumnIsActive] == 1,
      'templateCount': row[_catColumnTemplateCount],
    }).toList();
  }

  /// Convert template from database map
  Template _templateFromMap(Map<String, dynamic> map) {
    return Template(
      id: map[_columnId],
      title: map[_columnTitle],
      description: map[_columnDescription],
      categoryId: map[_columnCategoryId],
      body: map[_columnBody],
      placeholders: _placeholdersFromJson(json.decode(map[_columnPlaceholders])),
      createdBy: map[_columnCreatedBy],
      price: map[_columnPrice],
      status: TemplateStatus.values.firstWhere(
        (e) => e.name == map[_columnStatus],
        orElse: () => TemplateStatus.pending,
      ),
      isVerified: map[_columnIsVerified] == 1,
      isFeatured: map[_columnIsFeatured] == 1,
      rating: map[_columnRating],
      totalRatings: map[_columnTotalRatings],
      downloadCount: map[_columnDownloadCount],
      purchaseCount: map[_columnPurchaseCount],
      version: map[_columnVersion],
      previewImageUrl: map[_columnPreviewImageUrl],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map[_columnCreatedAt]),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map[_columnUpdatedAt]),
    );
  }

  /// Convert placeholders to JSON format
  Map<String, dynamic> _placeholdersToJson(Map<String, PlaceholderConfig> placeholders) {
    return placeholders.map((key, config) => MapEntry(key, {
      'type': config.type.name,
      'label': config.label,
      'required': config.required,
      'validation': config.validation != null ? {
        'minLength': config.validation!.minLength,
        'maxLength': config.validation!.maxLength,
        'minValue': config.validation!.minValue,
        'maxValue': config.validation!.maxValue,
        'pattern': config.validation!.pattern,
      } : null,
      'defaultValue': config.defaultValue,
      'options': config.options,
      'order': config.order,
    }));
  }

  /// Convert placeholders from JSON format
  Map<String, PlaceholderConfig> _placeholdersFromJson(Map<String, dynamic> json) {
    return json.map((key, value) => MapEntry(key, PlaceholderConfig(
      type: PlaceholderType.values.firstWhere(
        (e) => e.name == value['type'],
        orElse: () => PlaceholderType.string,
      ),
      label: value['label'],
      required: value['required'] ?? false,
      validation: value['validation'] != null
          ? ValidationRules(
              minLength: value['validation']['minLength'],
              maxLength: value['validation']['maxLength'],
              minValue: value['validation']['minValue']?.toDouble(),
              maxValue: value['validation']['maxValue']?.toDouble(),
              pattern: value['validation']['pattern'],
            )
          : null,
      defaultValue: value['defaultValue'],
      options: value['options']?.cast<String>(),
      order: value['order'] ?? 0,
    )));
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}