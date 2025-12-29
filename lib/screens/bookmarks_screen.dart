import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'dart:convert';
import '../models/news_article.dart';
import '../services/bookmark_service.dart';
import '../widgets/highlighted_text.dart';
import 'article_detail_screen.dart';
import 'bookmark_groups_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

enum BookmarkSortType { dateAdded, source, titleAZ, titleZA }

class _BookmarksScreenState extends State<BookmarksScreen>
    with AutomaticKeepAliveClientMixin {
  final BookmarkService _bookmarkService = BookmarkService();
  List<NewsArticle> _bookmarkedArticles = [];
  List<NewsArticle> _filteredArticles = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  BookmarkSortType _sortType = BookmarkSortType.dateAdded;
  final TextEditingController _searchController = TextEditingController();

  // Selezione multipla
  bool _isSelectionMode = false;
  final Set<String> _selectedArticleLinks = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    final bookmarks = await _bookmarkService.getBookmarkedArticles();
    if (mounted) {
      setState(() {
        _bookmarkedArticles = bookmarks;
        _applyFiltersAndSort();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFiltersAndSort();
    });
  }

  void _applyFiltersAndSort() {
    // Filtra
    if (_searchQuery.isEmpty) {
      _filteredArticles = List.from(_bookmarkedArticles);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredArticles = _bookmarkedArticles.where((article) {
        return article.title.toLowerCase().contains(query) ||
            article.description.toLowerCase().contains(query) ||
            article.source.toLowerCase().contains(query);
      }).toList();
    }

    // Ordina
    switch (_sortType) {
      case BookmarkSortType.dateAdded:
        // Mantieni ordine originale (più recenti prima in genere)
        break;
      case BookmarkSortType.source:
        _filteredArticles.sort((a, b) => a.source.compareTo(b.source));
        break;
      case BookmarkSortType.titleAZ:
        _filteredArticles.sort((a, b) => a.title.compareTo(b.title));
        break;
      case BookmarkSortType.titleZA:
        _filteredArticles.sort((a, b) => b.title.compareTo(a.title));
        break;
    }
  }

  void _changeSortType(BookmarkSortType newType) {
    setState(() {
      _sortType = newType;
      _applyFiltersAndSort();
    });
  }

  void _toggleSelectionMode() {
    // Haptic feedback per modalità selezione
    HapticFeedback.lightImpact();

    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedArticleLinks.clear();
      }
    });
  }

  void _toggleArticleSelection(String articleLink) {
    // Haptic feedback leggero per selezione singola
    HapticFeedback.lightImpact();

    setState(() {
      if (_selectedArticleLinks.contains(articleLink)) {
        _selectedArticleLinks.remove(articleLink);
      } else {
        _selectedArticleLinks.add(articleLink);
      }
    });
  }

  void _selectAll() {
    // Haptic feedback per selezione massiva
    HapticFeedback.mediumImpact();

    setState(() {
      _selectedArticleLinks.clear();
      _selectedArticleLinks.addAll(_filteredArticles.map((a) => a.link));
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedArticleLinks.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rimuovi selezionati'),
        content: Text(
          'Vuoi rimuovere ${_selectedArticleLinks.length} articoli dai preferiti?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      // Haptic feedback per conferma eliminazione
      await HapticFeedback.heavyImpact();

      for (final link in _selectedArticleLinks) {
        await _bookmarkService.unbookmarkArticle(link);
      }

      setState(() {
        _selectedArticleLinks.clear();
        _isSelectionMode = false;
      });

      await _loadBookmarks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Articoli rimossi'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _exportSelected() async {
    if (_selectedArticleLinks.isEmpty) return;

    try {
      final selectedArticles = _bookmarkedArticles
          .where((a) => _selectedArticleLinks.contains(a.link))
          .toList();

      // Crea JSON temporaneo
      final jsonList = selectedArticles.map((a) {
        return {
          'title': a.title,
          'description': a.description,
          'link': a.link,
          'imageUrl': a.imageUrl,
          'pubDate': a.pubDate.toIso8601String(),
          'source': a.source,
          'category': a.category,
        };
      }).toList();

      final jsonString = json.encode(jsonList);

      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/selected_bookmarks_$timestamp.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: '${_selectedArticleLinks.length} articoli selezionati');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedArticleLinks.length} articoli esportati'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeBookmark(NewsArticle article) async {
    await _bookmarkService.unbookmarkArticle(article.link);
    _loadBookmarks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Articolo rimosso dai preferiti'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearAllBookmarks() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rimuovi tutti i preferiti'),
        content: const Text(
          'Sei sicuro di voler rimuovere tutti gli articoli salvati? Questa azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rimuovi tutto'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      await _bookmarkService.clearAllBookmarks();
      _loadBookmarks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tutti i preferiti sono stati rimossi'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _exportAsJson() async {
    try {
      final jsonString = await _bookmarkService.exportBookmarksAsJson();

      // Crea file temporaneo
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/bookmarks_$timestamp.json');
      await file.writeAsString(jsonString);

      // Condividi usando share_plus
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'I miei preferiti Android News');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferiti esportati in JSON'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportAsCsv() async {
    try {
      final csvString = await _bookmarkService.exportBookmarksAsCsv();

      // Crea file temporaneo
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/bookmarks_$timestamp.csv');
      await file.writeAsString(csvString);

      // Condividi usando share_plus
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'I miei preferiti Android News');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferiti esportati in CSV'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importBookmarks() async {
    try {
      // Seleziona file JSON
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();

      // Mostra loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Import
      final importResult = await _bookmarkService.importBookmarksFromJson(
        jsonString,
      );

      // Chiudi loading
      if (mounted) Navigator.pop(context);

      // Ricarica lista
      await _loadBookmarks();

      // Mostra risultato
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import completato'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✓ Importati: ${importResult.imported}'),
                Text('⊘ Saltati (duplicati): ${importResult.skipped}'),
                if (importResult.hasErrors) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Errori:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...importResult.errors
                      .take(3)
                      .map(
                        (e) =>
                            Text('• $e', style: const TextStyle(fontSize: 12)),
                      ),
                  if (importResult.errors.length > 3)
                    Text(
                      '... e altri ${importResult.errors.length - 3} errori',
                    ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Chiudi loading se aperto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante import: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToGroups() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BookmarkGroupsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm', 'it_IT');

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        title: _isSelectionMode
            ? Text('${_selectedArticleLinks.length} selezionati')
            : _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: Theme.of(context).textTheme.titleMedium,
                decoration: InputDecoration(
                  hintText: 'Cerca nei preferiti...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _isSearching = false;
                      });
                    },
                  ),
                ),
              )
            : const Text('Articoli Salvati'),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
              tooltip: 'Seleziona tutto',
            ),
          if (_bookmarkedArticles.isNotEmpty &&
              !_isSearching &&
              !_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: 'Seleziona',
            ),
          if (_bookmarkedArticles.isNotEmpty &&
              !_isSearching &&
              !_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
              tooltip: 'Cerca',
            ),
          if (_bookmarkedArticles.isNotEmpty &&
              !_isSearching &&
              !_isSelectionMode)
            PopupMenuButton<BookmarkSortType>(
              icon: const Icon(Icons.sort),
              tooltip: 'Ordina',
              onSelected: _changeSortType,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: BookmarkSortType.dateAdded,
                  child: Text('Data aggiunta'),
                ),
                const PopupMenuItem(
                  value: BookmarkSortType.source,
                  child: Text('Fonte'),
                ),
                const PopupMenuItem(
                  value: BookmarkSortType.titleAZ,
                  child: Text('Titolo A → Z'),
                ),
                const PopupMenuItem(
                  value: BookmarkSortType.titleZA,
                  child: Text('Titolo Z → A'),
                ),
              ],
            ),
          if (_bookmarkedArticles.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Opzioni',
              onSelected: (value) {
                switch (value) {
                  case 'export_json':
                    _exportAsJson();
                    break;
                  case 'export_csv':
                    _exportAsCsv();
                    break;
                  case 'import':
                    _importBookmarks();
                    break;
                  case 'manage_groups':
                    _navigateToGroups();
                    break;
                  case 'clear_all':
                    _clearAllBookmarks();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export_json',
                  child: Row(
                    children: [
                      Icon(Icons.upload_file),
                      SizedBox(width: 12),
                      Text('Esporta JSON'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_csv',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart),
                      SizedBox(width: 12),
                      Text('Esporta CSV'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.file_download),
                      SizedBox(width: 12),
                      Text('Importa JSON'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'manage_groups',
                  child: Row(
                    children: [
                      Icon(Icons.folder),
                      SizedBox(width: 12),
                      Text('Gestisci gruppi'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red),
                      SizedBox(width: 12),
                      Text(
                        'Rimuovi tutti',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarkedArticles.isEmpty
          ? _buildEmptyState(colorScheme)
          : _filteredArticles.isEmpty
          ? _buildNoResultsState(colorScheme)
          : _buildBookmarksList(colorScheme, dateFormat),
      bottomNavigationBar: _isSelectionMode && _selectedArticleLinks.isNotEmpty
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: _exportSelected,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Esporta'),
                  ),
                  TextButton.icon(
                    onPressed: _deleteSelected,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Elimina',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildNoResultsState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Lottie.asset(
                'assets/animations/no_search_results.json',
                repeat: true,
                animate: true,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun risultato',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prova con altri termini di ricerca',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                'assets/animations/empty_bookmarks.json',
                repeat: true,
                animate: true,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nessun articolo salvato',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Salva i tuoi articoli preferiti per leggerli in seguito',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksList(ColorScheme colorScheme, DateFormat dateFormat) {
    return RefreshIndicator(
      onRefresh: _loadBookmarks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredArticles.length,
        itemBuilder: (context, index) {
          final article = _filteredArticles[index];
          return Dismissible(
            key: Key(article.link),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 16),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 32),
            ),
            onDismissed: _isSelectionMode
                ? null
                : (_) => _removeBookmark(article),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color:
                      _isSelectionMode &&
                          _selectedArticleLinks.contains(article.link)
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width:
                      _isSelectionMode &&
                          _selectedArticleLinks.contains(article.link)
                      ? 2
                      : 1,
                ),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleArticleSelection(article.link);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(
                          article: article,
                          allArticles: _bookmarkedArticles,
                          currentIndex: index,
                        ),
                      ),
                    ).then((_) => _loadBookmarks());
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Immagine
                    if (article.imageUrl?.isNotEmpty ?? false)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Hero(
                          tag: 'article_image_${article.link}',
                          child: CachedNetworkImage(
                            imageUrl: article.imageUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Contenuto
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge sorgente e checkbox
                          Row(
                            children: [
                              if (_isSelectionMode)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Checkbox(
                                    value: _selectedArticleLinks.contains(
                                      article.link,
                                    ),
                                    onChanged: (_) =>
                                        _toggleArticleSelection(article.link),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  article.source,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.bookmark,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Titolo (con highlighting se c'è ricerca)
                          _searchQuery.isNotEmpty
                              ? HighlightedText(
                                  text: _cleanHtml(article.title),
                                  query: _searchQuery,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        height: 1.3,
                                      ),
                                  maxLines: 3,
                                )
                              : Text(
                                  _cleanHtml(article.title),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        height: 1.3,
                                      ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),

                          const SizedBox(height: 8),

                          // Data
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateFormat.format(article.pubDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _cleanHtml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&ndash;', '–')
        .replaceAll('&mdash;', '—')
        .replaceAll('&hellip;', '…')
        .replaceAll('&euro;', '€')
        .replaceAll('&pound;', '£')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®')
        .replaceAll('&trade;', '™');
  }
}
