// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Android News';

  @override
  String get home => 'Home';

  @override
  String get bookmarks => 'Preferiti';

  @override
  String get settings => 'Impostazioni';

  @override
  String get search => 'Cerca';

  @override
  String get searchHint => 'Cerca articoli...';

  @override
  String get noResults => 'Nessun articolo trovato';

  @override
  String get noResultsDesc => 'Prova a modificare la ricerca';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get allArticles => 'Tutti gli Articoli';

  @override
  String get readMore => 'Leggi di più';

  @override
  String get readFullArticle => 'Leggi l\'articolo completo';

  @override
  String get share => 'Condividi';

  @override
  String get copyLink => 'Copia Link';

  @override
  String get linkCopied => 'Link copiato negli appunti';

  @override
  String get openInBrowser => 'Apri nel Browser';

  @override
  String get bookmark => 'Aggiungi ai Preferiti';

  @override
  String get removeBookmark => 'Rimuovi dai Preferiti';

  @override
  String get bookmarked => 'Aggiunto ai preferiti';

  @override
  String get noBookmarks => 'Nessun preferito';

  @override
  String get noBookmarksDesc => 'Salva gli articoli da leggere dopo';

  @override
  String get clearAllBookmarks => 'Rimuovi Tutti i Preferiti';

  @override
  String get clearAllConfirm =>
      'Sei sicuro di voler rimuovere tutti i preferiti?';

  @override
  String get cancel => 'Annulla';

  @override
  String get confirm => 'Conferma';

  @override
  String get deleted => 'Eliminato';

  @override
  String get appearance => 'Aspetto';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get layout => 'Layout';

  @override
  String get layoutList => 'Lista';

  @override
  String get layoutGrid => 'Griglia';

  @override
  String get textSize => 'Dimensione Testo';

  @override
  String get sources => 'Fonti Notizie';

  @override
  String get manageSources => 'Gestisci Fonti';

  @override
  String get enableDisableSources => 'Abilita o disabilita le fonti';

  @override
  String get reorderSources => 'Trascina per riordinare le fonti';

  @override
  String get storage => 'Archiviazione';

  @override
  String get cacheSize => 'Dimensione Cache';

  @override
  String get clearCache => 'Svuota Cache';

  @override
  String get cacheCleared => 'Cache svuotata con successo';

  @override
  String get maxCacheSize => 'Dimensione Max Cache';

  @override
  String get mb => 'MB';

  @override
  String get about => 'Informazioni';

  @override
  String get version => 'Versione';

  @override
  String get offline => 'Offline';

  @override
  String get offlineMessage =>
      'Sei offline. Visualizzazione articoli in cache.';

  @override
  String get loadingArticles => 'Caricamento articoli...';

  @override
  String get errorLoadingArticles => 'Errore nel caricamento degli articoli';

  @override
  String get retry => 'Riprova';

  @override
  String minutesAgo(int minutes) {
    return 'minuti fa';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h fa';
  }

  @override
  String daysAgo(int days) {
    return 'giorni fa';
  }

  @override
  String get justNow => 'Adesso';

  @override
  String get settingsNotifications => 'Notifiche';

  @override
  String get notificationsBreakingNews => 'Breaking News';

  @override
  String get notificationsBreakingNewsDesc =>
      'Ricevi notifiche per notizie urgenti';

  @override
  String get notificationsFavoriteSources => 'Fonti Preferite';

  @override
  String get notificationsFavoriteSourcesDesc =>
      'Ricevi notifiche dalle fonti selezionate';

  @override
  String get notificationsSelectSources => 'Seleziona Fonti';

  @override
  String get notificationsSelectSourcesDesc =>
      'Ricevi notifiche solo dalle fonti selezionate';

  @override
  String get notificationsUnavailable => 'Notifiche non disponibili';

  @override
  String get notificationsEnablePermissions =>
      'Abilita i permessi notifiche nelle impostazioni';

  @override
  String get backgroundSyncSettings => 'Sincronizzazione in Background';

  @override
  String get enableBackgroundSync => 'Abilita Sync in Background';

  @override
  String get syncArticlesAutomatically =>
      'Sincronizza automaticamente nuovi articoli';

  @override
  String get syncFrequency => 'Frequenza di Sincronizzazione';

  @override
  String get every => 'Ogni';

  @override
  String get hours => 'ore';

  @override
  String get smartSyncDescription =>
      'La frequenza si adatta automaticamente al tuo utilizzo';

  @override
  String get syncStatistics => 'Statistiche Sincronizzazione';

  @override
  String get lastSync => 'Ultima Sincronizzazione';

  @override
  String get syncsToday => 'Sync Oggi';

  @override
  String get articlesReadToday => 'Articoli Letti Oggi';

  @override
  String get manualSync => 'Sincronizzazione Manuale';

  @override
  String get downloadLatestArticles => 'Scarica gli ultimi articoli';

  @override
  String get syncNow => 'Sincronizza Ora';

  @override
  String get howItWorks => 'Come Funziona';

  @override
  String get backgroundSyncInfo =>
      'Il sync in background scarica automaticamente nuovi articoli quando sei connesso al WiFi e la batteria è sufficiente. La frequenza si adatta al tuo utilizzo per risparmiare batteria.';

  @override
  String get batteryFriendly => 'Risparmio Batteria';

  @override
  String get wifiOnly => 'Solo WiFi';

  @override
  String get smartTiming => 'Timing Intelligente';

  @override
  String get backgroundSyncEnabled => 'Sync in background abilitato';

  @override
  String get backgroundSyncDisabled => 'Sync in background disabilitato';

  @override
  String get manualSyncStarted => 'Sincronizzazione manuale avviata';

  @override
  String get never => 'Mai';
}
