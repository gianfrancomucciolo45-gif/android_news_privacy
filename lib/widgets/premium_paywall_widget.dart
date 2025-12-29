// lib/widgets/premium_paywall_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';
import '../constants/monetization_constants.dart';

/// Widget paywall per premium subscription
class PremiumPaywallWidget extends StatefulWidget {
  /// Callback quando l'utente chiude il paywall
  final VoidCallback? onDismiss;

  /// Se true, mostra in modalità full screen (dialog)
  final bool isFullScreen;

  const PremiumPaywallWidget({
    super.key,
    this.onDismiss,
    this.isFullScreen = true,
  });

  @override
  State<PremiumPaywallWidget> createState() =>
      _PremiumPaywallWidgetState();
}

class _PremiumPaywallWidgetState extends State<PremiumPaywallWidget> {
  int _selectedTabIndex = 0; // 0 = monthly, 1 = yearly

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, subscriptionService, _) {
        if (subscriptionService.isPremium) {
          // Se già premium, non mostrare paywall
          return const SizedBox.shrink();
        }

        if (widget.isFullScreen) {
          return _buildFullScreenPaywall(context);
        } else {
          return _buildInlinePaywall(context);
        }
      },
    );
  }

  /// Paywall in full screen (dialog style)
  Widget _buildFullScreenPaywall(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildPaywallContent(context),
        ),
      ),
    );
  }

  /// Paywall inline (card style)
  Widget _buildInlinePaywall(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildPaywallContent(context),
      ),
    );
  }

  /// Contenuto principale del paywall
  Widget _buildPaywallContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                '✨ Android News Premium',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.isFullScreen)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDismiss?.call();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Descrizione
        const Text(
          'Goditi il massimo con l\'accesso illimitato a tutte le notizie senza pubblicità',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 24),

        // Features list
        _buildFeaturesList(),
        const SizedBox(height: 24),

        // Pricing tabs
        _buildPricingTabs(),
        const SizedBox(height: 24),

        // CTA Buttons
        _buildActionButtons(context),
      ],
    );
  }

  /// Lista dei benefici premium
  Widget _buildFeaturesList() {
    final features = [
      _PremiumFeature('🚫', 'Zero pubblicità', 'Leggi in pace senza interruzioni'),
      _PremiumFeature('📱', 'Lettura offline', 'Accedi ai tuoi articoli senza internet'),
      _PremiumFeature('❤️', 'Salvataggi illimitati', 'Colleziona tutti gli articoli che desideri'),
      _PremiumFeature('🔔', 'Notifiche prioritarie', 'Non perdere le breaking news più importanti'),
    ];

    return Column(
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          feature.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  /// Tab di scelta tra monthly e yearly
  Widget _buildPricingTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPricingOption(
              index: 0,
              label: 'Mensile',
              price: SubscriptionPrices.monthlyPrice,
              perMonth: '/mese',
              isSelected: _selectedTabIndex == 0,
              onTap: () {
                setState(() => _selectedTabIndex = 0);
              },
            ),
          ),
          Expanded(
            child: _buildPricingOption(
              index: 1,
              label: 'Annuale',
              price: SubscriptionPrices.yearlyPrice,
              perMonth: '/anno',
              isSelected: _selectedTabIndex == 1,
              onTap: () {
                setState(() => _selectedTabIndex = 1);
              },
              badge: 'SCONTO ${SubscriptionPrices.yearlyDiscountPercent}',
            ),
          ),
        ],
      ),
    );
  }

  /// Singola opzione di prezzo
  Widget _buildPricingOption({
    required int index,
    required String label,
    required String price,
    required String perMonth,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
            Text(
              perMonth,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.black54 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pulsanti d'azione
  Widget _buildActionButtons(BuildContext context) {
    final subscriptionService =
        Provider.of<SubscriptionService>(context, listen: false);

    final productId = _selectedTabIndex == 0
        ? SubscriptionProductIds.monthly
        : SubscriptionProductIds.yearly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subscribe button
        ElevatedButton(
          onPressed: () async {
            final success =
                await subscriptionService
                    .purchaseSubscription(productId);

            if (!mounted) return;

            if (success) {
              // Chiudi il paywall
              if (widget.isFullScreen) {
                Navigator.of(context).pop();
              }
              widget.onDismiss?.call();

              // Mostra messaggio di successo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '✅ Benvenuto in Premium! Goditi i vantaggi',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            } else {
              // Mostra errore
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '❌ Errore: ${subscriptionService.lastErrorMessage}',
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: subscriptionService.isPurchasing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
              : const Text(
                  'Prova gratis 7 giorni',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 12),

        // Dismiss button
        TextButton(
          onPressed: () {
            if (widget.isFullScreen) {
              Navigator.of(context).pop();
            }
            widget.onDismiss?.call();
          },
          child: const Text('Non ora'),
        ),

        // Terms and conditions
        const SizedBox(height: 12),
        Text(
          'Dopo il periodo di prova verranno addebitate le spese dell\'abbonamento. '
          'Cancella in qualunque momento',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

/// Helper class per le feature della lista premium
class _PremiumFeature {
  final String emoji;
  final String title;
  final String description;

  const _PremiumFeature(this.emoji, this.title, this.description);
}

/// Mostra il paywall in un dialog
Future<void> showPremiumPaywall(
  BuildContext context, {
  VoidCallback? onDismiss,
}) {
  return showDialog(
    context: context,
    builder: (context) => PremiumPaywallWidget(
      onDismiss: onDismiss,
      isFullScreen: true,
    ),
  );
}
