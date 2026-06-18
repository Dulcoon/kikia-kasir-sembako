import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../helpers/preferences_helper.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final themeStr = await PreferencesHelper.getThemeMode();
    state = _parseThemeMode(themeStr);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await PreferencesHelper.setThemeMode(mode.name);
  }

  ThemeMode _parseThemeMode(String val) {
    switch (val) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
