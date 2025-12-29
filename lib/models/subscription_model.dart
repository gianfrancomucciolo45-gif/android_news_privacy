// lib/models/subscription_model.dart

// Model per rappresentare lo stato di subscription dell'utente

// Stato della subscription
enum SubscriptionStatus {
  /// Nessuna subscription (free tier)
  none,
  
  /// In prova gratuita
  trial,
  
  /// Subscription attiva
  active,
  
  /// Subscription in cancellazione (ma ancora attiva fino alla data di scadenza)
  pendingCancellation,
  
  /// Subscription scaduta/cancellata
  expired,
}

/// Tipo di subscription
enum SubscriptionType {
  /// Nessuna subscription
  none,
  
  /// Monthly subscription
  monthly,
  
  /// Yearly subscription
  yearly,
}

/// Model per la subscription dell'utente
class UserSubscription {
  /// Status della subscription
  final SubscriptionStatus status;
  
  /// Tipo di subscription (monthly, yearly, none)
  final SubscriptionType type;
  
  /// Data di inizio subscription
  final DateTime? startDate;
  
  /// Data di scadenza subscription
  final DateTime? expiryDate;
  
  /// Data di annullamento (se cancellata ma ancora attiva)
  final DateTime? cancellationDate;
  
  /// Se è prova gratuita
  final bool isTrial;
  
  /// Data di inizio prova
  final DateTime? trialStartDate;
  
  /// Data di fine prova
  final DateTime? trialEndDate;
  
  /// Prezzo pagato (in centesimi per evitare decimali)
  final int priceInCents;
  
  /// Valuta ISO (es. EUR, USD)
  final String currency;
  
  /// Product ID da Play Store
  final String? productId;
  
  /// Purchase token
  final String? purchaseToken;

  UserSubscription({
    required this.status,
    required this.type,
    this.startDate,
    this.expiryDate,
    this.cancellationDate,
    required this.isTrial,
    this.trialStartDate,
    this.trialEndDate,
    required this.priceInCents,
    required this.currency,
    this.productId,
    this.purchaseToken,
  });

  /// Se l'utente è premium (subscription attiva)
  bool get isPremium {
    return status == SubscriptionStatus.active ||
        status == SubscriptionStatus.pendingCancellation;
  }

  /// Se la subscription è scaduta
  bool get isExpired {
    return status == SubscriptionStatus.expired;
  }

  /// Se è ancora in prova gratuita
  bool get isActivelyOnTrial {
    if (!isTrial) return false;
    if (trialEndDate == null) return false;
    return DateTime.now().isBefore(trialEndDate!);
  }

  /// Giorni rimanenti di subscription (null se scaduta o nessuna)
  int? get daysRemaining {
    if (!isPremium || expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  /// Prezzo formattato (es. "2,99 €")
  String get formattedPrice {
    final doublePrice = priceInCents / 100.0;
    return '$doublePrice $currency';
  }

  /// Copia con modifche
  UserSubscription copyWith({
    SubscriptionStatus? status,
    SubscriptionType? type,
    DateTime? startDate,
    DateTime? expiryDate,
    DateTime? cancellationDate,
    bool? isTrial,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    int? priceInCents,
    String? currency,
    String? productId,
    String? purchaseToken,
  }) {
    return UserSubscription(
      status: status ?? this.status,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      cancellationDate: cancellationDate ?? this.cancellationDate,
      isTrial: isTrial ?? this.isTrial,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      priceInCents: priceInCents ?? this.priceInCents,
      currency: currency ?? this.currency,
      productId: productId ?? this.productId,
      purchaseToken: purchaseToken ?? this.purchaseToken,
    );
  }

  /// Crea default (nessuna subscription)
  factory UserSubscription.none() {
    return UserSubscription(
      status: SubscriptionStatus.none,
      type: SubscriptionType.none,
      isTrial: false,
      priceInCents: 0,
      currency: 'EUR',
    );
  }

  @override
  String toString() {
    return 'UserSubscription('
        'status: $status, '
        'type: $type, '
        'isPremium: $isPremium, '
        'daysRemaining: $daysRemaining'
        ')';
  }
}
