import 'package:flutter/material.dart';
import '../services/rss_service.dart';
import '../services/settings_service.dart';

class SourcesSettingsScreen extends StatefulWidget {
  const SourcesSettingsScreen({super.key});

  @override
  State<SourcesSettingsScreen> createState() => _SourcesSettingsScreenState();
}

class _SourcesSettingsScreenState extends State<SourcesSettingsScreen> {
  late List<String> _order;
  late Set<String> _enabled;

  @override
  void initState() {
    super.initState();
    final settings = SettingsService();
    _order = settings.sourceOrder.value.isEmpty
        ? RssService.sources.keys.toList()
        : List<String>.from(settings.sourceOrder.value);
    _enabled = settings.enabledSources.value.isEmpty
        ? RssService.sources.keys.toSet()
        : settings.enabledSources.value.toSet();
  }

  Future<void> _persist() async {
    final settings = SettingsService();
    await settings.setSourceOrder(_order);
    await settings.setEnabledSources(_enabled.toList());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fonti Preferite'),
        actions: [
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _persist();
              if (mounted) navigator.pop(true);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Abilita/disabilita le fonti e trascina per riordinarle. L’ordine influenza la priorità di fetch.',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _order.removeAt(oldIndex);
                  _order.insert(newIndex, item);
                });
              },
              children: [
                for (final key in _order)
                  Card(
                    key: ValueKey(key),
                    child: SwitchListTile(
                      title: Text(RssService.sources[key]?.name ?? key),
                      subtitle: Text(RssService.sources[key]?.url ?? ''),
                      value: _enabled.contains(key),
                      onChanged: (v) {
                        setState(() {
                          if (v) {
                            _enabled.add(key);
                          } else {
                            _enabled.remove(key);
                          }
                        });
                      },
                      secondary: const Icon(Icons.drag_handle),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
