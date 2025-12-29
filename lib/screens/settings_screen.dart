import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/cache_service.dart';
import '../services/settings_service.dart';
import '../services/subscription_service.dart';
import '../widgets/premium_paywall_widget.dart';
import 'sources_settings_screen.dart';
import 'theme_customization_screen.dart';
import 'notifications_settings_screen.dart';
import 'background_sync_settings_screen.dart';
import 'contact_screen.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CacheService _cacheService = CacheService();
  final SettingsService _settings = SettingsService();
  double _cacheSize = 0.0;
  int _cacheLimit = 50;
  DateTime? _lastCacheTime;
  bool _isLoading = true;
  ThemeMode _themeMode = ThemeMode.system;
  double _textScale = 1.0;
  bool _gridLayout = false;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    setState(() => _isLoading = true);

    final size = await _cacheService.getCacheSize();
    final limit = await _cacheService.getCacheLimit();
    final lastTime = await _cacheService.getLastCacheTime();
    _themeMode = _settings.themeMode.value;
    _textScale = _settings.textScale.value;
    _gridLayout = _settings.gridLayout.value;

    setState(() {
      _cacheSize = size;
      _cacheLimit = limit;
      _lastCacheTime = lastTime;
      _isLoading = false;
    });
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancella cache'),
        content: const Text(
          'Vuoi davvero cancellare tutti gli articoli salvati in cache?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancella'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _cacheService.clearCache();
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cancellata con successo'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadCacheInfo();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante la cancellazione'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateCacheLimit(int newLimit) async {
    final success = await _cacheService.setCacheLimit(newLimit);
    if (success) {
      setState(() {
        _cacheLimit = newLimit;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Limite cache impostato a $newLimit MB'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm', 'it_IT');

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Sezione Premium
                Consumer<SubscriptionService>(
                  builder: (context, subscriptionService, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscriptionService.isPremium ? 'Premium Attivo' : 'Diventa Premium',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: subscriptionService.isPremium ? 4 : 2,
                          color: subscriptionService.isPremium
                              ? colorScheme.primaryContainer
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      subscriptionService.isPremium
                                          ? Icons.stars
                                          : Icons.star_border,
                                      color: subscriptionService.isPremium
                                          ? Colors.amber
                                          : null,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            subscriptionService.isPremium
                                                ? 'Sei Premium!'
                                                : 'Android News Premium',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            subscriptionService.isPremium
                                                ? 'Goditi tutti i vantaggi'
                                                : 'Zero pubblicità e funzioni esclusive',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (!subscriptionService.isPremium) ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  _buildPremiumFeature(
                                      '🚫', 'Zero pubblicità', colorScheme),
                                  _buildPremiumFeature(
                                      '📱', 'Lettura offline illimitata', colorScheme),
                                  _buildPremiumFeature(
                                      '❤️', 'Salvataggi illimitati', colorScheme),
                                  _buildPremiumFeature(
                                      '🔔', 'Notifiche prioritarie', colorScheme),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () async {
                                      await showPremiumPaywall(context);
                                    },
                                    icon: const Icon(Icons.workspace_premium),
                                    label: const Text('Scopri Premium'),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 48),
                                      backgroundColor: Colors.blue,
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: colorScheme.primary, size: 20),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text('Nessuna pubblicità'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: colorScheme.primary, size: 20),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text('Tutte le funzioni sbloccate'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Gestisci Abbonamento'),
                                          content: const Text(
                                            'Vuoi ripristinare gli acquisti o annullare l\'abbonamento?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Chiudi'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(context, true);
                                                final success =
                                                    await subscriptionService
                                                        .restorePurchases();
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(success
                                                          ? '✅ Acquisti ripristinati'
                                                          : '❌ Nessun acquisto trovato'),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text('Ripristina'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.settings),
                                    label: const Text('Gestisci Abbonamento'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 48),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  },
                ),

                // Sezione Personalizzazione
                Text(
                  'Personalizzazione',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Tema
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tema',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto),
                              label: Text('Sistema'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.wb_sunny_outlined),
                              label: Text('Chiaro'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.nights_stay_outlined),
                              label: Text('Scuro'),
                            ),
                          ],
                          selected: {_themeMode},
                          onSelectionChanged: (s) async {
                            final mode = s.first;
                            setState(() => _themeMode = mode);
                            await _settings.setThemeMode(mode);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Advanced Themes
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Personalizzazione Tema'),
                    subtitle: const Text('Colori, preset e modalità OLED'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ThemeCustomizationScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Notifiche
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(AppLocalizations.of(context)?.settingsNotifications ?? 'Notifiche'),
                    subtitle: const Text('Breaking news e fonti preferite'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationsSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Background Sync
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('Sincronizzazione in Background'),
                    subtitle: const Text('Sync automatico e intelligente'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const BackgroundSyncSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Layout e testo
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Layout e Testo',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Layout a griglia'),
                          subtitle: const Text(
                            'Mostra le notizie in due colonne',
                          ),
                          value: _gridLayout,
                          onChanged: (v) async {
                            setState(() => _gridLayout = v);
                            await _settings.setGridLayout(v);
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dimensione testo: ${((_textScale) * 100).round()}%',
                        ),
                        Slider(
                          value: _textScale,
                          min: 0.9,
                          max: 1.3,
                          divisions: 8,
                          label: '${(_textScale * 100).round()}% ',
                          onChanged: (v) {
                            setState(() => _textScale = v);
                          },
                          onChangeEnd: (v) async {
                            await _settings.setTextScale(v);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Gestione Fonti
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.rss_feed_outlined),
                    title: const Text('Selezione e ordine fonti'),
                    subtitle: const Text(
                      'Scegli quali fonti mostrare e riordinali',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      final changed = await navigator.push(
                        MaterialPageRoute(
                          builder: (_) => const SourcesSettingsScreen(),
                        ),
                      );
                      if (changed == true && mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Fonti aggiornate'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 24),
                // Sezione Cache
                Text(
                  'Gestione Cache',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Info cache
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Dimensione cache:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${_cacheSize.toStringAsFixed(2)} MB',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Limite cache:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '$_cacheLimit MB',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (_lastCacheTime != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Ultimo aggiornamento:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                dateFormat.format(_lastCacheTime!),
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Limite cache slider
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Limite cache: $_cacheLimit MB',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _cacheLimit.toDouble(),
                          min: 10,
                          max: 200,
                          divisions: 19,
                          label: '$_cacheLimit MB',
                          onChanged: (value) {
                            setState(() {
                              _cacheLimit = value.round();
                            });
                          },
                          onChangeEnd: (value) {
                            _updateCacheLimit(value.round());
                          },
                        ),
                        Text(
                          'Limita la quantità di dati salvati in cache per la modalità offline',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Pulsante clear cache
                FilledButton.icon(
                  onPressed: _cacheSize > 0 ? _clearCache : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Cancella cache'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.orange,
                  ),
                ),

                const SizedBox(height: 32),

                // Info app
                Text(
                  'Informazioni',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Android News',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Versione 0.3.0',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'App per rimanere aggiornati sulle ultime notizie Android e tecnologia.',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ListTile(
                          leading: const Icon(Icons.contact_mail),
                          title: const Text('Contatti / Trasparenza'),
                          subtitle: const Text(
                            'Email, sito, fonti e segnalazioni',
                          ),
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            await navigator.push(
                              MaterialPageRoute(
                                builder: (_) => const ContactScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPremiumFeature(String emoji, String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
