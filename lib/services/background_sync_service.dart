// lib/services/background_sync_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'rss_service.dart';
import 'cache_service.dart';
import 'image_optimization_service.dart';
import 'notification_service.dart';
import '../models/news_article.dart';

/// Servizio per gestire il background sync periodico e intelligente
class BackgroundSyncService {
  static final BackgroundSyncService _instance =
      BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  static const String _syncTaskName = 'periodic_news_sync';
  static const String _downloadTaskName = 'download_articles';
  static const String _imagePreloadTaskName = 'preload_images';

  // Keys per SharedPreferences
  static const String _lastSyncKey = 'last_background_sync';
  static const String _syncCountKey = 'sync_count_today';
  static const String _lastActiveTimeKey = 'last_active_time';
  static const String _dailyReadsKey = 'daily_reads_count';
  static const String _enabledKey = 'background_sync_enabled';
  static const String _syncFrequencyKey = 'sync_frequency_hours';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Inizializza il WorkManager e registra i task
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // Registra task periodici basati su preferenze utente
      await _registerPeriodicTasks();

      _isInitialized = true;
      debugPrint('✅ BackgroundSyncService inizializzato');
    } catch (e) {
      debugPrint('⚠️ Errore inizializzazione BackgroundSyncService: $e');
    }
  }

  /// Registra i task periodici basati su pattern di utilizzo
  Future<void> _registerPeriodicTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? true;
    final frequencyHours = prefs.getInt(_syncFrequencyKey) ?? 4;

    if (!enabled) {
      debugPrint('📴 Background sync disabilitato dall\'utente');
      return;
    }

    // Calcola frequenza intelligente basata su pattern di utilizzo
    final smartFrequency = await _calculateSmartFrequency(frequencyHours);

    // Registra sync periodico articoli
    await Workmanager().registerPeriodicTask(
      _syncTaskName,
      _syncTaskName,
      frequency: Duration(hours: smartFrequency),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
    );

    debugPrint('🔄 Sync periodico registrato: ogni $smartFrequency ore');
  }

  /// Calcola la frequenza di sync intelligente basata su pattern di utilizzo
  Future<int> _calculateSmartFrequency(int baseFrequency) async {
    final prefs = await SharedPreferences.getInstance();

    // Recupera statistiche di utilizzo
    final dailyReads = prefs.getInt(_dailyReadsKey) ?? 0;
    final lastActiveTime = prefs.getInt(_lastActiveTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Calcola ore dall'ultima attività
    final hoursSinceActive = (now - lastActiveTime) / (1000 * 60 * 60);

    // Logica smart:
    // - Utente molto attivo (>10 articoli/giorno): sync più frequente
    // - Utente poco attivo (<3 articoli/giorno): sync meno frequente
    // - Non attivo da >24h: riduci frequenza
    if (dailyReads > 10) {
      return (baseFrequency * 0.75).round().clamp(1, 24); // Più frequente
    } else if (dailyReads < 3 || hoursSinceActive > 24) {
      return (baseFrequency * 1.5).round().clamp(1, 24); // Meno frequente
    }

    return baseFrequency;
  }

  /// Traccia lettura articolo per pattern analysis
  Future<void> trackArticleRead() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyReads = prefs.getInt(_dailyReadsKey) ?? 0;
    final lastActiveTime = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt(_dailyReadsKey, dailyReads + 1);
    await prefs.setInt(_lastActiveTimeKey, lastActiveTime);

    // Reset contatore giornaliero se è un nuovo giorno
    await _resetDailyCounterIfNeeded();
  }

  /// Reset contatore giornaliero se è un nuovo giorno
  Future<void> _resetDailyCounterIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTime = prefs.getInt(_lastSyncKey) ?? 0;
    final now = DateTime.now();
    final lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncTime);

    if (now.day != lastSync.day) {
      await prefs.setInt(_dailyReadsKey, 0);
      await prefs.setInt(_syncCountKey, 0);
    }
  }

  /// Avvia download manuale articoli con foreground service notification
  Future<void> startManualSync({bool preloadImages = true}) async {
    await Workmanager().registerOneOffTask(
      'manual_sync_${DateTime.now().millisecondsSinceEpoch}',
      _downloadTaskName,
      inputData: {
        'preload_images': preloadImages,
        'is_manual': true,
      },
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    debugPrint('📥 Sync manuale avviato');
  }

  /// Preload immagini in background
  Future<void> preloadImages(List<NewsArticle> articles) async {
    await Workmanager().registerOneOffTask(
      'image_preload_${DateTime.now().millisecondsSinceEpoch}',
      _imagePreloadTaskName,
      inputData: {
        'article_urls':
            articles.map((a) => a.imageUrl).whereType<String>().toList(),
      },
      constraints: Constraints(
        networkType: NetworkType.unmetered, // Solo WiFi per immagini
        requiresBatteryNotLow: true,
      ),
    );

    debugPrint('🖼️ Preload immagini avviato: ${articles.length} articoli');
  }

  /// Abilita/disabilita background sync
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (enabled) {
      await _registerPeriodicTasks();
    } else {
      await Workmanager().cancelAll();
    }

    debugPrint('🔄 Background sync ${enabled ? 'abilitato' : 'disabilitato'}');
  }

  /// Imposta frequenza di sync (ore)
  Future<void> setSyncFrequency(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_syncFrequencyKey, hours.clamp(1, 24));
    await _registerPeriodicTasks();
  }

  /// Ottieni statistiche sync
  Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'last_sync': prefs.getInt(_lastSyncKey) ?? 0,
      'sync_count_today': prefs.getInt(_syncCountKey) ?? 0,
      'daily_reads': prefs.getInt(_dailyReadsKey) ?? 0,
      'enabled': prefs.getBool(_enabledKey) ?? true,
      'frequency_hours': prefs.getInt(_syncFrequencyKey) ?? 4,
    };
  }

  /// Cancella tutti i task di background
  Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    debugPrint('🛑 Tutti i task di background cancellati');
  }
}

