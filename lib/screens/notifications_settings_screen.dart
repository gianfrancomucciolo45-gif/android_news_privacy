import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../l10n/app_localizations.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  // Lista delle fonti disponibili (dovrebbe provenire da RssService)
  final List<Map<String, String>> _sources = [
    {'id': 'tuttoandroid', 'name': 'TuttoAndroid'},
    {'id': 'androidworld', 'name': 'AndroidWorld'},
    {'id': 'hdblog_android', 'name': 'HDblog Android'},
    {'id': 'androidiani', 'name': 'Androidiani'},
    {'id': 'hdblog', 'name': 'HDblog'},
    {'id': 'tecnoandroid', 'name': 'TecnoAndroid'},
    {'id': 'gizchina', 'name': 'GizChina'},
    {'id': 'xiaomitoday', 'name': 'XiaomiToday'},
    {'id': 'telefonino', 'name': 'Telefonino.net'},
    {'id': 'tomshw', 'name': "Tom's Hardware"},
    {'id': 'hwupgrade', 'name': 'HWUpgrade'},
    {'id': 'evosmart', 'name': 'EvoSmart'},
    {'id': 'dday', 'name': 'DDay.it'},
    {'id': 'tuttotech', 'name': 'TuttoTech'},
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.settingsNotifications ?? 'Notifiche'),
      ),
      body: !_notificationService.isInitialized
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Notifiche non disponibili',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Abilita i permessi notifiche nelle impostazioni del dispositivo',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // FCM Token (debug)
                if (_notificationService.fcmToken != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.vpn_key, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'FCM Token (Debug)',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _notificationService.fcmToken!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Breaking News
                _buildSectionHeader(context, 'Breaking News', Icons.notification_important),
                ValueListenableBuilder<bool>(
                  valueListenable: _notificationService.breakingNewsEnabled,
                  builder: (context, enabled, _) {
                    return SwitchListTile(
                      title: const Text('Notizie Urgenti'),
                      subtitle: const Text('Ricevi notifiche per breaking news importanti'),
                      value: enabled,
                      onChanged: (value) {
                        _notificationService.toggleBreakingNews(value);
                      },
                      secondary: Icon(
                        Icons.flash_on,
                        color: enabled ? theme.colorScheme.primary : Colors.grey,
                      ),
                    );
                  },
                ),
                
                const Divider(height: 32),
                
                // Fonti Preferite
                _buildSectionHeader(context, 'Fonti Preferite', Icons.star),
                ValueListenableBuilder<bool>(
                  valueListenable: _notificationService.favoriteSourcesEnabled,
                  builder: (context, enabled, _) {
                    return SwitchListTile(
                      title: const Text('Notifiche Fonti Preferite'),
                      subtitle: const Text('Ricevi notifiche dalle fonti selezionate sotto'),
                      value: enabled,
                      onChanged: (value) {
                        _notificationService.toggleFavoriteSources(value);
                      },
                      secondary: Icon(
                        Icons.bookmarks,
                        color: enabled ? theme.colorScheme.primary : Colors.grey,
                      ),
                    );
                  },
                ),
                
                const Divider(height: 32),
                
                // Selezione Fonti
                _buildSectionHeader(context, 'Seleziona Fonti', Icons.rss_feed),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Ricevi notifiche solo dalle fonti selezionate',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                
                ValueListenableBuilder<Set<String>>(
                  valueListenable: _notificationService.enabledSources,
                  builder: (context, enabledSources, _) {
                    return Column(
                      children: _sources.map((source) {
                        final isEnabled = enabledSources.contains(source['id']);
                        return CheckboxListTile(
                          title: Text(source['name']!),
                          value: isEnabled,
                          onChanged: (value) {
                            _notificationService.toggleSourceNotifications(
                              source['id']!,
                              value ?? false,
                            );
                          },
                          secondary: Icon(
                            Icons.newspaper,
                            color: isEnabled ? theme.colorScheme.primary : Colors.grey,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Info Card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Le notifiche vengono inviate quando ci sono nuovi articoli dalle fonti selezionate',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
