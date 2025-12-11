import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

/// Cache optimizasyonu için kullanılan servis
class CacheOptimizer {
  static final CacheOptimizer _instance = CacheOptimizer._internal();
  factory CacheOptimizer() => _instance;
  CacheOptimizer._internal();

  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, Timer> _expirationTimers = {};
  
  static const int _maxMemoryCacheSize = 100; // Maksimum bellek cache boyutu
  static const Duration _defaultTTL = Duration(minutes: 30); // Varsayılan TTL

  /// Bellek cache'ine veri ekle
  void setMemoryCache(String key, dynamic value, {Duration? ttl}) {
    // Cache boyutu kontrolü
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      _evictOldestEntry();
    }

    final entry = CacheEntry(
      value: value,
      timestamp: DateTime.now(),
      ttl: ttl ?? _defaultTTL,
    );

    _memoryCache[key] = entry;
    _setExpirationTimer(key, entry.ttl);

    developer.log('Memory cache set: $key', name: 'CacheOptimizer');
  }

  /// Bellek cache'inden veri al
  T? getMemoryCache<T>(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return null;

    // TTL kontrolü
    if (entry.isExpired) {
      removeMemoryCache(key);
      return null;
    }

    // Access time güncelle (LRU için)
    entry.lastAccessed = DateTime.now();
    
    developer.log('Memory cache hit: $key', name: 'CacheOptimizer');
    return entry.value as T?;
  }

  /// Bellek cache'inden veri sil
  void removeMemoryCache(String key) {
    _memoryCache.remove(key);
    _expirationTimers[key]?.cancel();
    _expirationTimers.remove(key);
    
    developer.log('Memory cache removed: $key', name: 'CacheOptimizer');
  }

  /// Persistent cache'e veri kaydet
  Future<void> setPersistentCache(String key, dynamic value, {Duration? ttl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entry = PersistentCacheEntry(
        value: value,
        timestamp: DateTime.now(),
        ttl: ttl ?? _defaultTTL,
      );

      await prefs.setString('cache_$key', json.encode(entry.toJson()));
      developer.log('Persistent cache set: $key', name: 'CacheOptimizer');
    } catch (e) {
      developer.log('Error setting persistent cache: $e', name: 'CacheOptimizer');
    }
  }

  /// Persistent cache'den veri al
  Future<T?> getPersistentCache<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cache_$key');
      
      if (jsonString == null) return null;

      final entry = PersistentCacheEntry.fromJson(json.decode(jsonString));
      
      // TTL kontrolü
      if (entry.isExpired) {
        await removePersistentCache(key);
        return null;
      }

      developer.log('Persistent cache hit: $key', name: 'CacheOptimizer');
      return entry.value as T?;
    } catch (e) {
      developer.log('Error getting persistent cache: $e', name: 'CacheOptimizer');
      return null;
    }
  }

  /// Persistent cache'den veri sil
  Future<void> removePersistentCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_$key');
      developer.log('Persistent cache removed: $key', name: 'CacheOptimizer');
    } catch (e) {
      developer.log('Error removing persistent cache: $e', name: 'CacheOptimizer');
    }
  }

  /// Hibrit cache (önce memory, sonra persistent)
  Future<T?> getHybridCache<T>(String key) async {
    // Önce memory cache'e bak
    final memoryResult = getMemoryCache<T>(key);
    if (memoryResult != null) return memoryResult;

    // Memory cache'de yoksa persistent cache'e bak
    final persistentResult = await getPersistentCache<T>(key);
    if (persistentResult != null) {
      // Persistent cache'den bulduğunu memory cache'e de ekle
      setMemoryCache(key, persistentResult);
      return persistentResult;
    }

    return null;
  }

  /// Hibrit cache'e veri kaydet
  Future<void> setHybridCache(String key, dynamic value, {Duration? ttl}) async {
    setMemoryCache(key, value, ttl: ttl);
    await setPersistentCache(key, value, ttl: ttl);
  }

  /// Cache istatistiklerini al
  CacheStats getStats() {
    int expiredCount = 0;
    int totalSize = 0;

    for (final entry in _memoryCache.values) {
      if (entry.isExpired) expiredCount++;
      totalSize += _estimateSize(entry.value);
    }

    return CacheStats(
      memoryCacheSize: _memoryCache.length,
      expiredEntries: expiredCount,
      estimatedMemoryUsage: totalSize,
      hitRate: 0.0, // Bu gerçek bir uygulamada hesaplanmalı
    );
  }

  /// Süresi dolmuş cache girişlerini temizle
  void cleanupExpiredEntries() {
    final expiredKeys = <String>[];
    
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      removeMemoryCache(key);
    }

    developer.log('Cleaned up ${expiredKeys.length} expired entries', name: 'CacheOptimizer');
  }

  /// Tüm cache'i temizle
  Future<void> clearAllCache() async {
    _memoryCache.clear();
    for (final timer in _expirationTimers.values) {
      timer.cancel();
    }
    _expirationTimers.clear();

    // Persistent cache'i de temizle
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      developer.log('Error clearing persistent cache: $e', name: 'CacheOptimizer');
    }

    developer.log('All cache cleared', name: 'CacheOptimizer');
  }

  /// Cache boyutunu optimize et
  void optimizeCacheSize() {
    if (_memoryCache.length <= _maxMemoryCacheSize) return;

    // LRU algoritması ile eski girişleri sil
    final entries = _memoryCache.entries.toList();
    entries.sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));

    final toRemove = entries.take(_memoryCache.length - _maxMemoryCacheSize);
    for (final entry in toRemove) {
      removeMemoryCache(entry.key);
    }

    developer.log('Cache size optimized, removed ${toRemove.length} entries', name: 'CacheOptimizer');
  }

  /// En eski girişi sil
  void _evictOldestEntry() {
    if (_memoryCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _memoryCache.entries) {
      if (oldestTime == null || entry.value.lastAccessed.isBefore(oldestTime)) {
        oldestTime = entry.value.lastAccessed;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      removeMemoryCache(oldestKey);
    }
  }

  /// Expiration timer ayarla
  void _setExpirationTimer(String key, Duration ttl) {
    _expirationTimers[key]?.cancel();
    _expirationTimers[key] = Timer(ttl, () {
      removeMemoryCache(key);
    });
  }

  /// Veri boyutunu tahmin et
  int _estimateSize(dynamic value) {
    if (value == null) return 0;
    if (value is String) return value.length * 2; // UTF-16
    if (value is List) return value.length * 8; // Ortalama
    if (value is Map) return value.length * 16; // Ortalama
    return 8; // Varsayılan
  }

  /// Otomatik temizleme başlat
  void startAutoCleanup({Duration interval = const Duration(minutes: 10)}) {
    Timer.periodic(interval, (timer) {
      cleanupExpiredEntries();
      optimizeCacheSize();
    });
  }
}

