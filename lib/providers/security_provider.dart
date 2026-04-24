import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityProvider extends ChangeNotifier {
  SecurityProvider() {
    _load();
  }

  static const _appLockKey = 'security_app_lock_enabled';
  static const _biometricKey = 'security_biometric_enabled';
  static const _privacyModeKey = 'security_privacy_mode_enabled';
  static const _pinCodeKey = 'security_pin_code';

  bool _appLockEnabled = false;
  bool _biometricEnabled = false;
  bool _privacyModeEnabled = false;
  String _pinCode = '';
  bool _loaded = false;

  bool get appLockEnabled => _appLockEnabled;
  bool get biometricEnabled => _biometricEnabled;
  bool get privacyModeEnabled => _privacyModeEnabled;
  bool get hasPinCode => _pinCode.isNotEmpty;
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

  Future<void> setPinCode(String pinCode) async {
    _pinCode = pinCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinCodeKey, pinCode);
    notifyListeners();
  }

  bool verifyPinCode(String input) {
    return _pinCode == input;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _appLockEnabled = prefs.getBool(_appLockKey) ?? false;
    _biometricEnabled = prefs.getBool(_biometricKey) ?? false;
    _privacyModeEnabled = prefs.getBool(_privacyModeKey) ?? false;
    _pinCode = prefs.getString(_pinCodeKey) ?? '';
    _loaded = true;
    notifyListeners();
  }
}
