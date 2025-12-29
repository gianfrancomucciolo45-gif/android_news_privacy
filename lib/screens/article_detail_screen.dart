import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter/services.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:share_plus/share_plus.dart';
import '../models/news_article.dart';
import '../services/bookmark_service.dart';

class ArticleDetailScreen extends StatefulWidget {
  final NewsArticle article;
  final List<NewsArticle>? allArticles;
  final int? currentIndex;

  const ArticleDetailScreen({
    super.key,
    required this.article,
    this.allArticles,
    this.currentIndex,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen>
    with AutomaticKeepAliveClientMixin {
  final BookmarkService _bookmarkService = BookmarkService();
  bool _isBookmarked = false;
  late PageController _pageController;
  late ScrollController _scrollController;
  int _currentPage = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.currentIndex ?? 0;
    _pageController = PageController(initialPage: _currentPage);
    _scrollController = ScrollController();
    _loadBookmarkStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarkStatus() async {
    final isBookmarked = await _bookmarkService.isBookmarked(
      widget.article.link,
    );
    if (mounted) {
      setState(() {
        _isBookmarked = isBookmarked;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarked) {
      await _bookmarkService.unbookmarkArticle(widget.article.link);
    } else {
      await _bookmarkService.bookmarkArticle(widget.article);
    }

    // Haptic feedback
    await HapticFeedback.mediumImpact();

    if (mounted) {
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
      if (mounted) {
        _showSnackBar(
          context,
          _isBookmarked
              ? 'Articolo salvato nei preferiti'
              : 'Articolo rimosso dai preferiti',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('EEEE dd MMMM yyyy • HH:mm', 'it_IT');

    // Se abbiamo una lista di articoli, usa PageView per swipe
    if (widget.allArticles != null && widget.allArticles!.isNotEmpty) {
      return PageView.builder(
        controller: _pageController,
        itemCount: widget.allArticles!.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
          _loadBookmarkStatus();
        },
        itemBuilder: (context, index) {
          final article = widget.allArticles![index];
          return _buildArticleContent(
            context,
            article,
            colorScheme,
            dateFormat,
          );
        },
      );
    }

    // Altrimenti mostra solo l'articolo corrente
    return _buildArticleContent(
      context,
      widget.article,
      colorScheme,
      dateFormat,
    );
  }

  Widget _buildArticleContent(
    BuildContext context,
    NewsArticle article,
    ColorScheme colorScheme,
    DateFormat dateFormat,
  ) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar con immagine e parallax scroll effect
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background:
                  article.imageUrl != null && article.imageUrl!.isNotEmpty
                  ? Hero(
                      tag: 'image_${article.link}',
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Parallax image con scroll listener
                          _ParallaxImage(
                            imageUrl: article.imageUrl!,
                            scrollController: _scrollController,
                            colorScheme: colorScheme,
                          ),
                          // Gradient overlay per leggibilità
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Color.fromRGBO(0, 0, 0, 0.7),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.article,
                        size: 100,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                ),
                onPressed: _toggleBookmark,
                tooltip: _isBookmarked
                    ? 'Rimuovi dai preferiti'
                    : 'Salva nei preferiti',
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  final article =
                      widget.allArticles?[_currentPage] ?? widget.article;
                  _shareArticle(context, article);
                },
                tooltip: 'Condividi',
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => _openInCustomTab(article.link),
                    child: const Row(
                      children: [
                        Icon(Icons.chrome_reader_mode),
                        SizedBox(width: 12),
                        Text('Leggi articolo completo'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => _openInBrowser(article.link),
                    child: const Row(
                      children: [
                        Icon(Icons.open_in_browser),
                        SizedBox(width: 12),
                        Text('Apri nel browser esterno'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => _copyLink(context, article.link),
                    child: const Row(
                      children: [
                        Icon(Icons.copy),
                        SizedBox(width: 12),
                        Text('Copia link'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Contenuto
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge fonte
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      article.source.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Titolo
                  Text(
                    _cleanHtml(article.title),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Metadata
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dateFormat.format(article.pubDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getReadingTime(article.description),
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Divider(color: colorScheme.outlineVariant),

                  const SizedBox(height: 24),

                  // Descrizione/Contenuto
                  Text(
                    _cleanHtml(article.description),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.8, fontSize: 17),
                  ),

                  const SizedBox(height: 32),

                  // Card "Leggi articolo completo"
                  Card(
                    elevation: 0,
                    color: colorScheme.secondaryContainer,
                    child: InkWell(
                      onTap: () => _openInCustomTab(article.link),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chrome_reader_mode,
                                color: colorScheme.onSecondary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Leggi l\'articolo completo',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              colorScheme.onSecondaryContainer,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Apri in Chrome Custom Tab',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSecondaryContainer
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Azioni rapide
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(
                        icon: Icons.share_outlined,
                        label: 'Condividi',
                        onTap: () => _shareArticle(context, article),
                      ),
                      _ActionButton(
                        icon: _isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_outline,
                        label: _isBookmarked ? 'Salvato' : 'Salva',
                        onTap: _toggleBookmark,
                      ),
                      _ActionButton(
                        icon: Icons.copy_outlined,
                        label: 'Copia link',
                        onTap: () => _copyLink(context, article.link),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
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

  String _getReadingTime(String text) {
    final wordCount = text.split(RegExp(r'\s+')).length;
    final minutes = (wordCount / 200).ceil(); // 200 parole al minuto
    return '$minutes min';
  }

  Future<void> _openInCustomTab(String link) async {
    try {
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
        _showSnackBar(context, 'Impossibile aprire il link');
      }
    }
  }

  Future<void> _openInBrowser(String link) async {
    final uri = Uri.parse(link);
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );
    } else {
      if (mounted) {
        _showSnackBar(context, 'Impossibile aprire il link');
      }
    }
  }

  Future<void> _shareArticle(BuildContext context, NewsArticle article) async {
    await Share.share(
      '${_cleanHtml(article.title)}\n\n${article.link}\n\nCondiviso da Android News',
    );
  }

  Future<void> _copyLink(BuildContext context, String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Link copiato negli appunti'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget che implementa l'effetto parallax durante lo scroll
class _ParallaxImage extends StatefulWidget {
  final String imageUrl;
  final ScrollController scrollController;
  final ColorScheme colorScheme;

  const _ParallaxImage({
    required this.imageUrl,
    required this.scrollController,
    required this.colorScheme,
  });

  @override
  State<_ParallaxImage> createState() => _ParallaxImageState();
}

class _ParallaxImageState extends State<_ParallaxImage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Calcola l'offset per il parallax effect
    // Quando scrolli down, l'immagine si muove più lentamente creando un effetto parallax
    final offset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    final parallaxFactor = offset * 0.5; // Adjust 0.5 per velocità parallax

    return Transform.translate(
      offset: Offset(0, parallaxFactor),
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        fit: BoxFit.cover,
        memCacheHeight: 600,
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
        placeholder: (context, url) => Container(
          color: widget.colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 3)),
        ),
        errorWidget: (context, url, error) => Container(
          color: widget.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.image_not_supported,
            size: 80,
            color: widget.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
