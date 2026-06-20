import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late SharedPreferences _prefs;

  static const String _ipKey = 'pc_ip_address';
  static const String _portKey = 'pc_port';
  static const String _customMacrosKey = 'custom_macros';

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

  static List<String> get customMacros => _prefs.getStringList(_customMacrosKey) ?? [];
  static Future<void> setCustomMacros(List<String> value) async {
    await _prefs.setStringList(_customMacrosKey, value);
  }

  static String get micMuteBind => _prefs.getString('bind_mic_mute') ?? '';
  static Future<void> setMicMuteBind(String value) async {
    await _prefs.setString('bind_mic_mute', value);
  }

  static String get deafenBind => _prefs.getString('bind_deafen') ?? '';
  static Future<void> setDeafenBind(String value) async {
    await _prefs.setString('bind_deafen', value);
  }

  static String get cameraBind => _prefs.getString('bind_camera') ?? '';
  static Future<void> setCameraBind(String value) async {
    await _prefs.setString('bind_camera', value);
  }

  static List<String> get buttonLayout => _prefs.getStringList('button_layout') ?? [];
  static Future<void> setButtonLayout(List<String> value) async {
    await _prefs.setStringList('button_layout', value);
  }

  static List<String> get recentColors => _prefs.getStringList('recent_colors') ?? [];
  static Future<void> setRecentColors(List<String> value) async {
    await _prefs.setStringList('recent_colors', value);
  }
}
