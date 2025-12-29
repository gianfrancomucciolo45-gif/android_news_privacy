import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePreset { defaultTheme, ocean, forest, sunset, purple, custom }

class ThemeCustomizationService {
  static final ThemeCustomizationService _instance =
      ThemeCustomizationService._internal();
  factory ThemeCustomizationService() => _instance;
  ThemeCustomizationService._internal();

  SharedPreferences? _prefs;

  final ValueNotifier<ThemePreset> currentPreset = ValueNotifier(
    ThemePreset.defaultTheme,
  );
  final ValueNotifier<Color> primaryColor = ValueNotifier(
    const Color(0xFF6750A4),
  );
  final ValueNotifier<Color> secondaryColor = ValueNotifier(
    const Color(0xFF625B71),
  );
  final ValueNotifier<bool> oledMode = ValueNotifier(false);

  // Preset colors
  static const Map<ThemePreset, Map<String, Color>> presetColors = {
    ThemePreset.defaultTheme: {
      'primary': Color(0xFF6750A4),
      'secondary': Color(0xFF625B71),
    },
    ThemePreset.ocean: {
      'primary': Color(0xFF0277BD),
      'secondary': Color(0xFF00ACC1),
    },
    ThemePreset.forest: {
      'primary': Color(0xFF2E7D32),
      'secondary': Color(0xFF558B2F),
    },
    ThemePreset.sunset: {
      'primary': Color(0xFFE64A19),
      'secondary': Color(0xFFFF6F00),
    },
    ThemePreset.purple: {
      'primary': Color(0xFF7B1FA2),
      'secondary': Color(0xFF9C27B0),
    },
  };

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    final presetIndex = _prefs!.getInt('theme_preset') ?? 0;
    currentPreset.value = ThemePreset.values[presetIndex];

    final primaryValue = _prefs!.getInt('primary_color');
    if (primaryValue != null) {
      primaryColor.value = Color(primaryValue);
    } else {
      primaryColor.value = presetColors[currentPreset.value]!['primary']!;
    }

    final secondaryValue = _prefs!.getInt('secondary_color');
    if (secondaryValue != null) {
      secondaryColor.value = Color(secondaryValue);
    } else {
      secondaryColor.value = presetColors[currentPreset.value]!['secondary']!;
    }

    oledMode.value = _prefs!.getBool('oled_mode') ?? false;
  }

  Future<void> setPreset(ThemePreset preset) async {
    currentPreset.value = preset;
    await _prefs?.setInt('theme_preset', preset.index);

    if (preset != ThemePreset.custom) {
      primaryColor.value = presetColors[preset]!['primary']!;
      secondaryColor.value = presetColors[preset]!['secondary']!;
      await _prefs?.setInt('primary_color', primaryColor.value.toARGB32());
      await _prefs?.setInt('secondary_color', secondaryColor.value.toARGB32());
    }
  }

  Future<void> setPrimaryColor(Color color) async {
    primaryColor.value = color;
    currentPreset.value = ThemePreset.custom;
    await _prefs?.setInt('primary_color', color.toARGB32());
    await _prefs?.setInt('theme_preset', ThemePreset.custom.index);
  }

  Future<void> setSecondaryColor(Color color) async {
    secondaryColor.value = color;
    currentPreset.value = ThemePreset.custom;
    await _prefs?.setInt('secondary_color', color.toARGB32());
    await _prefs?.setInt('theme_preset', ThemePreset.custom.index);
  }

  Future<void> setOledMode(bool enabled) async {
    oledMode.value = enabled;
    await _prefs?.setBool('oled_mode', enabled);
  }

  String getPresetName(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.defaultTheme:
        return 'Default';
      case ThemePreset.ocean:
        return 'Ocean';
      case ThemePreset.forest:
        return 'Forest';
      case ThemePreset.sunset:
        return 'Sunset';
      case ThemePreset.purple:
        return 'Purple';
      case ThemePreset.custom:
        return 'Custom';
    }
  }

  ColorScheme createLightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primaryColor.value,
      secondary: secondaryColor.value,
      brightness: Brightness.light,
    );
  }

  ColorScheme createDarkColorScheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor.value,
      secondary: secondaryColor.value,
      brightness: Brightness.dark,
    );

    if (oledMode.value) {
      return scheme.copyWith(
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: const Color(0xFF0A0A0A),
        surfaceContainer: const Color(0xFF121212),
        surfaceContainerHigh: const Color(0xFF1A1A1A),
        surfaceContainerHighest: const Color(0xFF222222),
      );
    }

    return scheme;
  }
}
