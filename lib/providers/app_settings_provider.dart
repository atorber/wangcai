import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  AppSettingsProvider() {
    _load();
  }

  static const _themeModeKey = 'app_settings_theme_mode';
  static const _profileNameKey = 'app_settings_profile_name';
  static const _profileTaglineKey = 'app_settings_profile_tagline';

  ThemeMode _themeMode = ThemeMode.system;
  String _profileName = '旺财';
  String _profileTagline = '本地优先 · 数据自主可控';
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  String get profileName => _profileName;
  String get profileTagline => _profileTagline;
  bool get loaded => _loaded;

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, value.name);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String tagline,
  }) async {
    _profileName = name;
    _profileTagline = tagline;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileNameKey, name);
    await prefs.setString(_profileTaglineKey, tagline);
    notifyListeners();
  }

  String themeModeLabel() {
    switch (_themeMode) {
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawMode = prefs.getString(_themeModeKey);
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == rawMode,
      orElse: () => ThemeMode.system,
    );
    _profileName = prefs.getString(_profileNameKey) ?? _profileName;
    _profileTagline = prefs.getString(_profileTaglineKey) ?? _profileTagline;
    _loaded = true;
    notifyListeners();
  }
}
