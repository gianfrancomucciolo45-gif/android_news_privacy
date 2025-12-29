// lib/services/ads_service.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'consent_service.dart';
import '../constants/monetization_constants.dart';

/// Servizio per gestire Google AdMob ads
class AdsService extends ChangeNotifier {
  static final AdsService _instance = AdsService._internal();

  factory AdsService() {
    return _instance;
  }

  AdsService._internal();

  // ===== State =====
  bool _isInitialized = false;
  bool _adsEnabled = MonetizationFeatureFlags.adsEnabled;
  AppConsentStatus _consentStatus = AppConsentStatus.unknown;
  bool _useTestAds = false;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  DateTime? _lastInterstitialTime;
  bool _interstitialReady = false;
  bool _rewardedReady = false;
  bool _bannerReady = false;

  // ===== Getters =====
  bool get isInitialized => _isInitialized;
  bool get adsEnabled => _adsEnabled;
  bool get bannerReady => _bannerReady;
  bool get interstitialReady => _interstitialReady;
  bool get rewardedReady => _rewardedReady;
  BannerAd? get bannerAd => _bannerAd;

  // ===== Initialization =====
  /// Inizializza Google Mobile Ads
  Future<void> initialize([AppConsentStatus? consentStatus]) async {
    try {
      // Imposta eventuale consenso noto (EEA/GDPR)
      _consentStatus = consentStatus ?? AppConsentStatus.unknown;

      // Inizializza Mobile Ads SDK
      await MobileAds.instance.initialize();

      // Imposta configurazione richiesta (es. testDeviceIds se presenti)
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: AdMobIds.testDeviceIds,
        ),
      );

      // Carica preferenze ads
      await _loadAdsPreferences();

      _isInitialized = true;
      notifyListeners();