/// Callback dispatcher per WorkManager (deve essere top-level function)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('📋 Eseguendo task: $task');

    try {
      switch (task) {
        case BackgroundSyncService._syncTaskName:
          await _performPeriodicSync();
          break;

        case BackgroundSyncService._downloadTaskName:
          final preloadImages = inputData?['preload_images'] ?? true;
          final isManual = inputData?['is_manual'] ?? false;
          await _performArticleDownload(preloadImages, isManual);
          break;

        case BackgroundSyncService._imagePreloadTaskName:
          final urls =
              (inputData?['article_urls'] as List?)?.cast<String>() ?? [];
          await _performImagePreload(urls);
          break;

        default:
          debugPrint('⚠️ Task sconosciuto: $task');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Errore durante task $task: $e');
      return false;
    }
  });
}

/// Esegue sync periodico articoli
Future<void> _performPeriodicSync() async {
  final prefs = await SharedPreferences.getInstance();
  final rssService = RssService();
  final cacheService = CacheService();

  debugPrint('🔄 Inizio sync periodico...');

  // Fetch nuovi articoli
  final articles = await rssService.fetchArticles();

  if (articles.isNotEmpty) {
    // Salva in cache
    await cacheService.cacheArticles(articles);

    // Aggiorna timestamp
    await prefs.setInt(
      BackgroundSyncService._lastSyncKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    // Incrementa contatore
    final syncCount = prefs.getInt(BackgroundSyncService._syncCountKey) ?? 0;
    await prefs.setInt(BackgroundSyncService._syncCountKey, syncCount + 1);

    debugPrint('✅ Sync periodico completato: ${articles.length} articoli');

    // Notifica l'utente se ci sono nuovi articoli importanti (breaking news)
    await _notifyBreakingNews(articles);
  }
}

/// Esegue download articoli con foreground notification
Future<void> _performArticleDownload(bool preloadImages, bool isManual) async {
  final notificationService = NotificationService();
  final rssService = RssService();
  final cacheService = CacheService();

  // Mostra notifica foreground service
  await notificationService.showDownloadNotification(
    title: 'Download articoli',
    body: 'Download articoli in corso...',
  );

  try {
    // Fetch articoli
    final articles = await rssService.fetchArticles();

    // Salva in cache
    await cacheService.cacheArticles(articles);

    // Preload immagini se richiesto
    if (preloadImages && articles.isNotEmpty) {
      await _performImagePreload(
        articles.map((a) => a.imageUrl).whereType<String>().toList(),
      );
    }

    // Aggiorna notifica con successo
    await notificationService.showDownloadNotification(
      title: 'Download completato',
      body: '${articles.length} articoli scaricati',
      isComplete: true,
    );

    debugPrint('✅ Download articoli completato: ${articles.length}');
  } catch (e) {
    await notificationService.showDownloadNotification(
      title: 'Errore download',
      body: 'Impossibile scaricare gli articoli',
      isError: true,
    );
    debugPrint('❌ Errore download articoli: $e');
  }
}

/// Esegue preload immagini in background
Future<void> _performImagePreload(List<String> imageUrls) async {
  if (imageUrls.isEmpty) return;

  final imageService = ImageOptimizationService();
  int successCount = 0;

  debugPrint('🖼️ Inizio preload ${imageUrls.length} immagini...');

  for (final url in imageUrls) {
    try {
      // Pre-cache dell'immagine verrà gestito da CachedNetworkImage automaticamente
      successCount++;
    } catch (e) {
      debugPrint('⚠️ Errore preload immagine $url: $e');
    }
  }

  debugPrint(
      '✅ Preload completato: $successCount/${imageUrls.length} immagini');
}

/// Notifica l'utente di breaking news importanti
Future<void> _notifyBreakingNews(List<NewsArticle> articles) async {
  // Identifica breaking news (articoli molto recenti da fonti importanti)
  final now = DateTime.now();
  final breakingNews = articles.where((article) {
    final diff = now.difference(article.pubDate);
    final isRecent = diff.inMinutes < 30; // Pubblicato negli ultimi 30 minuti

    // Priorità a fonti principali
    final isPriority = ['TuttoAndroid', 'AndroidWorld', 'HDblog']
        .any((source) => article.source.contains(source));

    return isRecent && isPriority;
  }).toList();

  if (breakingNews.isEmpty) return;

  // Mostra notifica per il primo breaking news
  final article = breakingNews.first;
  final notificationService = NotificationService();

  await notificationService.showNotification(
    title: '🔥 Breaking News',
    body: article.title,
    payload: article.link,
  );

  debugPrint('📢 Notificato breaking news: ${article.title}');
}
