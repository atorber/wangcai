import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityProvider extends ChangeNotifier {
  SecurityProvider() {
    _load();
  }

  static const _appLockKey = 'security_app_lock_enabled';
  static const _biometricKey = 'security_biometric_enabled';
  static const _privacyModeKey = 'security_privacy_mode_enabled';

  bool _appLockEnabled = false;
  bool _biometricEnabled = true;
  bool _privacyModeEnabled = false;
  bool _loaded = false;

  bool get appLockEnabled => _appLockEnabled;
  bool get biometricEnabled => _biometricEnabled;
  bool get privacyModeEnabled => _privacyModeEnabled;
  bool get loaded => _loaded;

  Future<void> setAppLockEnabled(bool value) async {
    _appLockEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockKey, value);
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    _biometricEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, value);
    notifyListeners();
  }

  Future<void> setPrivacyModeEnabled(bool value) async {
    _privacyModeEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyModeKey, value);
    notifyListeners();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _appLockEnabled = prefs.getBool(_appLockKey) ?? false;
    _biometricEnabled = prefs.getBool(_biometricKey) ?? true;
    _privacyModeEnabled = prefs.getBool(_privacyModeKey) ?? false;
    _loaded = true;
    notifyListeners();
  }
}
