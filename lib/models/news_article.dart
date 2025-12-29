class NewsArticle {
  final String title;
  final String description;
  final String link;
  final String? imageUrl;
  final DateTime pubDate;
  final String source;
  final String category;

  NewsArticle({
    required this.title,
    required this.description,
    required this.link,
    this.imageUrl,
    required this.pubDate,
    required this.source,
    this.category = 'general',
  });

  factory NewsArticle.fromRss(dynamic item, String source, String category) {
    try {
      final title = (item.title ?? '').trim();
      final description = (item.description ?? '').trim();
      final link = (item.link ?? '').trim();
      
      // Parse della data con fallback
      DateTime pubDate;
      try {
        pubDate = item.pubDate ?? DateTime.now();
      } catch (e) {
        pubDate = DateTime.now();
      }
      
      return NewsArticle(
        title: title.isNotEmpty ? title : 'Notizia senza titolo',
        description: description,
        link: link.isNotEmpty ? link : '#',
        imageUrl: _extractImageUrl(item),
        pubDate: pubDate,
        source: source,
        category: category,
      );
    } catch (e) {
      // Ritorna un articolo di fallback
      return NewsArticle(
        title: 'Errore nel caricamento',
        description: '',
        link: '#',
        imageUrl: null,
        pubDate: DateTime.now(),
        source: source,
        category: category,
      );
    }
  }

  static String? _extractImageUrl(dynamic item) {
    try {
      // Try media:content
      if (item.media?.contents?.isNotEmpty ?? false) {
        final url = item.media.contents.first.url;
        if (url != null && _isValidImageUrl(url)) return url;
      }
      
      // Try enclosure
      if (item.enclosure?.url != null) {
        final url = item.enclosure.url;
        if (_isValidImageUrl(url)) return url;
      }
      
      // Try media:thumbnail
      if (item.media?.thumbnails?.isNotEmpty ?? false) {
        final url = item.media.thumbnails.first.url;
        if (url != null && _isValidImageUrl(url)) return url;
      }
      
      // Try content:encoded
      final content = item.content?.value ?? '';
      if (content.isNotEmpty) {
        final url = _extractImageFromHtml(content);
        if (url != null && _isValidImageUrl(url)) return url;
      }
      
      // Try to extract from description
      final desc = item.description ?? '';
      if (desc.isNotEmpty) {
        final url = _extractImageFromHtml(desc);
        if (url != null && _isValidImageUrl(url)) return url;
      }
    } catch (e) {
      // Ignora errori nell'estrazione immagini
    }
    return null;
  }
  
  static String? _extractImageFromHtml(String html) {
    // Prova diversi pattern per le immagini
    final patterns = [
      RegExp(r'<img[^>]+src=["' "'" r']([^"' "'" r'>]+)["' "'" r']', caseSensitive: false),
      RegExp(r'background-image:\s*url\(["' "'" r']?([^"' "'" r')]+)["' "'" r']?\)', caseSensitive: false),
      RegExp(r'<meta[^>]+property=["' "'" r']og:image["' "'" r'][^>]+content=["' "'" r']([^"' "'" r'>]+)["' "'" r']', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }
  
  static bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) return false;
      
      // Controlla estensioni immagine comuni
      final path = uri.path.toLowerCase();
      final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg', '.bmp'];
      
      // Accetta URL senza estensione (potrebbero essere URL dinamiche)
      if (validExtensions.any((ext) => path.endsWith(ext))) return true;
      if (!path.contains('.') && path.length > 10) return true; // URL dinamiche
      
      return false;
    } catch (e) {
      return false;
    }
  }
}
