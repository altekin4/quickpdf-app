import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Uygulama performansını izlemek için kullanılan servis
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, Stopwatch> _timers = {};
  final List<PerformanceMetric> _metrics = [];
  bool _isEnabled = kDebugMode;

  /// Performans izlemeyi etkinleştir/devre dışı bırak
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Bir işlemin süresini ölçmeye başla
  void startTimer(String name) {
    if (!_isEnabled) return;
    
    _timers[name] = Stopwatch()..start();
    developer.log('Timer started: $name', name: 'PerformanceMonitor');
  }

  /// Bir işlemin süresini ölçmeyi bitir ve kaydet
  void stopTimer(String name) {
    if (!_isEnabled) return;
    
    final timer = _timers[name];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsedMilliseconds;
      
      _metrics.add(PerformanceMetric(
        name: name,
        duration: duration,
        timestamp: DateTime.now(),
      ));
      
      developer.log(
        'Timer stopped: $name - ${duration}ms',
        name: 'PerformanceMonitor',
      );
      
      _timers.remove(name);
      
      // Uzun süren işlemler için uyarı
      if (duration > 1000) {
        developer.log(
          'WARNING: Slow operation detected: $name took ${duration}ms',
          name: 'PerformanceMonitor',
          level: 900,
        );
      }
    }
  }

  /// Bir işlemi ölç ve sonucu döndür
  Future<T> measureAsync<T>(String name, Future<T> Function() operation) async {
    if (!_isEnabled) return await operation();
    
    startTimer(name);
    try {
      final result = await operation();
      return result;
    } finally {
      stopTimer(name);
    }
  }

  /// Senkron işlemi ölç ve sonucu döndür
  T measureSync<T>(String name, T Function() operation) {
    if (!_isEnabled) return operation();
    
    startTimer(name);
    try {
      final result = operation();
      return result;
    } finally {
      stopTimer(name);
    }
  }

  /// Bellek kullanımını ölç
  Future<MemoryInfo> measureMemoryUsage() async {
    if (!_isEnabled) return const MemoryInfo(0, 0);
    
    try {
      // Platform-specific memory measurement
      const platform = MethodChannel('performance_monitor');
      final result = await platform.invokeMethod('getMemoryInfo');
      
      return MemoryInfo(
        result['used'] ?? 0,
        result['total'] ?? 0,
      );
    } catch (e) {
      developer.log('Error measuring memory: $e', name: 'PerformanceMonitor');
      return const MemoryInfo(0, 0);
    }
  }

  /// FPS ölçümü başlat
  void startFPSMonitoring() {
    if (!_isEnabled) return;
    
    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final fps = 1000 / timing.totalSpan.inMilliseconds;
        
        if (fps < 30) {
          developer.log(
            'Low FPS detected: ${fps.toStringAsFixed(1)}',
            name: 'PerformanceMonitor',
            level: 800,
          );
        }
      }
    });
  }

  /// Performans metriklerini al
  List<PerformanceMetric> getMetrics({String? name}) {
    if (name != null) {
      return _metrics.where((m) => m.name == name).toList();
    }
    return List.unmodifiable(_metrics);
  }

  /// Performans raporunu oluştur
  PerformanceReport generateReport() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    
    final recentMetrics = _metrics
        .where((m) => m.timestamp.isAfter(last24Hours))
        .toList();
    
    final groupedMetrics = <String, List<PerformanceMetric>>{};
    for (final metric in recentMetrics) {
      groupedMetrics.putIfAbsent(metric.name, () => []).add(metric);
    }
    
    final summaries = <String, MetricSummary>{};
    for (final entry in groupedMetrics.entries) {
      final durations = entry.value.map((m) => m.duration).toList();
      durations.sort();
      
      summaries[entry.key] = MetricSummary(
        name: entry.key,
        count: durations.length,
        average: durations.isEmpty ? 0 : durations.reduce((a, b) => a + b) / durations.length,
        min: durations.isEmpty ? 0 : durations.first,
        max: durations.isEmpty ? 0 : durations.last,
        median: durations.isEmpty ? 0 : durations[durations.length ~/ 2],
      );
    }
    
    return PerformanceReport(
      generatedAt: now,
      period: const Duration(hours: 24),
      summaries: summaries,
      totalMetrics: recentMetrics.length,
    );
  }

  /// Metrikleri temizle
  void clearMetrics() {
    _metrics.clear();
    developer.log('Performance metrics cleared', name: 'PerformanceMonitor');
  }

  /// Performans uyarılarını kontrol et
  List<PerformanceWarning> checkWarnings() {
    final warnings = <PerformanceWarning>[];
    final report = generateReport();
    
    for (final summary in report.summaries.values) {
      // Yavaş işlemler
      if (summary.average > 500) {
        warnings.add(PerformanceWarning(
          type: WarningType.slowOperation,
          message: '${summary.name} ortalama ${summary.average.toStringAsFixed(0)}ms sürüyor',
          severity: summary.average > 1000 ? WarningSeverity.high : WarningSeverity.medium,
        ));
      }
      
      // Tutarsız performans
      if (summary.max > summary.average * 3) {
        warnings.add(PerformanceWarning(
          type: WarningType.inconsistentPerformance,
          message: '${summary.name} tutarsız performans gösteriyor (max: ${summary.max}ms, avg: ${summary.average.toStringAsFixed(0)}ms)',
          severity: WarningSeverity.medium,
        ));
      }
    }
    
    return warnings;
  }
}

/// Performans metriği
class PerformanceMetric {
  final String name;
  final int duration;
  final DateTime timestamp;

  const PerformanceMetric({
    required this.name,
    required this.duration,
    required this.timestamp,
  });
}

/// Bellek bilgisi
class MemoryInfo {
  final int used;
  final int total;

  const MemoryInfo(this.used, this.total);

  double get usagePercentage => total > 0 ? (used / total) * 100 : 0;
}

/// Metrik özeti
class MetricSummary {
  final String name;
  final int count;
  final double average;
  final int min;
  final int max;
  final int median;

  const MetricSummary({
    required this.name,
    required this.count,
    required this.average,
    required this.min,
    required this.max,
    required this.median,
  });
}

/// Performans raporu
class PerformanceReport {
  final DateTime generatedAt;
  final Duration period;
  final Map<String, MetricSummary> summaries;
  final int totalMetrics;

  const PerformanceReport({
    required this.generatedAt,
    required this.period,
    required this.summaries,
    required this.totalMetrics,
  });
}

/// Performans uyarısı
class PerformanceWarning {
  final WarningType type;
  final String message;
  final WarningSeverity severity;

  const PerformanceWarning({
    required this.type,
    required this.message,
    required this.severity,
  });
}

enum WarningType {
  slowOperation,
  inconsistentPerformance,
  highMemoryUsage,
  lowFPS,
}

enum WarningSeverity {
  low,
  medium,
  high,
}

/// Performans izleme mixin'i
mixin PerformanceTrackingMixin {
  final PerformanceMonitor _monitor = PerformanceMonitor();

  /// Widget build süresini ölç
  Widget trackBuildPerformance(String widgetName, Widget Function() builder) {
    return _monitor.measureSync('build_$widgetName', builder);
  }

  /// Async işlem süresini ölç
  Future<T> trackAsyncOperation<T>(String operationName, Future<T> Function() operation) {
    return _monitor.measureAsync(operationName, operation);
  }

  /// Sync işlem süresini ölç
  T trackSyncOperation<T>(String operationName, T Function() operation) {
    return _monitor.measureSync(operationName, operation);
  }
}