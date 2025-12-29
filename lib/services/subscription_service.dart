// lib/services/subscription_service.dart

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/monetization_constants.dart';
import '../models/subscription_model.dart';
import 'ads_service.dart';

/// Servizio per gestire le subscription in-app
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance =
      SubscriptionService._internal();

  factory SubscriptionService() {
    return _instance;
  }

  SubscriptionService._internal();

  // ===== State =====
  UserSubscription _userSubscription = UserSubscription.none();
  bool _isInitialized = false;
  bool _isPurchasing = false;
  String? _lastErrorMessage;
  
  late InAppPurchase _inAppPurchase;
  final List<ProductDetails> _productDetails = [];

  // ===== Getters =====
  UserSubscription get userSubscription => _userSubscription;
  bool get isInitialized => _isInitialized;
  bool get isPremium => _userSubscription.isPremium;
  bool get isPurchasing => _isPurchasing;
  String? get lastErrorMessage => _lastErrorMessage;
  List<ProductDetails> get availableProducts => _productDetails;

  // ===== Initialization =====
  /// Inizializza il servizio di subscription
  Future<void> initialize() async {
    try {
      _inAppPurchase = InAppPurchase.instance;

      // Verifica se le in-app purchases sono disponibili
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        debugPrint(
            'In-app purchases not available on this device');
        _isInitialized = true;
        notifyListeners();
        return;
      }

      // Carica lo stato della subscription salvato
      await _loadSubscriptionState();

      // Ascolta i cambiamenti nelle subscription
      _inAppPurchase.purchaseStream
          .listen(_handlePurchaseUpdate)
          .onError((error) {
        debugPrint('Purchase stream error: $error');
      });

      // Query i prodotti disponibili
      await _queryProducts();

      // Verifica le subscription esistenti
      await _restorePurchases();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing subscription service: $e');
      _lastErrorMessage = 'Errore durante l\'inizializzazione: $e';
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ===== Product Query =====
  /// Query i prodotti disponibili dal Play Store
  Future<void> _queryProducts() async {
    try {
      final ProductDetailsResponse response =
          await _inAppPurchase
              .queryProductDetails(
                Set<String>.from(
                  SubscriptionProductIds.allProductIds,
                ),
              );

      if (response.error != null) {
        _lastErrorMessage = 'Errore nel caricamento dei prodotti';
        debugPrint(
            'Product query error: ${response.error}');
        notifyListeners();
        return;
      }

      _productDetails.clear();
      _productDetails.addAll(response.productDetails);

      debugPrint(
          'Loaded ${_productDetails.length} products');
      notifyListeners();
    } catch (e) {
      debugPrint('Error querying products: $e');
      _lastErrorMessage = 'Errore nel caricamento dei prodotti';
      notifyListeners();
    }
  }

  // ===== Purchase Flow =====
  /// Acquista una subscription
  Future<bool> purchaseSubscription(
    String productId,
  ) async {
    try {
      _isPurchasing = true;
      _lastErrorMessage = null;
      notifyListeners();

      // Verifica se i prodotti sono disponibili
      if (_productDetails.isEmpty) {
        _lastErrorMessage = 'Prodotti non disponibili. Assicurati di aver creato i prodotti in Play Console o usa un account di test.';
        _isPurchasing = false;
        notifyListeners();
        return false;
      }

      // Trova il prodotto
      ProductDetails? product;
      try {
        product = _productDetails.firstWhere((p) => p.id == productId);
      } catch (e) {
        product = null;
      }

      if (product == null) {
        _lastErrorMessage = 'Prodotto "$productId" non trovato. Prodotti disponibili: ${_productDetails.map((p) => p.id).join(", ")}';
        debugPrint('Available products: ${_productDetails.map((p) => p.id).toList()}');
        _isPurchasing = false;
        notifyListeners();
        return false;
      }

      // Avvia il purchase
      final purchaseParam = PurchaseParam(
        productDetails: product,
      );

      await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      return true;
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      _lastErrorMessage =
          'Errore durante l\'acquisto: ${e.toString()}';
      _isPurchasing = false;
      notifyListeners();
      return false;
    }
  }

  // ===== Purchase Handling =====
  /// Gestisce gli aggiornamenti delle purchase
  Future<void> _handlePurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Marca come premium
        await _markUserAsPremium(purchase);

        // Completa la purchase se necessario
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        _lastErrorMessage =
            'Errore: ${purchase.error?.message}';
        debugPrint(
            'Purchase error: ${purchase.error?.message}');
      } else if (purchase.status == PurchaseStatus.canceled) {
        _lastErrorMessage = 'Acquisto annullato';
      }
    }

    _isPurchasing = false;
    notifyListeners();
  }

  /// Marca l'utente come premium
  Future<void> _markUserAsPremium(
    PurchaseDetails purchase,
  ) async {
    try {
      // Determina il tipo di subscription
      final SubscriptionType type =
          purchase.productID ==
                  SubscriptionProductIds.monthly
              ? SubscriptionType.monthly
              : SubscriptionType.yearly;

      // Crea la subscription
      _userSubscription = UserSubscription(
        status: SubscriptionStatus.active,
        type: type,
        startDate: DateTime.now(),
        expiryDate: _calculateExpiryDate(type),
        isTrial: false,
        priceInCents: 299, // Placeholder - aggiornare da product details
        currency: 'EUR',
        productId: purchase.productID,
        purchaseToken: purchase.verificationData.localVerificationData,
      );

      // Salva lo stato
      await _saveSubscriptionState();

      // Disattiva Ads per utenti premium
      await AdsService().setAdsEnabled(false);

      notifyListeners();
      debugPrint('User marked as premium: $type');
    } catch (e) {
      debugPrint('Error marking user as premium: $e');
    }
  }

  /// Calcola la data di scadenza della subscription
  DateTime _calculateExpiryDate(SubscriptionType type) {
    final now = DateTime.now();
    return type == SubscriptionType.monthly
        ? now.add(const Duration(days: 30))
        : now.add(const Duration(days: 365));
  }

  // ===== Restore Purchases =====
  /// Ripristina le subscription precedenti
  Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('Purchases restored');
      return true;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      _lastErrorMessage =
          'Errore nel ripristino degli acquisti: $e';
      notifyListeners();
      return false;
    }
  }

  /// Ripristina le subscription precedenti (privato, usato durante l'inizializzazione)
  Future<void> _restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('Purchases restored');
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      _lastErrorMessage =
          'Errore nel ripristino degli acquisti';
      notifyListeners();
    }
  }

  // ===== Persistence =====
  /// Salva lo stato della subscription in SharedPreferences
  Future<void> _saveSubscriptionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'subscription_status',
        _userSubscription.status.toString(),
      );
      await prefs.setString(
        'subscription_type',
        _userSubscription.type.toString(),
      );

      if (_userSubscription.startDate != null) {
        await prefs.setInt(
          'subscription_start_date',
          _userSubscription.startDate!.millisecondsSinceEpoch,
        );
      }

      if (_userSubscription.expiryDate != null) {
        await prefs.setInt(
          'subscription_expiry_date',
          _userSubscription.expiryDate!.millisecondsSinceEpoch,
        );
      }

      await prefs.setString(
        'subscription_currency',
        _userSubscription.currency,
      );
      await prefs.setInt(
        'subscription_price_cents',
        _userSubscription.priceInCents,
      );

      debugPrint('Subscription state saved');
    } catch (e) {
      debugPrint('Error saving subscription state: $e');
    }
  }

  /// Carica lo stato della subscription da SharedPreferences
  Future<void> _loadSubscriptionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final statusString =
          prefs.getString('subscription_status');
      if (statusString == null) {
        return;
      }

      final status = SubscriptionStatus.values.firstWhere(
        (s) => s.toString() == statusString,
        orElse: () => SubscriptionStatus.none,
      );

      if (status == SubscriptionStatus.none) {
        return;
      }

      final typeString =
          prefs.getString('subscription_type');
      final type = typeString != null
          ? SubscriptionType.values.firstWhere(
              (t) => t.toString() == typeString,
              orElse: () => SubscriptionType.none,
            )
          : SubscriptionType.none;

      final startDateMs =
          prefs.getInt('subscription_start_date');
      final expiryDateMs =
          prefs.getInt('subscription_expiry_date');

      _userSubscription = UserSubscription(
        status: status,
        type: type,
        startDate: startDateMs != null
            ? DateTime.fromMillisecondsSinceEpoch(
                startDateMs)
            : null,
        expiryDate: expiryDateMs != null
            ? DateTime.fromMillisecondsSinceEpoch(
                expiryDateMs)
            : null,
        isTrial: false,
        priceInCents:
            prefs.getInt('subscription_price_cents') ?? 0,
        currency:
            prefs.getString('subscription_currency') ??
                'EUR',
      );

      // Se la subscription è scaduta, marcala come expired
      if (_userSubscription.expiryDate != null &&
          DateTime.now()
              .isAfter(_userSubscription.expiryDate!)) {
        _userSubscription = _userSubscription.copyWith(
          status: SubscriptionStatus.expired,
        );
        await _saveSubscriptionState();
        // Riattiva ads quando scaduta
        await AdsService().setAdsEnabled(true);
      } else {
        // Stato corrente: attiva/disattiva ads in base a premium
        await AdsService().setAdsEnabled(!_userSubscription.isPremium);
      }

      debugPrint('Loaded subscription state: $_userSubscription');
    } catch (e) {
      debugPrint('Error loading subscription state: $e');
    }
  }

  // ===== Utility Methods =====
  /// Cancella la subscription (lato client - la cancellazione vera avviene su Play Console)
  Future<void> cancelSubscription() async {
    try {
      _userSubscription = _userSubscription.copyWith(
        status: SubscriptionStatus.pendingCancellation,
        cancellationDate: DateTime.now(),
      );
      await _saveSubscriptionState();
      await AdsService().setAdsEnabled(true);
      notifyListeners();
      debugPrint('Subscription marked for cancellation');
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
    }
  }

  /// Resetta lo stato (per testing)
  Future<void> resetSubscription() async {
    try {
      _userSubscription = UserSubscription.none();
      await _saveSubscriptionState();
      await AdsService().setAdsEnabled(true);
      notifyListeners();
      debugPrint('Subscription reset');
    } catch (e) {
      debugPrint('Error resetting subscription: $e');
    }
  }
}
