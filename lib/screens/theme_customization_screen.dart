import 'package:flutter/material.dart';
import '../services/theme_customization_service.dart';
import '../widgets/color_picker_dialog.dart';

class ThemeCustomizationScreen extends StatefulWidget {
  const ThemeCustomizationScreen({super.key});

  @override
  State<ThemeCustomizationScreen> createState() =>
      _ThemeCustomizationScreenState();
}

class _ThemeCustomizationScreenState extends State<ThemeCustomizationScreen> {
  final ThemeCustomizationService _themeService = ThemeCustomizationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personalizzazione Tema')),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _themeService.currentPreset,
          _themeService.primaryColor,
          _themeService.secondaryColor,
          _themeService.oledMode,
        ]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Theme Presets
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temi Predefiniti',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: ThemePreset.values.map((preset) {
                          if (preset == ThemePreset.custom) {
                            return const SizedBox.shrink();
                          }
                          final isSelected =
                              _themeService.currentPreset.value == preset;
                          final colors =
                              ThemeCustomizationService.presetColors[preset]!;

                          return GestureDetector(
                            onTap: () => _themeService.setPreset(preset),
                            child: Container(
                              width: 100,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colors['primary']!,
                                    colors['secondary']!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _themeService.getPresetName(preset),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Custom Colors
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Colori Personalizzati',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      // Primary Color
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _themeService.primaryColor.value,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 2,
                            ),
                          ),
                        ),
                        title: const Text('Colore Primario'),
                        subtitle: Text(
                          '#${_themeService.primaryColor.value.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: () async {
                          final color = await showDialog<Color>(
                            context: context,
                            builder: (context) => ColorPickerDialog(
                              initialColor: _themeService.primaryColor.value,
                              title: 'Seleziona Colore Primario',
                            ),
                          );
                          if (color != null) {
                            _themeService.setPrimaryColor(color);
                          }
                        },
                      ),

                      // Secondary Color
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _themeService.secondaryColor.value,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 2,
                            ),
                          ),
                        ),
                        title: const Text('Colore Secondario'),
                        subtitle: Text(
                          '#${_themeService.secondaryColor.value.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: () async {
                          final color = await showDialog<Color>(
                            context: context,
                            builder: (context) => ColorPickerDialog(
                              initialColor: _themeService.secondaryColor.value,
                              title: 'Seleziona Colore Secondario',
                            ),
                          );
                          if (color != null) {
                            _themeService.setSecondaryColor(color);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // OLED Mode
              Card(
                child: SwitchListTile(
                  title: const Text('Modalità OLED'),
                  subtitle: const Text('Nero puro per schermi OLED'),
                  value: _themeService.oledMode.value,
                  onChanged: (value) => _themeService.setOledMode(value),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
