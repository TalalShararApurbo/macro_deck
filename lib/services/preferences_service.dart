import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late SharedPreferences _prefs;

  static const String _ipKey = 'pc_ip_address';
  static const String _portKey = 'pc_port';

  // Call this method in main() before runApp
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String get pcIpAddress => _prefs.getString(_ipKey) ?? '';
  static Future<void> setPcIpAddress(String value) async {
    await _prefs.setString(_ipKey, value);
  }

  static String get pcPort => _prefs.getString(_portKey) ?? '';
  static Future<void> setPcPort(String value) async {
    await _prefs.setString(_portKey, value);
  }
}
