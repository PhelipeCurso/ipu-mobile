// lib/theme_notifier.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('modo_escuro') ?? false;
    value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('modo_escuro', isDark);
    value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}
