import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _keyThemeMode = 'theme_mode'; // system|light|dark
  static const _keyTextScale = 'text_scale'; // double
  static const _keyGridLayout = 'grid_layout'; // bool
  static const _keyEnabledSources = 'enabled_sources'; // List<String>
  static const _keySourceOrder = 'source_order'; // List<String>

  late SharedPreferences _prefs;

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
  final ValueNotifier<double> textScale = ValueNotifier<double>(1.0);
  final ValueNotifier<bool> gridLayout = ValueNotifier<bool>(false);
  final ValueNotifier<List<String>> enabledSources = ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<List<String>> sourceOrder = ValueNotifier<List<String>>(<String>[]);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Theme mode
    final themeStr = _prefs.getString(_keyThemeMode) ?? 'system';
    switch (themeStr) {
      case 'light':
        themeMode.value = ThemeMode.light;
        break;
      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;
      default:
        themeMode.value = ThemeMode.system;
    }

    // Text scale
    textScale.value = _prefs.getDouble(_keyTextScale) ?? 1.0;

    // Grid layout
    gridLayout.value = _prefs.getBool(_keyGridLayout) ?? false;

    // Sources
    enabledSources.value = List<String>.from(_prefs.getStringList(_keyEnabledSources) ?? const <String>[]);
    sourceOrder.value = List<String>.from(_prefs.getStringList(_keySourceOrder) ?? const <String>[]);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final str = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await _prefs.setString(_keyThemeMode, str);
  }

  Future<void> setTextScale(double scale) async {
    textScale.value = scale;
    await _prefs.setDouble(_keyTextScale, scale);
  }

  Future<void> setGridLayout(bool isGrid) async {
    gridLayout.value = isGrid;
    await _prefs.setBool(_keyGridLayout, isGrid);
  }

  Future<void> setEnabledSources(List<String> keys) async {
    enabledSources.value = List<String>.from(keys);
    await _prefs.setStringList(_keyEnabledSources, enabledSources.value);
  }

  Future<void> setSourceOrder(List<String> keys) async {
    sourceOrder.value = List<String>.from(keys);
    await _prefs.setStringList(_keySourceOrder, sourceOrder.value);
  }
}
