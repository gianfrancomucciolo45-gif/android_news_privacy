// lib/constants/monetization_constants.dart

// ===== Google AdMob Configuration =====
/// Ad Unit IDs - Production IDs from AdMob Console
/// App: Android News (ca-app-pub-9815928286949687~8739940611)
class AdMobIds {
  /// ID Banner Ads (Home Feed)
  static const String bannerAdUnitId = 
    'ca-app-pub-9815928286949687/5898154859';  // Production ID
  
  /// ID Interstitial Ads (Between Articles)
  static const String interstitialAdUnitId =
    'ca-app-pub-9815928286949687/3059581987';  // Production ID
  
  /// ID Rewarded Ads (Premium Article Access)
  static const String rewardedAdUnitId =
    'ca-app-pub-9815928286949687/8364536094';  // Production ID

  /// Test Device IDs - Aggiungi i tuoi test device IDs
  static const List<String> testDeviceIds = [
    // 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', // Replace with your test device ID
  ];

  /// Dimensione banner ads
  static const int bannerAdHeight = 50;
}

/// Ad Unit IDs di test ufficiali Google (usa in sviluppo/fallback)
class AdMobTestIds {
  static const String banner = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String rewarded = 'ca-app-pub-3940256099942544/5224354917';
}

// ===== In-App Purchase Configuration =====
/// Product IDs da Google Play Console
class SubscriptionProductIds {
  /// Monthly subscription ID
  static const String monthly = 'premium_monthly';
  
  /// Yearly subscription ID
  static const String yearly = 'premium_yearly';
  
  /// List di tutti i product IDs
  static const List<String> allProductIds = [monthly, yearly];
}

/// Prezzi delle subscription per display
class SubscriptionPrices {
  static const String monthlyPrice = '€2,99';
  static const String monthlyPriceUs = '\$2.99';
  static const String yearlyPrice = '€19,99';
  static const String yearlyPriceUs = '\$19.99';
  
  /// Sconto annuale vs mensile (circa 44%)
  static const String yearlyDiscountPercent = '44%';
}

// ===== Entitlements =====
/// Diritti/Entitlements dell'utente premium
class EntitlementIds {
  static const String premiumAccess = 'premium_access';
}

// ===== Feature Flags per Monetizzazione =====
/// Flag per abilitare/disabilitare monetizzazione
class MonetizationFeatureFlags {
  /// Abilita Google AdMob ads
  static const bool adsEnabled = true;
  
  /// Abilita subscription in-app
  static const bool subscriptionEnabled = true;
  
  /// Mostra paywall dopo N articoli letti
  static const int paywallFrequency = 3;
  
  /// Abilita reward ads per accedere ad articoli premium
  static const bool rewardAdsForPremium = true;
  
  /// Frequenza massima interstitial ads (minuti tra un ad e l'altro)
  static const int interstitialFrequencyMinutes = 30;
}

// ===== Prezzi e Conversioni di Valuta =====
/// Tassi di conversione di riferimento per prezzi
class CurrencyRates {
  /// EUR to USD
  static const double eurToUsd = 1.10;
  
  /// EUR to GBP
  static const double eurToGbp = 0.92;
}

// ===== Analytics Events =====
/// Event names per Firebase Analytics
class MonetizationAnalyticsEvents {
  // Paywall events
  static const String paywallViewed = 'paywall_viewed';
  static const String paywallDismissed = 'paywall_dismissed';
  
  // Subscription events
  static const String subscriptionViewed = 'subscription_viewed';
  static const String subscriptionStartedTrial = 'subscription_started_trial';
  static const String subscriptionPurchased = 'subscription_purchased';
  static const String subscriptionFailed = 'subscription_failed';
  static const String subscriptionCancelled = 'subscription_cancelled';
  static const String subscriptionExpired = 'subscription_expired';
  
  // Ad events
  static const String adImpression = 'ad_impression';
  static const String adClicked = 'ad_clicked';
  static const String adFailedToLoad = 'ad_failed_to_load';
  
  // Premium feature access
  static const String premiumFeatureAccessed = 'premium_feature_accessed';
  static const String limitExceeded = 'limit_exceeded';
}

// ===== Remote Config Keys =====
/// Chiavi per Firebase Remote Config (per feature flags server-side)
class RemoteConfigKeys {
  static const String adsEnabled = 'ads_enabled';
  static const String subscriptionEnabled = 'subscription_enabled';
  static const String paywallFrequency = 'paywall_frequency';
  static const String premiumFeatures = 'premium_features';
  static const String adsBlocked = 'ads_blocked_until';
  static const String monthlyPrice = 'monthly_price';
  static const String yearlyPrice = 'yearly_price';
}
