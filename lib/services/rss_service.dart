import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';
import '../models/news_article.dart';
import 'settings_service.dart';

class RssService {
  // Fonti RSS Android e tecnologia italiane
  static final Map<String, RssSource> sources = {
    'tuttoandroid': RssSource(
      name: 'TuttoAndroid',
      url: 'https://www.tuttoandroid.net/feed/',
      category: 'technology',
    ),
    'androidworld': RssSource(
      name: 'AndroidWorld',
      url: 'https://www.smartworld.it/android/feed',
      category: 'technology',
    ),
    'hdblog_android': RssSource(
      name: 'HDblog Android',
      url: 'https://www.hdblog.it/android/rss',
      category: 'technology',
    ),
    'androidiani': RssSource(
      name: 'Androidiani',
      url: 'https://www.androidiani.com/feed/',
      category: 'technology',
    ),
    'hdblog': RssSource(
      name: 'HDblog',
      url: 'https://www.hdblog.it/rss',
      category: 'technology',
    ),
    'tecnoandroid': RssSource(
      name: 'TecnoAndroid',
      url: 'https://www.tecnoandroid.it/feed/',
      category: 'technology',
    ),
    'gizchina': RssSource(
      name: 'GizChina',
      url: 'https://gizchina.it/feed/',
      category: 'technology',
    ),
    'xiaomitoday': RssSource(
      name: 'XiaomiToday',
      url: 'https://www.xiaomitoday.it/feed/',
      category: 'technology',
    ),
    'telefonino': RssSource(
      name: 'Telefonino.net',
      url: 'https://www.telefonino.net/feed/',
      category: 'technology',
    ),
    'tomshw': RssSource(
      name: "Tom's Hardware",
      url: 'https://www.tomshw.it/feed/',
      category: 'technology',
    ),
    'hwupgrade': RssSource(
      name: 'HWUpgrade',
      url: 'https://www.hwupgrade.it/rss/hwupgrade.xml',
      category: 'technology',
    ),
    'evosmart': RssSource(
      name: 'EvoSmart',
      url: 'https://www.evosmart.it/feed/',
      category: 'technology',
    ),
    'dday': RssSource(
      name: 'DDay.it',
      url: 'https://www.dday.it/rss',
      category: 'technology',
    ),
    'tuttotech': RssSource(
      name: 'TuttoTech',
      url: 'https://www.tuttotech.net/feed/',
      category: 'technology',
    ),
  };

  Future<List<NewsArticle>> fetchArticles({String? category}) async {
    List<NewsArticle> allArticles = [];
    final settings = SettingsService();

    // Determina le fonti abilitate e l'ordine preferito
    final enabled = settings.enabledSources.value;
    final order = settings.sourceOrder.value;
    // Se l'utente non ha ancora scelto, consideriamo tutte abilitate
    final filteredEntries = sources.entries.where((e) => enabled.isEmpty || enabled.contains(e.key));
    // Applica ordine personalizzato se presente, altrimenti mantieni chiave naturale
    final sortedEntries = filteredEntries.toList()
      ..sort((a, b) {
        if (order.isEmpty) return a.key.compareTo(b.key);
        final ia = order.indexOf(a.key);
        final ib = order.indexOf(b.key);
        final va = ia == -1 ? 1 << 20 : ia; // elementi non in lista vanno in fondo
        final vb = ib == -1 ? 1 << 20 : ib;
        return va.compareTo(vb);
      });

    for (var entry in sortedEntries) {
      if (category != null && entry.value.category != category && category != 'all') {
        continue;
      }

      try {
        final articles = await _fetchFromSource(entry.value);
        allArticles.addAll(articles);
      } catch (e) {
        // Ignora errori da singole fonti e continua
      }
    }

    // Ordina per data (più recenti prima)
    allArticles.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    return allArticles;
  }

  Future<List<NewsArticle>> _fetchFromSource(RssSource source) async {
    try {
      final response = await http.get(
        Uri.parse(source.url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/rss+xml, application/xml, text/xml, */*',
          // Supporto formati moderni per immagini
          'Accept-Image': 'image/webp, image/avif, image/jpeg, image/*',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          // Prova a decodificare come UTF-8
          final feed = RssFeed.parse(response.body);
          final articles = <NewsArticle>[];
          
          if (feed.items != null) {
            for (var item in feed.items!) {
              try {
                final article = NewsArticle.fromRss(item, source.name, source.category);
                articles.add(article);
              } catch (e) {
                // Continua con gli altri articoli
              }
            }
          }
          return articles;
        } catch (e) {
          // Errore parsing feed
        }
      } else {
        // HTTP error
      }
    } catch (e) {
      // Errore fetching
    }
    return [];
  }
}

class RssSource {
  final String name;
  final String url;
  final String category;

  RssSource({
    required this.name,
    required this.url,
    required this.category,
  });
}
