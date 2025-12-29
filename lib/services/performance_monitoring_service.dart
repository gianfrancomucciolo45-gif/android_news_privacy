import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Service per monitorare la memoria e le performance dell'app
/// Supporta DevTools integration per memory profiling
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance =
      PerformanceMonitoringService._internal();

  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  Timer? _memoryMonitorTimer;
  final List<MemorySnapshot> _memorySnapshots = [];
  static const int maxSnapshots = 100;
  static const Duration memoryCheckInterval = Duration(seconds: 30);

  /// Avvia il monitoraggio della memoria
  void startMemoryMonitoring() {
    if (_memoryMonitorTimer != null) return;

    _memoryMonitorTimer = Timer.periodic(memoryCheckInterval, (_) async {
      final snapshot = MemorySnapshot(
        timestamp: DateTime.now(),
        heapUsageMB: _estimateHeapUsage(),
      );

      _memorySnapshots.add(snapshot);

      // Mantieni solo gli ultimi 100 snapshot
      if (_memorySnapshots.length > maxSnapshots) {
        _memorySnapshots.removeAt(0);
      }

      // Log memory trend
      _checkForMemoryLeaks();
    });
  }

  /// Ferma il monitoraggio della memoria
  void stopMemoryMonitoring() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
  }

  /// Verifica per possibili memory leak analizzando i trend
  void _checkForMemoryLeaks() {
    if (_memorySnapshots.length < 5) return;

    // Prendi gli ultimi 5 snapshot
    final recentSnapshots = _memorySnapshots.sublist(
      _memorySnapshots.length - 5,
    );

    // Calcola il trend (crescita media)
    double trend = 0;
    for (int i = 1; i < recentSnapshots.length; i++) {
      trend += recentSnapshots[i].heapUsageMB -
          recentSnapshots[i - 1].heapUsageMB;
    }
    trend /= (recentSnapshots.length - 1);

    // Se la memoria cresce costantemente di >5MB per ciclo, segnala
    if (trend > 5.0 && !kDebugMode) {
      developer.log(
        'MEMORY WARNING: Possibile memory leak - crescita media: ${trend.toStringAsFixed(2)}MB per ciclo',
        name: 'PerformanceMonitoring',
        level: 900,
      );
    }
  }

  /// Stima l'uso della memoria heap (approssimativo)
  double _estimateHeapUsage() {
    // Implementazione semplificata
    // In un'app reale, useremmo native code per memoria precisa
    return 0.0; // Placeholder
  }

  /// Ritorna storico delle misurazioni di memoria
  List<MemorySnapshot> getMemoryHistory() => List.from(_memorySnapshots);

  /// Resetta lo storico della memoria
  void clearMemoryHistory() => _memorySnapshots.clear();

  /// Ritorna il picco massimo di memoria registrato
  double? getMaxMemoryUsage() {
    if (_memorySnapshots.isEmpty) return null;
    return _memorySnapshots
        .map((s) => s.heapUsageMB)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Misura il tempo di esecuzione di un'operazione
  Future<T> measurePerformance<T>(
    Future<T> Function() operation, {
    String? label,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();

      final duration = stopwatch.elapsedMilliseconds;
      developer.log(
        'Performance: ${label ?? 'Operation'} took ${duration}ms',
        name: 'PerformanceMonitoring',
      );

      return result;
    } catch (e) {
      stopwatch.stop();
      developer.log(
        'Performance: ${label ?? 'Operation'} failed after ${stopwatch.elapsedMilliseconds}ms - $e',
        name: 'PerformanceMonitoring',
        level: 900,
      );
      rethrow;
    }
  }

  /// Timeline marker per DevTools
  void mark(String name) {
    developer.Timeline.instantSync(name);
  }

  /// Inizio di una sezione timeline
  void beginBlock(String name) {
    developer.Timeline.startSync(name);
  }

  /// Fine di una sezione timeline
  void endBlock() {
    developer.Timeline.finishSync();
  }
}

/// Snapshot della memoria in un dato momento
class MemorySnapshot {
  final DateTime timestamp;
  final double heapUsageMB;

  MemorySnapshot({
    required this.timestamp,
    required this.heapUsageMB,
  });

  @override
  String toString() =>
      'MemorySnapshot($timestamp: ${heapUsageMB.toStringAsFixed(2)}MB)';
}
