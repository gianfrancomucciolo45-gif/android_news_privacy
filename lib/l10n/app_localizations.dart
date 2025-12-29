import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Android News'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search articles...'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No articles found'**
  String get noResults;

  /// No description provided for @noResultsDesc.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search'**
  String get noResultsDesc;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @allArticles.
  ///
  /// In en, this message translates to:
  /// **'All Articles'**
  String get allArticles;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get readMore;

  /// No description provided for @readFullArticle.
  ///
  /// In en, this message translates to:
  /// **'Read full article'**
  String get readFullArticle;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopied;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in Browser'**
  String get openInBrowser;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove Bookmark'**
  String get removeBookmark;

  /// No description provided for @bookmarked.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get bookmarked;

  /// No description provided for @noBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarks;

  /// No description provided for @noBookmarksDesc.
  ///
  /// In en, this message translates to:
  /// **'Save articles to read later'**
  String get noBookmarksDesc;

  /// No description provided for @clearAllBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Clear All Bookmarks'**
  String get clearAllBookmarks;

  /// No description provided for @clearAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all bookmarks?'**
  String get clearAllConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @layout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layout;

  /// No description provided for @layoutList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get layoutList;

  /// No description provided for @layoutGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get layoutGrid;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get textSize;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'News Sources'**
  String get sources;

  /// No description provided for @manageSources.
  ///
  /// In en, this message translates to:
  /// **'Manage Sources'**
  String get manageSources;

  /// No description provided for @enableDisableSources.
  ///
  /// In en, this message translates to:
  /// **'Enable or disable news sources'**
  String get enableDisableSources;

  /// No description provided for @reorderSources.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder sources'**
  String get reorderSources;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @cacheSize.
  ///
  /// In en, this message translates to:
  /// **'Cache Size'**
  String get cacheSize;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get cacheCleared;

  /// No description provided for @maxCacheSize.
  ///
  /// In en, this message translates to:
  /// **'Max Cache Size'**
  String get maxCacheSize;

  /// No description provided for @mb.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get mb;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @offlineMessage.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Showing cached articles.'**
  String get offlineMessage;

  /// No description provided for @loadingArticles.
  ///
  /// In en, this message translates to:
  /// **'Loading articles...'**
  String get loadingArticles;

  /// No description provided for @errorLoadingArticles.
  ///
  /// In en, this message translates to:
  /// **'Error loading articles'**
  String get errorLoadingArticles;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'minutes ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String daysAgo(int days);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @notificationsBreakingNews.
  ///
  /// In en, this message translates to:
  /// **'Breaking News'**
  String get notificationsBreakingNews;

  /// No description provided for @notificationsBreakingNewsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications for urgent news'**
  String get notificationsBreakingNewsDesc;

  /// No description provided for @notificationsFavoriteSources.
  ///
  /// In en, this message translates to:
  /// **'Favorite Sources'**
  String get notificationsFavoriteSources;

  /// No description provided for @notificationsFavoriteSourcesDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications from selected sources'**
  String get notificationsFavoriteSourcesDesc;

  /// No description provided for @notificationsSelectSources.
  ///
  /// In en, this message translates to:
  /// **'Select Sources'**
  String get notificationsSelectSources;

  /// No description provided for @notificationsSelectSourcesDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications only from selected sources'**
  String get notificationsSelectSourcesDesc;

  /// No description provided for @notificationsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Notifications unavailable'**
  String get notificationsUnavailable;

  /// No description provided for @notificationsEnablePermissions.
  ///
  /// In en, this message translates to:
  /// **'Enable notification permissions in device settings'**
  String get notificationsEnablePermissions;

  /// No description provided for @backgroundSyncSettings.
  ///
  /// In en, this message translates to:
  /// **'Background Sync Settings'**
  String get backgroundSyncSettings;

  /// No description provided for @enableBackgroundSync.
  ///
  /// In en, this message translates to:
  /// **'Enable Background Sync'**
  String get enableBackgroundSync;

  /// No description provided for @syncArticlesAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Automatically sync new articles'**
  String get syncArticlesAutomatically;

  /// No description provided for @syncFrequency.
  ///
  /// In en, this message translates to:
  /// **'Sync Frequency'**
  String get syncFrequency;

  /// No description provided for @every.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get every;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @smartSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Frequency adapts automatically to your usage patterns'**
  String get smartSyncDescription;

  /// No description provided for @syncStatistics.
  ///
  /// In en, this message translates to:
  /// **'Sync Statistics'**
  String get syncStatistics;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get lastSync;

  /// No description provided for @syncsToday.
  ///
  /// In en, this message translates to:
  /// **'Syncs Today'**
  String get syncsToday;

  /// No description provided for @articlesReadToday.
  ///
  /// In en, this message translates to:
  /// **'Articles Read Today'**
  String get articlesReadToday;

  /// No description provided for @manualSync.
  ///
  /// In en, this message translates to:
  /// **'Manual Sync'**
  String get manualSync;

  /// No description provided for @downloadLatestArticles.
  ///
  /// In en, this message translates to:
  /// **'Download latest articles'**
  String get downloadLatestArticles;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// No description provided for @backgroundSyncInfo.
  ///
  /// In en, this message translates to:
  /// **'Background sync automatically downloads new articles when you\'re connected to WiFi and battery is sufficient. Frequency adapts to your usage to save battery.'**
  String get backgroundSyncInfo;

  /// No description provided for @batteryFriendly.
  ///
  /// In en, this message translates to:
  /// **'Battery Friendly'**
  String get batteryFriendly;

  /// No description provided for @wifiOnly.
  ///
  /// In en, this message translates to:
  /// **'WiFi Only'**
  String get wifiOnly;

  /// No description provided for @smartTiming.
  ///
  /// In en, this message translates to:
  /// **'Smart Timing'**
  String get smartTiming;

  /// No description provided for @backgroundSyncEnabled.
  ///
  /// In en, this message translates to:
  /// **'Background sync enabled'**
  String get backgroundSyncEnabled;

  /// No description provided for @backgroundSyncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Background sync disabled'**
  String get backgroundSyncDisabled;

  /// No description provided for @manualSyncStarted.
  ///
  /// In en, this message translates to:
  /// **'Manual sync started'**
  String get manualSyncStarted;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
