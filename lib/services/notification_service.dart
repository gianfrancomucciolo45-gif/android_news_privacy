import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Handler per messaggi in background (deve essere top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📲 Background message ricevuto: ${message.messageId}');
  debugPrint('Titolo: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  
  // Mostra notifica locale anche in background
  await NotificationService._showLocalNotification(message);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  String? _fcmToken;
  
  // Notification channels IDs
  static const String channelBreakingNews = 'breaking_news';
  static const String channelFavoriteSources = 'favorite_sources';
  static const String channelGeneral = 'general';
  
  // ValueNotifiers per settings reattivi
  final ValueNotifier<bool> breakingNewsEnabled = ValueNotifier(true);
  final ValueNotifier<bool> favoriteSourcesEnabled = ValueNotifier(true);
  final ValueNotifier<Set<String>> enabledSources = ValueNotifier({});
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Richiedi permesso per notifiche
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      debugPrint('📱 Permesso notifiche: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Inizializza notification channels
        await _createNotificationChannels();
        
        // Inizializza local notifications
        await _initializeLocalNotifications();
        
        // Ottieni FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('🔑 FCM Token: $_fcmToken');
        
        // Carica preferenze salvate
        await _loadPreferences();
        
        // Subscribe ai topic di default
        await _subscribeToTopics();
        
        // Configura handlers
        _setupMessageHandlers();
        
        _initialized = true;
        debugPrint('✅ NotificationService inizializzato con successo');
      } else {
        debugPrint('⚠️ Permessi notifiche negati');
      }
    } catch (e) {
      debugPrint('❌ Errore inizializzazione NotificationService: $e');
    }
  }
  
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;
    
    const AndroidNotificationChannel breakingNewsChannel = AndroidNotificationChannel(
      channelBreakingNews,
      'Breaking News',
      description: 'Notifiche importanti per notizie urgenti',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    
    const AndroidNotificationChannel favoriteSourcesChannel = AndroidNotificationChannel(
      channelFavoriteSources,
      'Fonti Preferite',
      description: 'Notifiche dalle tue fonti preferite',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    
    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      channelGeneral,
      'Notifiche Generali',
      description: 'Notifiche generali dall\'app',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: false,
      showBadge: true,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(breakingNewsChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(favoriteSourcesChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
    
    debugPrint('✅ Notification channels creati');
  }
  
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }
  
  void _setupMessageHandlers() {
    // Messaggi in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Messaggio in foreground: ${message.messageId}');
      _showLocalNotification(message);
    });
    
    // Notifica tappata mentre app aperta
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('👆 Notifica tappata (app in background): ${message.messageId}');
      _handleNotificationTap(message.data);
    });
    
    // Controlla se app è stata aperta da notifica
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🚀 App aperta da notifica: ${message.messageId}');
        _handleNotificationTap(message.data);
      }
    });
  }
  
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    
    if (notification == null) return;
    
    // Determina il channel in base ai dati del messaggio
    String channelId = channelGeneral;
    if (message.data['type'] == 'breaking_news') {
      channelId = channelBreakingNews;
    } else if (message.data['type'] == 'favorite_source') {
      channelId = channelFavoriteSources;
    }
    
    // Download immagine se presente
    BigPictureStyleInformation? bigPictureStyle;
    
    if (message.data['image_url'] != null) {
      try {
        final imageUrl = message.data['image_url'] as String;
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          bigPictureStyle = BigPictureStyleInformation(
            ByteArrayAndroidBitmap.fromBase64String(base64Encode(bytes)),
            largeIcon: ByteArrayAndroidBitmap.fromBase64String(base64Encode(bytes)),
            contentTitle: notification.title,
            summaryText: notification.body,
            htmlFormatContentTitle: true,
            htmlFormatSummaryText: true,
          );
        }
      } catch (e) {
        debugPrint('❌ Errore download immagine notifica: $e');
      }
    }
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == channelBreakingNews ? 'Breaking News' : 
      channelId == channelFavoriteSources ? 'Fonti Preferite' : 'Notifiche Generali',
      channelDescription: 'Notifiche Android News',
      importance: channelId == channelBreakingNews ? Importance.max : Importance.high,
      priority: Priority.high,
      ticker: notification.title,
      styleInformation: bigPictureStyle,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'read',
          'Leggi',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_notification_read'),
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'save',
          'Salva',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_notification_bookmark'),
        ),
        const AndroidNotificationAction(
          'share',
          'Condividi',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_notification_share'),
        ),
      ],
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    final localNotifications = FlutterLocalNotificationsPlugin();
    await localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Notifica locale tappata: ${response.actionId}');
    
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      
      // Gestisci le azioni
      if (response.actionId == 'read') {
        _handleReadAction(data);
      } else if (response.actionId == 'save') {
        _handleSaveAction(data);
      } else if (response.actionId == 'share') {
        _handleShareAction(data);
      } else {
        _handleNotificationTap(data);
      }
    }
  }
  
  void _handleNotificationTap(Map<String, dynamic> data) {
    // Naviga all'articolo
    final articleUrl = data['article_url'];
    if (articleUrl != null) {
      debugPrint('🔗 Apertura articolo: $articleUrl');
      // TODO: Implementare navigazione all'articolo
    }
  }
  
  void _handleReadAction(Map<String, dynamic> data) {
    debugPrint('📖 Azione Leggi articolo');
    _handleNotificationTap(data);
  }
  
  void _handleSaveAction(Map<String, dynamic> data) {
    debugPrint('💾 Azione Salva articolo');
    // TODO: Implementare salvataggio bookmark
  }
  
  void _handleShareAction(Map<String, dynamic> data) {
    debugPrint('📤 Azione Condividi articolo');
    // TODO: Implementare share
  }
  
  Future<void> _subscribeToTopics() async {
    // Subscribe sempre al topic generale
    await _firebaseMessaging.subscribeToTopic('all_news');
    
    if (breakingNewsEnabled.value) {
      await _firebaseMessaging.subscribeToTopic('breaking_news');
    }
    
    if (favoriteSourcesEnabled.value) {
      await _firebaseMessaging.subscribeToTopic('favorite_sources');
    }
    
    // Subscribe alle fonti abilitate
    for (final source in enabledSources.value) {
      await _firebaseMessaging.subscribeToTopic('source_$source');
    }
    
    debugPrint('✅ Sottoscritto ai topic');
  }
  
  Future<void> toggleBreakingNews(bool enabled) async {
    breakingNewsEnabled.value = enabled;
    
    if (enabled) {
      await _firebaseMessaging.subscribeToTopic('breaking_news');
    } else {
      await _firebaseMessaging.unsubscribeFromTopic('breaking_news');
    }
    
    await _savePreferences();
  }
  
  Future<void> toggleFavoriteSources(bool enabled) async {
    favoriteSourcesEnabled.value = enabled;
    
    if (enabled) {
      await _firebaseMessaging.subscribeToTopic('favorite_sources');
    } else {
      await _firebaseMessaging.unsubscribeFromTopic('favorite_sources');
    }
    
    await _savePreferences();
  }
  
  Future<void> toggleSourceNotifications(String sourceId, bool enabled) async {
    final sources = Set<String>.from(enabledSources.value);
    
    if (enabled) {
      sources.add(sourceId);
      await _firebaseMessaging.subscribeToTopic('source_$sourceId');
    } else {
      sources.remove(sourceId);
      await _firebaseMessaging.unsubscribeFromTopic('source_$sourceId');
    }
    
    enabledSources.value = sources;
    await _savePreferences();
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    breakingNewsEnabled.value = prefs.getBool('notifications_breaking_news') ?? true;
    favoriteSourcesEnabled.value = prefs.getBool('notifications_favorite_sources') ?? true;
    
    final sourcesJson = prefs.getStringList('notifications_enabled_sources') ?? [];
    enabledSources.value = sourcesJson.toSet();
  }
  
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('notifications_breaking_news', breakingNewsEnabled.value);
    await prefs.setBool('notifications_favorite_sources', favoriteSourcesEnabled.value);
    await prefs.setStringList('notifications_enabled_sources', enabledSources.value.toList());
  }
  
  /// Mostra notifica per download in background (foreground service)
  Future<void> showDownloadNotification({
    required String title,
    required String body,
    bool isComplete = false,
    bool isError = false,
    int progress = 0,
  }) async {
    const int downloadNotificationId = 999; // ID fisso per download
    
    AndroidNotificationDetails androidDetails;
    
    if (isComplete || isError) {
      // Notifica finale (successo o errore)
      androidDetails = AndroidNotificationDetails(
        channelGeneral,
        'Notifiche Generali',
        channelDescription: 'Notifiche generali dall\'app',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        ongoing: false,
        autoCancel: true,
        icon: isError ? '@drawable/ic_error' : '@drawable/ic_check',
      );
    } else {
      // Notifica in progress (foreground service)
      androidDetails = AndroidNotificationDetails(
        channelGeneral,
        'Notifiche Generali',
        channelDescription: 'Notifiche generali dall\'app',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true, // Non può essere cancellata
        autoCancel: false,
        showProgress: progress > 0,
        maxProgress: 100,
        progress: progress,
        indeterminate: progress == 0,
        icon: '@drawable/ic_download',
      );
    }
    
    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    
    await _localNotifications.show(
      downloadNotificationId,
      title,
      body,
      platformDetails,
    );
    
    // Se è completata, cancellala dopo 3 secondi
    if (isComplete || isError) {
      Future.delayed(const Duration(seconds: 3), () {
        _localNotifications.cancel(downloadNotificationId);
      });
    }
  }
  
  /// Mostra notifica semplice
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelGeneral,
      'Notifiche Generali',
      channelDescription: 'Notifiche generali dall\'app',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
  
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _initialized;
}
