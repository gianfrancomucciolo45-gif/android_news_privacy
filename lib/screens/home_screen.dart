import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../models/news_article.dart';
import '../services/rss_service.dart';
import '../services/bookmark_service.dart';
import '../services/cache_service.dart';
import '../services/network_service.dart';
import '../services/search_history_service.dart';
import '../services/subscription_service.dart';
import '../services/ads_service.dart';
import '../utils/page_transitions.dart';
import '../widgets/highlighted_text.dart';
import '../widgets/premium_paywall_widget.dart';
import 'bookmarks_screen.dart';
import 'settings_screen.dart';
import '../services/settings_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final RssService _rssService = RssService();
  final CacheService _cacheService = CacheService();
  final NetworkService _networkService = NetworkService();
  final BookmarkService _bookmarkService = BookmarkService();
  final SearchHistoryService _searchHistory = SearchHistoryService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<NewsArticle> _articles = [];
  List<NewsArticle> _filteredArticles = [];
  List<String> _searchSuggestions = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isOnline = true;
  final SettingsService _settings = SettingsService();
  StreamSubscription<bool>? _connectionSubscription;
  String _currentSearchQuery = '';
  late ScrollController _scrollController;
  static const int _itemsPerPage = 20;
  int _loadedItemsCount = _itemsPerPage;
  bool _isLoadingMore = false;
  int _articlesReadCount = 0; // Traccia articoli letti per paywall
  static const int _articlesBeforePaywall = 3; // Mostra paywall ogni 3 articoli

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScrollListener);
    _searchHistory.init();
    _bookmarkService.initializeCount();
    _searchController.addListener(_onSearchChanged);
    _networkService.initialize();
    _isOnline = _networkService.isOnline;
    _connectionSubscription = _networkService.connectionStream.listen((
      isOnline,
    ) {
      setState(() {
        _isOnline = isOnline;
      });
      if (isOnline && _articles.isEmpty) {
        _loadArticles();
      }
    });
    _loadArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  void _onScrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreArticles();
    }
  }

  void _loadMoreArticles() {
    if (_isLoadingMore ||
        _loadedItemsCount >= _filteredArticles.length ||
        _isSearching) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
      _loadedItemsCount = (_loadedItemsCount + _itemsPerPage)
          .clamp(0, _filteredArticles.length);
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    });
  }

  void _onSearchChanged() {
    setState(() {
      _currentSearchQuery = _searchController.text;
      _loadedItemsCount = _itemsPerPage; // Reset pagination on search

      if (_searchController.text.isEmpty) {
        _filteredArticles = _articles;
        _searchSuggestions = _searchHistory.getHistory();
      } else {
        final query = _searchController.text.toLowerCase();

        // Filtra articoli
        _filteredArticles = _articles.where((article) {
          return article.title.toLowerCase().contains(query) ||
              article.description.toLowerCase().contains(query);
        }).toList();

        // Genera suggerimenti da cronologia e titoli
        final historySuggestions = _searchHistory.getSuggestions(query);
        final titles = _articles.map((a) => a.title).toList();
        final titleSuggestions = _searchHistory.getSuggestionsFromTitles(
          query,
          titles,
        );

        _searchSuggestions =
            <String>{
                  ...historySuggestions,
                  ...titleSuggestions,
                } // Rimuovi duplicati
                .take(5)
                .toList();
      }
    });
  }

  void _onSearchSubmitted(String query) async {
    if (query.trim().isNotEmpty) {
      await _searchHistory.addSearchTerm(query);
    }
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _loadedItemsCount = _itemsPerPage;
    });

    try {
      // Prova a caricare da cache prima
      final cachedArticles = await _cacheService.getCachedArticles();
      final isCacheValid = await _cacheService.isCacheValid();

      if (cachedArticles.isNotEmpty && (!_isOnline || isCacheValid)) {
        setState(() {
          _articles = cachedArticles;
          _filteredArticles = cachedArticles;
          _isLoading = false;
        });

        // Se online, aggiorna in background
        if (_isOnline && isCacheValid) {
          _updateArticlesInBackground();
        }
        return;
      }

      // Se non c'è cache o non è valida, carica da rete
      if (_isOnline) {
        final articles = await _rssService.fetchArticles();
        await _cacheService.cacheArticles(articles);

        // Preload intelligente per offline
        await _cacheService.preloadArticlesForOffline(articles);

        setState(() {
          _articles = articles;
          _filteredArticles = articles;
          _isLoading = false;
        });
      } else {
        // Offline e nessuna cache
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nessuna connessione e nessun articolo in cache'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // In caso di errore, prova a usare la cache
      final cachedArticles = await _cacheService.getCachedArticles();
      if (cachedArticles.isNotEmpty) {
        setState(() {
          _articles = cachedArticles;
          _filteredArticles = cachedArticles;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore nel caricamento: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _updateArticlesInBackground() async {
    try {
      final articles = await _rssService.fetchArticles();
      await _cacheService.cacheArticles(articles);

      // Aggiorna anche il preload
      await _cacheService.preloadArticlesForOffline(articles);

      if (mounted) {
        setState(() {
          _articles = articles;
          _filteredArticles = articles;
        });
      }
    } catch (e) {
      // Ignora errori in background update
    }
  }

  Future<void> _openArticleInCustomTab(String link) async {
    try {
      // Traccia articoli letti e mostra paywall se necessario
      final subscriptionService = context.read<SubscriptionService>();
      
      if (!subscriptionService.isPremium) {
        _articlesReadCount++;
        
        // Mostra paywall ogni N articoli
        if (_articlesReadCount % _articlesBeforePaywall == 0) {
          await showPremiumPaywall(context);
          return; // Non aprire l'articolo se l'utente non ha accesso
        }
      }
      
      await launchUrl(
        Uri.parse(link),
        customTabsOptions: CustomTabsOptions(
          colorSchemes: CustomTabsColorSchemes.defaults(
            toolbarColor: Theme.of(context).colorScheme.primary,
          ),
          shareState: CustomTabsShareState.on,
          urlBarHidingEnabled: true,
          showTitle: true,
          closeButton: CustomTabsCloseButton(
            icon: CustomTabsCloseButtonIcons.back,
          ),
        ),
        safariVCOptions: SafariViewControllerOptions(
          preferredBarTintColor: Theme.of(context).colorScheme.primary,
          preferredControlTintColor: Colors.white,
          barCollapsingEnabled: true,
          dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Impossibile aprire il link'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Column(
        children: [
          // Banner offline
          if (!_isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange,
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _articles.isNotEmpty
                          ? 'Modalità offline - Mostrando articoli salvati'
                          : 'Nessuna connessione internet',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar.large(
                    floating: true,
                    pinned: true,
                    snap: false,
                    title: const Text(
                      'Android News',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    actions: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubicEmphasized,
                        width: _isSearching
                            ? MediaQuery.of(context).size.width - 120
                            : 48,
                        height: 48,
                        child: _isSearching
                            ? Autocomplete<String>(
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return _searchHistory.getHistory().take(
                                          5,
                                        );
                                      }
                                      return _searchSuggestions;
                                    },
                                onSelected: (String selection) {
                                  _searchController.text = selection;
                                  _onSearchSubmitted(selection);
                                },
                                fieldViewBuilder:
                                    (
                                      context,
                                      controller,
                                      focusNode,
                                      onFieldSubmitted,
                                    ) {
                                      // Sincronizza con il controller principale
                                      if (controller.text !=
                                          _searchController.text) {
                                        controller.text =
                                            _searchController.text;
                                      }

                                      return TextField(
                                        controller: _searchController,
                                        focusNode: _searchFocusNode,
                                        autofocus: true,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                        textInputAction: TextInputAction.search,
                                        onSubmitted: _onSearchSubmitted,
                                        decoration: InputDecoration(
                                          hintText: 'Cerca notizie...',
                                          prefixIcon: const Icon(Icons.search),
                                          suffixIcon: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (_searchController
                                                  .text
                                                  .isNotEmpty)
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.clear,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                  },
                                                ),
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () {
                                                  setState(() {
                                                    _isSearching = false;
                                                    _searchController.clear();
                                                    _filteredArticles =
                                                        _articles;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          filled: true,
                                          fillColor: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                              ),
                                        ),
                                      );
                                    },
                                optionsViewBuilder:
                                    (context, onSelected, options) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 4,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxHeight: 200,
                                              maxWidth: 300,
                                            ),
                                            child: ListView.builder(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              shrinkWrap: true,
                                              itemCount: options.length,
                                              itemBuilder: (context, index) {
                                                final option = options
                                                    .elementAt(index);
                                                final isHistory = _searchHistory
                                                    .getHistory()
                                                    .contains(option);

                                                return ListTile(
                                                  dense: true,
                                                  leading: Icon(
                                                    isHistory
                                                        ? Icons.history
                                                        : Icons.search,
                                                    size: 20,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  title: Text(
                                                    option,
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
                                                  ),
                                                  trailing: isHistory
                                                      ? IconButton(
                                                          icon: const Icon(
                                                            Icons.close,
                                                            size: 18,
                                                          ),
                                                          onPressed: () async {
                                                            await _searchHistory
                                                                .removeSearchTerm(
                                                                  option,
                                                                );
                                                            setState(() {});
                                                          },
                                                        )
                                                      : null,
                                                  onTap: () =>
                                                      onSelected(option),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                              )
                            : IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () {
                                  setState(() {
                                    _isSearching = true;
                                  });
                                  _searchFocusNode.requestFocus();
                                },
                              ),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: _bookmarkService.bookmarkCountNotifier,
                        builder: (context, count, child) {
                          return Badge(
                            label: Text('$count'),
                            isLabelVisible: count > 0,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                            child: IconButton(
                              icon: const Icon(Icons.bookmark_outline),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageTransitions.slideAndFade(
                                    const BookmarksScreen(),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageTransitions.slideAndFade(
                              const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ];
              },
              body: RefreshIndicator(
                onRefresh: _isOnline
                    ? _loadArticles
                    : () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Impossibile aggiornare: nessuna connessione',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                child: _isLoading && _articles.isEmpty
                    ? _buildLoadingState()
                    : _filteredArticles.isEmpty
                    ? _buildEmptyState()
                    : _buildArticlesList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isOnline ? _loadArticles : null,
        icon: Icon(_isOnline ? Icons.refresh : Icons.cloud_off),
        label: Text(_isOnline ? 'Aggiorna' : 'Offline'),
        backgroundColor: _isOnline ? null : Colors.grey,
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shimmer animato per immagine
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: value,
                        ),
                        colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: value,
                        ),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
              onEnd: () {
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 12),
            // Shimmer titolo
            _buildShimmerLine(colorScheme, double.infinity, 20),
            const SizedBox(height: 8),
            // Shimmer sottotitolo
            _buildShimmerLine(colorScheme, 200, 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLine(
    ColorScheme colorScheme,
    double width,
    double height,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: value),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildEmptyState() {
    final isSearchActive = _searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie animation basato sullo stato
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              isSearchActive
                  ? 'assets/animations/no_search_results.json'
                  : 'assets/animations/empty_articles.json',
              repeat: true,
              reverse: false,
              animate: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearchActive ? 'Nessun risultato' : 'Nessuna notizia disponibile',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            isSearchActive
                ? 'Prova con altri termini di ricerca'
                : 'Premi il pulsante per caricare le notizie',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Calcola il numero totale di item (articoli + annunci) nella lista
  int _buildListItemCount(int articlesCount, bool isPremium) {
    if (isPremium) {
      return articlesCount + (_isLoadingMore ? 1 : 0);
    }
    // Per utenti gratuiti: aggiungi un annuncio ogni 5 elementi (ogni 4 articoli)
    int adsCount = (articlesCount / 4).floor();
    return articlesCount + adsCount + (_isLoadingMore ? 1 : 0);
  }

  /// Converte l'indice della lista (con annunci) all'indice dell'articolo
  int _getArticleIndex(int listIndex, bool isPremium) {
    if (isPremium) {
      return listIndex;
    }
    // Sottrai il numero di annunci prima di questo indice
    int adsCount = (listIndex / 5).floor();
    return listIndex - adsCount;
  }

  Widget _buildArticlesList() {
    return ValueListenableBuilder<bool>(
      valueListenable: _settings.gridLayout,
      builder: (context, isGrid, _) {
        final displayedArticles = _filteredArticles
            .take(_loadedItemsCount)
            .toList();

        if (!isGrid) {
          return Consumer2<SubscriptionService, AdsService>(
            builder: (context, subscriptionService, adsService, _) {
              return ListView.builder(
                controller: _scrollController,
                itemCount: _buildListItemCount(displayedArticles.length, subscriptionService.isPremium),
                padding: const EdgeInsets.only(bottom: 80, top: 8),
                itemBuilder: (context, index) {
                  // Loading indicator di fondo
                  if (index == _buildListItemCount(displayedArticles.length, subscriptionService.isPremium) - 1 && _isLoadingMore) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          height: 40,
                          width: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // Mostra annunci ogni 4 articoli per utenti gratuiti
                  if (!subscriptionService.isPremium && index > 0 && index % 5 == 4) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        height: 250,
                        child: adsService.getBannerAdWidget(),
                      ),
                    );
                  }

                  final articleIndex = _getArticleIndex(index, subscriptionService.isPremium);
                  if (articleIndex >= displayedArticles.length) {
                    return const SizedBox.shrink();
                  }

                  final article = displayedArticles[articleIndex];
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(
                      milliseconds: 300 + (articleIndex * 50).clamp(0, 500),
                    ),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: NewsCard(
                      article: article,
                      onTap: () => _openArticleInCustomTab(article.link),
                      searchQuery: _currentSearchQuery,
                    ),
                  );
                },
              );
            },
          );
        }

        // Grid layout
        return Consumer2<SubscriptionService, AdsService>(
          builder: (context, subscriptionService, adsService, _) {
            return GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: _buildListItemCount(displayedArticles.length, subscriptionService.isPremium),
              itemBuilder: (context, index) {
                // Loading indicator di fondo
                if (index == _buildListItemCount(displayedArticles.length, subscriptionService.isPremium) - 1 && _isLoadingMore) {
                  return Center(
                    child: SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                }

                // Mostra annunci ogni 4 articoli per utenti gratuiti
                if (!subscriptionService.isPremium && index > 0 && index % 5 == 4) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: adsService.getBannerAdWidget(),
                  );
                }

                final articleIndex = _getArticleIndex(index, subscriptionService.isPremium);
                if (articleIndex >= displayedArticles.length) {
                  return const SizedBox.shrink();
                }

                final article = displayedArticles[articleIndex];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(
                    milliseconds: 300 + (articleIndex * 40).clamp(0, 400),
                  ),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: NewsCard(
                    article: article,
                    onTap: () => _openArticleInCustomTab(article.link),
                    compact: true,
                    searchQuery: _currentSearchQuery,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class NewsCard extends StatefulWidget {
  final NewsArticle article;
  final VoidCallback onTap;
  final bool compact;
  final String searchQuery;

  const NewsCard({
    super.key,
    required this.article,
    required this.onTap,
    this.compact = false,
    this.searchQuery = '',
  });

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm', 'it_IT');

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Immagine
              if (widget.article.imageUrl != null &&
                  widget.article.imageUrl!.isNotEmpty)
                Hero(
                  tag: 'image_${widget.article.link}',
                  child: CachedNetworkImage(
                    imageUrl: widget.article.imageUrl!,
                    height: widget.compact ? 140 : 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    memCacheHeight: 400,
                    maxHeightDiskCache: 600,
                    httpHeaders: const {
                      'User-Agent':
                          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                    },
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      return Container(
                        height: widget.compact ? 140 : 200,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      );
                    },
                  ),
                ),

              // Contenuto
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge sorgente
                    Row(
                      children: [
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
                            widget.article.source,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(widget.article.pubDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Titolo con highlighting
                    HighlightedText(
                      text: widget.article.title,
                      query: widget.searchQuery,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: widget.compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Descrizione con highlighting
                    if (widget.article.description.isNotEmpty)
                      HighlightedText(
                        text: _cleanHtml(widget.article.description),
                        query: widget.searchQuery,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                        maxLines: widget.compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 12),

                    // Azioni
                    _NewsCardActions(article: widget.article),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
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
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®')
        .replaceAll('&trade;', '™')
        .replaceAll(RegExp(r'&#\d+;'), '')
        .replaceAll(RegExp(r'&[a-zA-Z]+;'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _NewsCardActions extends StatefulWidget {
  final NewsArticle article;

  const _NewsCardActions({required this.article});

  @override
  State<_NewsCardActions> createState() => _NewsCardActionsState();
}

class _NewsCardActionsState extends State<_NewsCardActions> {
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final bookmarkService = BookmarkService();
    final isBookmarked = await bookmarkService.isBookmarked(
      widget.article.link,
    );
    if (mounted) {
      setState(() {
        _isBookmarked = isBookmarked;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final bookmarkService = BookmarkService();

    if (_isBookmarked) {
      await bookmarkService.unbookmarkArticle(widget.article.link);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Articolo rimosso dai preferiti'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await bookmarkService.bookmarkArticle(widget.article);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Articolo salvato nei preferiti'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
    }
  }

  Future<void> _shareArticle() async {
    await Share.share(
      '${widget.article.title}\n\n${widget.article.link}',
      subject: widget.article.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          icon: Icon(
            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            size: 20,
          ),
          onPressed: _toggleBookmark,
          tooltip: _isBookmarked ? 'Rimuovi dai preferiti' : 'Salva',
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          icon: const Icon(Icons.share, size: 20),
          onPressed: _shareArticle,
          tooltip: 'Condividi',
        ),
      ],
    );
  }
}