      // Preload ads se enabled
      if (_adsEnabled) {
        _preloadBannerAd();
        _preloadInterstitialAd();
        _preloadRewardedAd();
      }
    } catch (e) {
      debugPrint('Error initializing ads service: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ===== Banner Ads =====
  /// Crea e carica un banner ad
  Future<void> _preloadBannerAd() async {
    try {
      if (!_adsEnabled) return;

      // Distruggi l'ad precedente se esiste
      await _bannerAd?.dispose();

      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId(),
        size: AdSize.banner,
        request: _buildAdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Banner ad loaded');
            _bannerReady = true;
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: ${error.message}');
            ad.dispose();
            _bannerAd = null;
            _bannerReady = false;
            if (_shouldFallbackToTestAds(error.message)) {
              _useTestAds = true;
              _preloadBannerAd();
            }
            notifyListeners();
          },
          onAdOpened: (ad) {
            debugPrint('Banner ad opened');
          },
          onAdClosed: (ad) {
            debugPrint('Banner ad closed');
          },
          onAdImpression: (ad) {
            debugPrint('Banner ad impression');
            _recordAdEvent('banner_impression');
          },
          onAdClicked: (ad) {
            debugPrint('Banner ad clicked');
            _recordAdEvent('banner_clicked');
          },
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      debugPrint('Error preloading banner ad: $e');
      _bannerReady = false;
      notifyListeners();
    }
  }

  /// Ottiene un widget per mostrare il banner ad
  Widget getBannerAdWidget() {
    if (!_adsEnabled || _bannerAd == null || !_bannerReady) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  // ===== Interstitial Ads =====
  /// Preload interstitial ad
  Future<void> _preloadInterstitialAd() async {
    try {
      if (!_adsEnabled) return;

      await _interstitialAd?.dispose();

      InterstitialAd.load(
        adUnitId: _interstitialAdUnitId(),
        request: _buildAdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Interstitial ad loaded');
            _interstitialAd = ad;
            _interstitialReady = true;
            notifyListeners();
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: ${error.message}');
            _interstitialReady = false;
            if (_shouldFallbackToTestAds(error.message)) {
              _useTestAds = true;
              _preloadInterstitialAd();
            }
            notifyListeners();
          },
        ),
      );
    } catch (e) {
      debugPrint('Error preloading interstitial ad: $e');
      _interstitialReady = false;
      notifyListeners();
    }
  }

  /// Mostra interstitial ad se pronto e non è stato mostrato di recente
  Future<bool> showInterstitialAdIfReady() async {
    try {
      if (!_adsEnabled || !_interstitialReady) {
        return false;
      }

      // Verifica frequency capping
      if (_lastInterstitialTime != null) {
        final minutesSinceLastAd =
            DateTime.now().difference(_lastInterstitialTime!).inMinutes;
        if (minutesSinceLastAd <
            MonetizationFeatureFlags.interstitialFrequencyMinutes) {
          debugPrint(
              'Interstitial ad frequency capped. Wait ${MonetizationFeatureFlags.interstitialFrequencyMinutes - minutesSinceLastAd} more minutes');
          return false;
        }
      }

      _interstitialAd?.fullScreenContentCallback =
          FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Interstitial ad showed');
          _recordAdEvent('interstitial_impression');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Interstitial ad dismissed');
          ad.dispose();
          _interstitialAd = null;
          _interstitialReady = false;
          // Ricarica per il prossimo utilizzo
          _preloadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint(
              'Interstitial ad failed to show: ${error.message}');
          ad.dispose();
          _interstitialAd = null;
          _interstitialReady = false;
          // Ricarica per il prossimo utilizzo
          _preloadInterstitialAd();
        },
        onAdClicked: (ad) {
          debugPrint('Interstitial ad clicked');
          _recordAdEvent('interstitial_clicked');
        },
      );

      await _interstitialAd!.show();
      _lastInterstitialTime = DateTime.now();
      _interstitialReady = false;

      return true;
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
      return false;
    }
  }

  // ===== Rewarded Ads =====
  /// Preload rewarded ad
  Future<void> _preloadRewardedAd() async {
    try {
      if (!_adsEnabled) return;

      RewardedAd.load(
        adUnitId: _rewardedAdUnitId(),
        request: _buildAdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Rewarded ad loaded');
            _rewardedAd = ad;
            _rewardedReady = true;
            notifyListeners();
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad failed to load: ${error.message}');
            _rewardedReady = false;
            if (_shouldFallbackToTestAds(error.message)) {
              _useTestAds = true;
              _preloadRewardedAd();
            }
            notifyListeners();
          },
        ),
      );
    } catch (e) {
      debugPrint('Error preloading rewarded ad: $e');
      _rewardedReady = false;
      notifyListeners();
    }
  }

  /// Mostra rewarded ad e ritorna true se utente guarda fino in fondo
  Future<bool> showRewardedAdIfReady() async {
    try {
      if (!_adsEnabled || !_rewardedReady) {
        return false;
      }

      bool rewardEarned = false;

      _rewardedAd?.fullScreenContentCallback =
          FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Rewarded ad showed');
          _recordAdEvent('rewarded_impression');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Rewarded ad dismissed');
          ad.dispose();
          _rewardedAd = null;
          _rewardedReady = false;
          // Ricarica per il prossimo utilizzo
          _preloadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Rewarded ad failed to show: ${error.message}');
          ad.dispose();
          _rewardedAd = null;
          _rewardedReady = false;
          // Ricarica per il prossimo utilizzo
          _preloadRewardedAd();
        },
        onAdClicked: (ad) {
          debugPrint('Rewarded ad clicked');
          _recordAdEvent('rewarded_clicked');
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, rewardItem) {
          debugPrint('User earned reward: ${rewardItem.amount}');
          rewardEarned = true;
          _recordAdEvent('reward_earned');
        },
      );

      _rewardedReady = false;
      return rewardEarned;
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
      return false;
    }
  }

  // ===== Preferences =====
  /// Abilita/disabilita ads
  Future<void> setAdsEnabled(bool enabled) async {
    try {
      _adsEnabled = enabled;

      // Salva in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ads_enabled', enabled);

      if (!enabled) {
        // Ripulisci gli ads caricati
        await _bannerAd?.dispose();
        _bannerAd = null;
        _bannerReady = false;

        await _interstitialAd?.dispose();
        _interstitialAd = null;
        _interstitialReady = false;

        await _rewardedAd?.dispose();
        _rewardedAd = null;
        _rewardedReady = false;
      } else {
        // Ricarica gli ads
        _preloadBannerAd();
        _preloadInterstitialAd();
        _preloadRewardedAd();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error setting ads enabled: $e');
    }
  }

  /// Carica le preferenze degli ads
  Future<void> _loadAdsPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _adsEnabled = prefs.getBool('ads_enabled') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading ads preferences: $e');
    }
  }

  // ===== Analytics =====
  /// Registra gli eventi degli ads (implementare con Firebase Analytics)
  void _recordAdEvent(String eventName,
      {Map<String, Object>? parameters}) {
    debugPrint('Ad event: $eventName${parameters != null ? ' - $parameters' : ''}');
    // TODO: Integrare con Firebase Analytics
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'ad_event',
    //   parameters: {
    //     'event': eventName,
    //     ...?parameters,
    //   },
    // );
  }

  // ===== Cleanup =====
  /// Dispone di tutte le risorse
  @override
  Future<void> dispose() async {
    await _bannerAd?.dispose();
    await _interstitialAd?.dispose();
    await _rewardedAd?.dispose();
    super.dispose();
  }

  // ===== Helpers =====
  AdRequest _buildAdRequest() {
    final nonPersonalized = _consentStatus != AppConsentStatus.accepted;
    return AdRequest(
      nonPersonalizedAds: nonPersonalized,
    );
  }

  String _bannerAdUnitId() => _useTestAds
      ? AdMobTestIds.banner
      : AdMobIds.bannerAdUnitId;

  String _interstitialAdUnitId() => _useTestAds
      ? AdMobTestIds.interstitial
      : AdMobIds.interstitialAdUnitId;

  String _rewardedAdUnitId() => _useTestAds
      ? AdMobTestIds.rewarded
      : AdMobIds.rewardedAdUnitId;

  bool _shouldFallbackToTestAds(String message) {
    final lower = message.toLowerCase();
    return lower.contains('account not approved') || lower.contains('not approved');
  }
}
