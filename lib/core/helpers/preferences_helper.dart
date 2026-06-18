import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String keyStoreName = 'store_name';
  static const String keyStoreAddress = 'store_address';
  static const String keyStorePhone = 'store_phone';
  static const String keyThemeMode = 'theme_mode';

  static Future<String> getStoreName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyStoreName) ?? 'Warung Sembako';
  }

  static Future<void> setStoreName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyStoreName, value);
  }

  static Future<String> getStoreAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyStoreAddress) ?? 'Alamat Toko';
  }

  static Future<void> setStoreAddress(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyStoreAddress, value);
  }

  static Future<String> getStorePhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyStorePhone) ?? '-';
  }

  static Future<void> setStorePhone(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyStorePhone, value);
  }

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyThemeMode) ?? 'system';
  }

  static Future<void> setThemeMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyThemeMode, value);
  }
}
