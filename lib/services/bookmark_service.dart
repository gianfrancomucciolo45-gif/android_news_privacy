import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_article.dart';
import '../models/bookmark_group.dart';

// Risultato operazione di import
class ImportResult {
  final int imported;
  final int skipped;
  final List<String> errors;

  ImportResult({
    required this.imported,
    required this.skipped,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => imported > 0;
}

class BookmarkService {
  // Singleton pattern
  static final BookmarkService _instance = BookmarkService._internal();
  factory BookmarkService() => _instance;
  BookmarkService._internal();

  static const String _bookmarksKey = 'bookmarked_articles';
  static const String _groupsKey = 'bookmark_groups';

  // ValueNotifier per aggiornamenti real-time del contatore
  final ValueNotifier<int> bookmarkCountNotifier = ValueNotifier<int>(0);

  // Salva un articolo nei preferiti
  Future<bool> bookmarkArticle(NewsArticle article) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = await getBookmarkedArticles();

      // Evita duplicati
      if (!bookmarks.any((a) => a.link == article.link)) {
        bookmarks.add(article);
        final jsonList = bookmarks.map((a) => _articleToJson(a)).toList();
        final result = await prefs.setString(
          _bookmarksKey,
          json.encode(jsonList),
        );
        if (result) {
          bookmarkCountNotifier.value = bookmarks.length;
        }
        return result;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Rimuove un articolo dai preferiti
  Future<bool> unbookmarkArticle(String articleLink) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = await getBookmarkedArticles();

      bookmarks.removeWhere((a) => a.link == articleLink);
      final jsonList = bookmarks.map((a) => _articleToJson(a)).toList();
      final result = await prefs.setString(
        _bookmarksKey,
        json.encode(jsonList),
      );
      if (result) {
        bookmarkCountNotifier.value = bookmarks.length;
      }
      return result;
    } catch (e) {
      return false;
    }
  }

  // Controlla se un articolo è nei preferiti
  Future<bool> isBookmarked(String articleLink) async {
    final bookmarks = await getBookmarkedArticles();
    return bookmarks.any((a) => a.link == articleLink);
  }

  // Ottiene tutti gli articoli salvati
  Future<List<NewsArticle>> getBookmarkedArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_bookmarksKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => _articleFromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Conta articoli salvati
  Future<int> getBookmarkCount() async {
    final bookmarks = await getBookmarkedArticles();
    return bookmarks.length;
  }

  // Cancella tutti i preferiti
  Future<bool> clearAllBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.remove(_bookmarksKey);
      if (result) {
        bookmarkCountNotifier.value = 0;
      }
      return result;
    } catch (e) {
      return false;
    }
  }

  // Inizializza il contatore al primo caricamento
  Future<void> initializeCount() async {
    final count = await getBookmarkCount();
    bookmarkCountNotifier.value = count;
  }

  // Export preferiti in formato JSON
  Future<String> exportBookmarksAsJson() async {
    final bookmarks = await getBookmarkedArticles();
    final jsonList = bookmarks.map((a) => _articleToJson(a)).toList();
    return json.encode(jsonList);
  }

  // Export preferiti in formato CSV
  Future<String> exportBookmarksAsCsv() async {
    final bookmarks = await getBookmarkedArticles();

    // Header CSV
    final buffer = StringBuffer();
    buffer.writeln('Titolo;Descrizione;Link;Immagine;Data;Fonte;Categoria');

    // Dati
    for (final article in bookmarks) {
      final title = _escapeCsvField(article.title);
      final description = _escapeCsvField(article.description);
      final link = _escapeCsvField(article.link);
      final imageUrl = _escapeCsvField(article.imageUrl ?? '');
      final pubDate = article.pubDate.toIso8601String();
      final source = _escapeCsvField(article.source);
      final category = _escapeCsvField(article.category);

      buffer.writeln(
        '$title;$description;$link;$imageUrl;$pubDate;$source;$category',
      );
    }

    return buffer.toString();
  }

  // Escape caratteri speciali per CSV
  String _escapeCsvField(String field) {
    // Rimuovi newlines e ritorna caratteri
    final cleaned = field.replaceAll('\n', ' ').replaceAll('\r', ' ');
    // Se contiene ; o " aggiungi quotes
    if (cleaned.contains(';') || cleaned.contains('"')) {
      return '"${cleaned.replaceAll('"', '""')}"';
    }
    return cleaned;
  }

  // Import preferiti da JSON con validazione e merge
  Future<ImportResult> importBookmarksFromJson(String jsonString) async {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      final existingBookmarks = await getBookmarkedArticles();
      final existingLinks = existingBookmarks.map((a) => a.link).toSet();

      int imported = 0;
      int skipped = 0;
      final List<String> errors = [];

      for (var i = 0; i < jsonList.length; i++) {
        try {
          final item = jsonList[i];

          // Validazione schema
          if (item is! Map<String, dynamic>) {
            errors.add('Elemento $i non è un oggetto JSON valido');
            skipped++;
            continue;
          }

          // Campi obbligatori
          if (!item.containsKey('title') ||
              !item.containsKey('link') ||
              !item.containsKey('pubDate')) {
            errors.add(
              'Elemento $i manca di campi obbligatori (title, link, pubDate)',
            );
            skipped++;
            continue;
          }

          final article = _articleFromJson(item);

          // Evita duplicati per link
          if (existingLinks.contains(article.link)) {
            skipped++;
            continue;
          }

          existingBookmarks.add(article);
          existingLinks.add(article.link);
          imported++;
        } catch (e) {
          errors.add('Errore elemento $i: $e');
          skipped++;
        }
      }

      // Salva se ci sono articoli importati
      if (imported > 0) {
        final prefs = await SharedPreferences.getInstance();
        final jsonListToSave = existingBookmarks
            .map((a) => _articleToJson(a))
            .toList();
        await prefs.setString(_bookmarksKey, json.encode(jsonListToSave));
        bookmarkCountNotifier.value = existingBookmarks.length;
      }

      return ImportResult(imported: imported, skipped: skipped, errors: errors);
    } catch (e) {
      return ImportResult(
        imported: 0,
        skipped: 0,
        errors: ['Errore generale durante import: $e'],
      );
    }
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

  // ===== GESTIONE GRUPPI/TAG =====

  // Ottieni tutti i gruppi
  Future<List<BookmarkGroup>> getGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_groupsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => BookmarkGroup.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Salva lista gruppi
  Future<bool> _saveGroups(List<BookmarkGroup> groups) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = groups.map((g) => g.toJson()).toList();
      return await prefs.setString(_groupsKey, json.encode(jsonList));
    } catch (e) {
      return false;
    }
  }

  // Crea nuovo gruppo
  Future<BookmarkGroup?> createGroup(String name) async {
    try {
      final groups = await getGroups();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newGroup = BookmarkGroup(id: id, name: name);

      groups.add(newGroup);
      final success = await _saveGroups(groups);

      return success ? newGroup : null;
    } catch (e) {
      return null;
    }
  }

  // Rinomina gruppo
  Future<bool> renameGroup(String groupId, String newName) async {
    try {
      final groups = await getGroups();
      final index = groups.indexWhere((g) => g.id == groupId);

      if (index == -1) return false;

      groups[index] = groups[index].copyWith(name: newName);
      return await _saveGroups(groups);
    } catch (e) {
      return false;
    }
  }

  // Elimina gruppo
  Future<bool> deleteGroup(String groupId) async {
    try {
      final groups = await getGroups();
      groups.removeWhere((g) => g.id == groupId);
      return await _saveGroups(groups);
    } catch (e) {
      return false;
    }
  }

  // Aggiungi articolo a gruppo
  Future<bool> addArticleToGroup(String groupId, String articleLink) async {
    try {
      final groups = await getGroups();
      final index = groups.indexWhere((g) => g.id == groupId);

      if (index == -1) return false;

      final articleLinks = groups[index].articleLinks;
      if (!articleLinks.contains(articleLink)) {
        articleLinks.add(articleLink);
        groups[index] = groups[index].copyWith(articleLinks: articleLinks);
        return await _saveGroups(groups);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Rimuovi articolo da gruppo
  Future<bool> removeArticleFromGroup(
    String groupId,
    String articleLink,
  ) async {
    try {
      final groups = await getGroups();
      final index = groups.indexWhere((g) => g.id == groupId);

      if (index == -1) return false;

      final articleLinks = groups[index].articleLinks;
      articleLinks.remove(articleLink);
      groups[index] = groups[index].copyWith(articleLinks: articleLinks);

      return await _saveGroups(groups);
    } catch (e) {
      return false;
    }
  }

  // Ottieni articoli di un gruppo
  Future<List<NewsArticle>> getArticlesByGroup(String groupId) async {
    try {
      final groups = await getGroups();
      final group = groups.firstWhere((g) => g.id == groupId);
      final allBookmarks = await getBookmarkedArticles();

      return allBookmarks
          .where((article) => group.articleLinks.contains(article.link))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Ottieni gruppi di un articolo
  Future<List<BookmarkGroup>> getGroupsForArticle(String articleLink) async {
    try {
      final groups = await getGroups();
      return groups
          .where((group) => group.articleLinks.contains(articleLink))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
