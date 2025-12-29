import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_article.dart';

class CacheService {
  static const String _cacheKey = 'cached_articles';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const String _cacheLimitKey = 'cache_limit_mb';
  static const String _preloadedArticlesKey = 'preloaded_articles';
  static const int _defaultCacheLimitMB = 50;
  static const Duration _cacheValidDuration = Duration(hours: 6);
  static const int _maxPreloadArticles = 50; // Articoli da pre-caricare

  // Salva articoli nella cache
  Future<bool> cacheArticles(List<NewsArticle> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Converti articoli in JSON
      final jsonList = articles
          .map((article) => _articleToJson(article))
          .toList();
      final jsonString = json.encode(jsonList);

      // Comprimi i dati
      final compressed = _compressData(jsonString);

      // Verifica limite storage
      final cacheLimitMB = await getCacheLimit();
      final sizeInMB = _calculateSizeInMB(compressed);

      if (sizeInMB > cacheLimitMB) {
        // Se supera il limite, rimuovi articoli più vecchi
        final limitedArticles = articles
            .take((articles.length * 0.8).round())
            .toList();
        final limitedJsonString = json.encode(
          limitedArticles.map((a) => _articleToJson(a)).toList(),
        );
        final compressedLimited = _compressData(limitedJsonString);
        await prefs.setString(_cacheKey, compressedLimited);
      } else {
        await prefs.setString(_cacheKey, compressed);
      }

      // Salva timestamp
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Recupera articoli dalla cache
  Future<List<NewsArticle>> getCachedArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final compressed = prefs.getString(_cacheKey);

      if (compressed == null || compressed.isEmpty) {
        return [];
      }

      // Decomprimi i dati
      final jsonString = _decompressData(compressed);
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => _articleFromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Controlla se la cache è valida (non troppo vecchia)
  Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      return now.difference(cacheTime) < _cacheValidDuration;
    } catch (e) {
      return false;
    }
  }

  // Ottieni dimensione cache in MB
  Future<double> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final compressed = prefs.getString(_cacheKey);

      if (compressed == null) return 0.0;

      return _calculateSizeInMB(compressed);
    } catch (e) {
      return 0.0;
    }
  }

  // Preload intelligente articoli per lettura offline
  Future<bool> preloadArticlesForOffline(List<NewsArticle> articles) async {
    try {
      // Ordina per data (più recenti prima)
      final sortedArticles = List<NewsArticle>.from(articles)
        ..sort((a, b) => b.pubDate.compareTo(a.pubDate));

      // Prendi i primi N articoli
      final articlesToPreload = sortedArticles
          .take(_maxPreloadArticles)
          .toList();

      final prefs = await SharedPreferences.getInstance();
      final jsonList = articlesToPreload.map((a) => _articleToJson(a)).toList();
      final jsonString = json.encode(jsonList);
      final compressed = _compressData(jsonString);

      await prefs.setString(_preloadedArticlesKey, compressed);
      await prefs.setInt(
        '${_preloadedArticlesKey}_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Recupera articoli precaricati
  Future<List<NewsArticle>> getPreloadedArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final compressed = prefs.getString(_preloadedArticlesKey);

      if (compressed == null || compressed.isEmpty) {
        return [];
      }

      final jsonString = _decompressData(compressed);
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => _articleFromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Comprimi dati usando gzip
  String _compressData(String data) {
    try {
      final bytes = utf8.encode(data);
      final compressed = gzip.encode(bytes);
      return base64.encode(compressed);
    } catch (e) {
      return data; // Fallback senza compressione
    }
  }

  // Decomprimi dati
  String _decompressData(String compressedData) {
    try {
      // Verifica se sembra essere un JSON non compresso (legacy)
      if (compressedData.trim().startsWith('[') ||
          compressedData.trim().startsWith('{')) {
        return compressedData; // Dati non compressi, compatibilità
      }

      final bytes = base64.decode(compressedData);
      final decompressed = gzip.decode(bytes);
      return utf8.decode(decompressed);
    } catch (e) {
      // Se fallisce, prova a leggere come non compresso (compatibilità)
      return compressedData;
    }
  }

  // Cancella la cache
  Future<bool> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Ottieni limite cache configurato
  Future<int> getCacheLimit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_cacheLimitKey) ?? _defaultCacheLimitMB;
    } catch (e) {
      return _defaultCacheLimitMB;
    }
  }

  // Imposta limite cache
  Future<bool> setCacheLimit(int limitMB) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(_cacheLimitKey, limitMB);
    } catch (e) {
      return false;
    }
  }

  // Ottieni timestamp ultima cache
  Future<DateTime?> getLastCacheTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (timestamp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }

  // Calcola dimensione stringa in MB
  double _calculateSizeInMB(String data) {
    final bytes = utf8.encode(data).length;
    return bytes / (1024 * 1024);
  }

  // Converti articolo in JSON
  Map<String, dynamic> _articleToJson(NewsArticle article) {
    return {
      'title': article.title,
      'description': article.description,
      'link': article.link,
      'imageUrl': article.imageUrl,
      'pubDate': article.pubDate.toIso8601String(),
      'source': article.source,
      'category': article.category,
    };
  }

  // Converti JSON in articolo
  NewsArticle _articleFromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      link: json['link'] ?? '',
      imageUrl: json['imageUrl'],
      pubDate: DateTime.parse(json['pubDate']),
      source: json['source'] ?? '',
      category: json['category'] ?? 'general',
    );
  }
}
