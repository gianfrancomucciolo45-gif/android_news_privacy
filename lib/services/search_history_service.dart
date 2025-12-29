import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchHistoryService {
  static final SearchHistoryService _instance = SearchHistoryService._internal();
  factory SearchHistoryService() => _instance;
  SearchHistoryService._internal();

  static const String _historyKey = 'search_history';
  static const int _maxHistorySize = 20;
  
  SharedPreferences? _prefs;
  List<String> _history = [];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final historyJson = _prefs?.getString(_historyKey);
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _history = decoded.cast<String>();
      } catch (e) {
        _history = [];
      }
    }
  }

  Future<void> _saveHistory() async {
    await _prefs?.setString(_historyKey, jsonEncode(_history));
  }

  // Aggiungi termine alla cronologia
  Future<void> addSearchTerm(String term) async {
    if (term.trim().isEmpty) return;
    
    final trimmedTerm = term.trim();
    
    // Rimuovi se già esiste (per spostarlo in cima)
    _history.remove(trimmedTerm);
    
    // Aggiungi all'inizio
    _history.insert(0, trimmedTerm);
    
    // Mantieni solo gli ultimi N termini
    if (_history.length > _maxHistorySize) {
      _history = _history.sublist(0, _maxHistorySize);
    }
    
    await _saveHistory();
  }

  // Ottieni cronologia
  List<String> getHistory() {
    return List.unmodifiable(_history);
  }

  // Rimuovi singolo termine
  Future<void> removeSearchTerm(String term) async {
    _history.remove(term);
    await _saveHistory();
  }

  // Cancella tutta la cronologia
  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
  }

  // Cerca suggerimenti dalla cronologia
  List<String> getSuggestions(String query) {
    if (query.trim().isEmpty) {
      return _history.take(5).toList();
    }
    
    final lowerQuery = query.toLowerCase();
    return _history
        .where((term) => term.toLowerCase().contains(lowerQuery))
        .take(5)
        .toList();
  }

  // Cerca suggerimenti da titoli articoli
  List<String> getSuggestionsFromTitles(String query, List<String> titles) {
    if (query.trim().isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    final words = <String>{};
    
    for (final title in titles) {
      final titleWords = title.toLowerCase().split(' ');
      for (final word in titleWords) {
        if (word.contains(lowerQuery) && word.length > 2) {
          words.add(word);
        }
      }
    }
    
    return words.take(5).toList();
  }
}
