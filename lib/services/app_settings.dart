import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const String _darkModeKey = 'settings_dark_mode';
  bool _isDarkMode = false;
  bool _loaded = false;

  bool get isDarkMode => _isDarkMode;
  bool get isLoaded => _loaded;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }
}