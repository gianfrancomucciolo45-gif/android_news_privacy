// lib/screens/background_sync_settings_screen.dart

import 'package:flutter/material.dart';
import '../services/background_sync_service.dart';
import '../l10n/app_localizations.dart';

class BackgroundSyncSettingsScreen extends StatefulWidget {
  const BackgroundSyncSettingsScreen({super.key});

  @override
  State<BackgroundSyncSettingsScreen> createState() => _BackgroundSyncSettingsScreenState();
}

class _BackgroundSyncSettingsScreenState extends State<BackgroundSyncSettingsScreen> {
  final BackgroundSyncService _syncService = BackgroundSyncService();
  
  bool _syncEnabled = true;
  int _syncFrequency = 4;
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final stats = await _syncService.getStats();
    
    setState(() {
      _syncEnabled = stats['enabled'] ?? true;
      _syncFrequency = stats['frequency_hours'] ?? 4;
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _toggleSync(bool value) async {
    await _syncService.setEnabled(value);
    setState(() => _syncEnabled = value);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value 
              ? AppLocalizations.of(context)!.backgroundSyncEnabled
              : AppLocalizations.of(context)!.backgroundSyncDisabled,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateFrequency(int hours) async {
    await _syncService.setSyncFrequency(hours);
    setState(() => _syncFrequency = hours);
  }

  Future<void> _startManualSync() async {
    await _syncService.startManualSync(preloadImages: true);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.manualSyncStarted),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatLastSync(int timestamp) {
    if (timestamp == 0) return AppLocalizations.of(context)!.never;
    
    final lastSync = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = DateTime.now().difference(lastSync);
    
    if (diff.inMinutes < 1) return AppLocalizations.of(context)!.justNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes} min fa';
    if (diff.inHours < 24) return '${diff.inHours} h fa';
    return '${diff.inDays} giorni fa';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.backgroundSyncSettings),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backgroundSyncSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Abilita/Disabilita Background Sync
          Card(
            child: SwitchListTile(
              title: Text(
                l10n.enableBackgroundSync,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(l10n.syncArticlesAutomatically),
              value: _syncEnabled,
              onChanged: _toggleSync,
              secondary: Icon(
                _syncEnabled ? Icons.sync : Icons.sync_disabled,
                color: _syncEnabled ? theme.colorScheme.primary : null,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Frequenza Sync
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.syncFrequency,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.every} $_syncFrequency ${l10n.hours}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: _syncFrequency.toDouble(),
                    min: 1,
                    max: 24,
                    divisions: 23,
                    label: '$_syncFrequency ${l10n.hours}',
                    onChanged: _syncEnabled 
                      ? (value) => _updateFrequency(value.round())
                      : null,
                  ),
                  Text(
                    l10n.smartSyncDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Statistiche
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.syncStatistics,
                    style: theme.textTheme.titleMedium,
                  ),
                  const Divider(),
                  _StatRow(
                    icon: Icons.access_time,
                    label: l10n.lastSync,
                    value: _formatLastSync(_stats['last_sync'] ?? 0),
                  ),
                  _StatRow(
                    icon: Icons.today,
                    label: l10n.syncsToday,
                    value: '${_stats['sync_count_today'] ?? 0}',
                  ),
                  _StatRow(
                    icon: Icons.article,
                    label: l10n.articlesReadToday,
                    value: '${_stats['daily_reads'] ?? 0}',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sync Manuale
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_download),
              title: Text(l10n.manualSync),
              subtitle: Text(l10n.downloadLatestArticles),
              trailing: ElevatedButton.icon(
                onPressed: _startManualSync,
                icon: const Icon(Icons.sync),
                label: Text(l10n.syncNow),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Informazioni
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.howItWorks,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.backgroundSyncInfo,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.battery_std,
                        label: l10n.batteryFriendly,
                      ),
                      _InfoChip(
                        icon: Icons.wifi,
                        label: l10n.wifiOnly,
                      ),
                      _InfoChip(
                        icon: Icons.smart_toy,
                        label: l10n.smartTiming,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      labelStyle: theme.textTheme.labelSmall,
      visualDensity: VisualDensity.compact,
    );
  }
}
