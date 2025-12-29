// test/services/background_sync_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_news/services/background_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackgroundSyncService Tests', () {
    late BackgroundSyncService syncService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      syncService = BackgroundSyncService();
    });

    test('Initialize service successfully', () async {
      await syncService.initialize();
      expect(syncService.isInitialized, isTrue);
    });

    test('Track article read updates daily counter', () async {
      await syncService.initialize();
      
      // Simula lettura di 3 articoli
      await syncService.trackArticleRead();
      await syncService.trackArticleRead();
      await syncService.trackArticleRead();
      
      final stats = await syncService.getStats();
      expect(stats['daily_reads'], equals(3));
    });

    test('Get stats returns correct structure', () async {
      await syncService.initialize();
      
      final stats = await syncService.getStats();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('last_sync'), isTrue);
      expect(stats.containsKey('sync_count_today'), isTrue);
      expect(stats.containsKey('daily_reads'), isTrue);
      expect(stats.containsKey('enabled'), isTrue);
      expect(stats.containsKey('frequency_hours'), isTrue);
    });

    test('Set sync frequency within valid range', () async {
      await syncService.initialize();
      
      await syncService.setSyncFrequency(6);
      
      final stats = await syncService.getStats();
      expect(stats['frequency_hours'], equals(6));
    });

    test('Disable sync updates preferences', () async {
      await syncService.initialize();
      
      await syncService.setEnabled(false);
      
      final stats = await syncService.getStats();
      expect(stats['enabled'], isFalse);
    });

    test('Enable sync updates preferences', () async {
      await syncService.initialize();
      
      await syncService.setEnabled(true);
      
      final stats = await syncService.getStats();
      expect(stats['enabled'], isTrue);
    });

    test('Sync frequency clamped to valid range', () async {
      await syncService.initialize();
      
      // Test limite minimo (< 1)
      await syncService.setSyncFrequency(0);
      var stats = await syncService.getStats();
      expect(stats['frequency_hours'], greaterThanOrEqualTo(1));
      
      // Test limite massimo (> 24)
      await syncService.setSyncFrequency(30);
      stats = await syncService.getStats();
      expect(stats['frequency_hours'], lessThanOrEqualTo(24));
    });

    test('Default values are correct', () async {
      await syncService.initialize();
      
      final stats = await syncService.getStats();
      
      expect(stats['enabled'], isTrue); // Default enabled
      expect(stats['frequency_hours'], equals(4)); // Default 4 hours
      expect(stats['daily_reads'], equals(0)); // No reads initially
      expect(stats['sync_count_today'], equals(0)); // No syncs initially
    });
  });
}