/// Cache girişi
class CacheEntry {
  final dynamic value;
  final DateTime timestamp;
  final Duration ttl;
  DateTime lastAccessed;

  CacheEntry({
    required this.value,
    required this.timestamp,
    required this.ttl,
  }) : lastAccessed = timestamp;

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// Persistent cache girişi
class PersistentCacheEntry {
  final dynamic value;
  final DateTime timestamp;
  final Duration ttl;

  const PersistentCacheEntry({
    required this.value,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl.inMilliseconds,
    };
  }

  factory PersistentCacheEntry.fromJson(Map<String, dynamic> json) {
    return PersistentCacheEntry(
      value: json['value'],
      timestamp: DateTime.parse(json['timestamp']),
      ttl: Duration(milliseconds: json['ttl']),
    );
  }
}

/// Cache istatistikleri
class CacheStats {
  final int memoryCacheSize;
  final int expiredEntries;
  final int estimatedMemoryUsage;
  final double hitRate;

  const CacheStats({
    required this.memoryCacheSize,
    required this.expiredEntries,
    required this.estimatedMemoryUsage,
    required this.hitRate,
  });
}

/// Cache optimizasyonu mixin'i
mixin CacheOptimizationMixin {
  final CacheOptimizer _cacheOptimizer = CacheOptimizer();

  /// Cached async operation
  Future<T> cachedOperation<T>(
    String key,
    Future<T> Function() operation, {
    Duration? ttl,
    bool useHybridCache = true,
  }) async {
    // Cache'den veriyi al
    final cached = useHybridCache
        ? await _cacheOptimizer.getHybridCache<T>(key)
        : _cacheOptimizer.getMemoryCache<T>(key);

    if (cached != null) return cached;

    // Cache'de yoksa işlemi çalıştır ve sonucu cache'le
    final result = await operation();
    
    if (useHybridCache) {
      await _cacheOptimizer.setHybridCache(key, result, ttl: ttl);
    } else {
      _cacheOptimizer.setMemoryCache(key, result, ttl: ttl);
    }

    return result;
  }

  /// Cache'i temizle
  Future<void> clearCache() async {
    await _cacheOptimizer.clearAllCache();
  }

  /// Cache istatistiklerini al
  CacheStats getCacheStats() {
    return _cacheOptimizer.getStats();
  }
}