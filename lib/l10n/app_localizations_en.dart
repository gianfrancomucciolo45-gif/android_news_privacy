// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Android News';

  @override
  String get home => 'Home';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get settings => 'Settings';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search articles...';

  @override
  String get noResults => 'No articles found';

  @override
  String get noResultsDesc => 'Try adjusting your search';

  @override
  String get refresh => 'Refresh';

  @override
  String get allArticles => 'All Articles';

  @override
  String get readMore => 'Read More';

  @override
  String get readFullArticle => 'Read full article';

  @override
  String get share => 'Share';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get linkCopied => 'Link copied to clipboard';

  @override
  String get openInBrowser => 'Open in Browser';

  @override
  String get bookmark => 'Bookmark';

  @override
  String get removeBookmark => 'Remove Bookmark';

  @override
  String get bookmarked => 'Bookmarked';

  @override
  String get noBookmarks => 'No bookmarks yet';

  @override
  String get noBookmarksDesc => 'Save articles to read later';

  @override
  String get clearAllBookmarks => 'Clear All Bookmarks';

  @override
  String get clearAllConfirm =>
      'Are you sure you want to remove all bookmarks?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get deleted => 'Deleted';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get layout => 'Layout';

  @override
  String get layoutList => 'List';

  @override
  String get layoutGrid => 'Grid';

  @override
  String get textSize => 'Text Size';

  @override
  String get sources => 'News Sources';

  @override
  String get manageSources => 'Manage Sources';

  @override
  String get enableDisableSources => 'Enable or disable news sources';

  @override
  String get reorderSources => 'Drag to reorder sources';

  @override
  String get storage => 'Storage';

  @override
  String get cacheSize => 'Cache Size';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get cacheCleared => 'Cache cleared successfully';

  @override
  String get maxCacheSize => 'Max Cache Size';

  @override
  String get mb => 'MB';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get offline => 'Offline';

  @override
  String get offlineMessage => 'You are offline. Showing cached articles.';

  @override
  String get loadingArticles => 'Loading articles...';

  @override
  String get errorLoadingArticles => 'Error loading articles';

  @override
  String get retry => 'Retry';

  @override
  String minutesAgo(int minutes) {
    return 'minutes ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return 'days ago';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get notificationsBreakingNews => 'Breaking News';

  @override
  String get notificationsBreakingNewsDesc =>
      'Receive notifications for urgent news';

  @override
  String get notificationsFavoriteSources => 'Favorite Sources';

  @override
  String get notificationsFavoriteSourcesDesc =>
      'Receive notifications from selected sources';

  @override
  String get notificationsSelectSources => 'Select Sources';

  @override
  String get notificationsSelectSourcesDesc =>
      'Receive notifications only from selected sources';

  @override
  String get notificationsUnavailable => 'Notifications unavailable';

  @override
  String get notificationsEnablePermissions =>
      'Enable notification permissions in device settings';

  @override
  String get backgroundSyncSettings => 'Background Sync Settings';

  @override
  String get enableBackgroundSync => 'Enable Background Sync';

  @override
  String get syncArticlesAutomatically => 'Automatically sync new articles';

  @override
  String get syncFrequency => 'Sync Frequency';

  @override
  String get every => 'Every';

  @override
  String get hours => 'hours';

  @override
  String get smartSyncDescription =>
      'Frequency adapts automatically to your usage patterns';

  @override
  String get syncStatistics => 'Sync Statistics';

  @override
  String get lastSync => 'Last Sync';

  @override
  String get syncsToday => 'Syncs Today';

  @override
  String get articlesReadToday => 'Articles Read Today';

  @override
  String get manualSync => 'Manual Sync';

  @override
  String get downloadLatestArticles => 'Download latest articles';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get howItWorks => 'How It Works';

  @override
  String get backgroundSyncInfo =>
      'Background sync automatically downloads new articles when you\'re connected to WiFi and battery is sufficient. Frequency adapts to your usage to save battery.';

  @override
  String get batteryFriendly => 'Battery Friendly';

  @override
  String get wifiOnly => 'WiFi Only';

  @override
  String get smartTiming => 'Smart Timing';

  @override
  String get backgroundSyncEnabled => 'Background sync enabled';

  @override
  String get backgroundSyncDisabled => 'Background sync disabled';

  @override
  String get manualSyncStarted => 'Manual sync started';

  @override
  String get never => 'Never';
}
