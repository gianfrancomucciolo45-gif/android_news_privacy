import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'services/settings_service.dart';
import 'services/theme_customization_service.dart';
import 'services/remote_config_service.dart';
import 'services/consent_service.dart';
import 'services/performance_monitoring_service.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';
import 'services/ads_service.dart';
import 'services/background_sync_service.dart';
import 'widgets/animated_splash_screen.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inizializza Firebase
  await Firebase.initializeApp();
  
  // Configura background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Configura Edge-to-Edge Layout (Android 12+)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  
  // Lazy initialization: carica solo ciò che serve immediatamente
  await _initializeCriticalServices();
  
  // Inizializza monetizzazione in background (non bloccante)
  _initializeMonetizationServices();
  
  // Inizializza il resto in background (non blocking)
  _initializeNonCriticalServices();
  
  // Avvia il monitoraggio performance
  PerformanceMonitoringService().startMemoryMonitoring();
  
  runApp(const AndroidNewsApp());
}

/// Servizi critici per l'avvio (deve completare prima di mostrare l'UI)
Future<void> _initializeCriticalServices() async {
  await initializeDateFormatting('it_IT', null);
  await SettingsService().init();
  await ThemeCustomizationService().init();
}

/// Inizializza servizi di monetizzazione (non bloccante)
void _initializeMonetizationServices() async {
  try {
    // Inizializza consenso prima degli ads (EEA/GDPR)
    final consentService = ConsentService();
    await consentService.initialize();

    final subscriptionService = SubscriptionService();
    await subscriptionService.initialize();

    final adsService = AdsService();
    await adsService.initialize(consentService.status);
    
    debugPrint('✅ Monetizzazione inizializzata con successo');
  } catch (e) {
    debugPrint('⚠️ Errore durante inizializzazione monetizzazione: $e');
  }
}

/// Servizi non critici per l'avvio (inizializzati in background)
void _initializeNonCriticalServices() async {
  // Carica consenso e feature flags in background
  await Future.delayed(const Duration(milliseconds: 500));
  
  try {
    final remoteConfig = RemoteConfigService();
    await remoteConfig.fetchFlags();
    
    // Inizializza notifiche (non bloccante)
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    // Inizializza background sync service
    final backgroundSync = BackgroundSyncService();
    await backgroundSync.initialize();
    
    debugPrint('✅ Servizi non critici inizializzati');
  } catch (e) {
    // Ignora errori non critici durante startup
    debugPrint('Avvertenza: inizializzazione servizi non critici fallita: $e');
  }
}

class AndroidNewsApp extends StatefulWidget {
  const AndroidNewsApp({super.key});

  @override
  State<AndroidNewsApp> createState() => _AndroidNewsAppState();
}

class _AndroidNewsAppState extends State<AndroidNewsApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();
    final themeCustom = ThemeCustomizationService();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SubscriptionService()),
        ChangeNotifierProvider(create: (_) => AdsService()),
      ],
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          return AnimatedBuilder(
            animation: Listenable.merge([
              settings.themeMode,
              settings.textScale,
              themeCustom.primaryColor,
              themeCustom.secondaryColor,
              themeCustom.oledMode,
            ]),
            builder: (context, _) {
              // Se il wallpaper fornisce colori dinamici (Android 12+), usa quelli
              // altrimenti usa il tema personalizzato
              final lightColorScheme = lightDynamic ?? themeCustom.createLightColorScheme();
              final darkColorScheme = darkDynamic ?? themeCustom.createDarkColorScheme();
          
              return MaterialApp.router(
                title: 'Android News',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.customLightTheme(lightColorScheme),
                darkTheme: AppTheme.customDarkTheme(darkColorScheme),
                themeMode: settings.themeMode.value,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'),
                  Locale('it'),
                ],
                builder: (context, child) {
                  final mq = MediaQuery.of(context);
                  return MediaQuery(
                    data: mq.copyWith(textScaler: TextScaler.linear(settings.textScale.value)),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
                routerConfig: _showSplash
                    ? GoRouter(
                        routes: [
                          GoRoute(
                            path: '/',
                            builder: (context, state) => AnimatedSplashScreen(
                              onAnimationComplete: () {
                                setState(() {
                                  _showSplash = false;
                                });
                              },
                            ),
                          ),
                        ],
                      )
                    : appRouter,
              );
            },
          );
        },
      ),
    );
  }
}
