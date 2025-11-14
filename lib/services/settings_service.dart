import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class SettingsService {
  static const String _themeKey = 'theme_option';
  static const String _fontSizeKey = 'font_size';

  static Future<void> saveThemeOption(ThemeOption themeOption) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeOption.toString());
  }

  static Future<ThemeOption> getThemeOption() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? ThemeOption.system.toString();
    
    try {
      return ThemeOption.values.firstWhere((e) => e.toString() == themeString);
    } catch (e) {
      return ThemeOption.system; // fallback
    }
  }

  static Future<void> saveFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, fontSize);
  }

  static Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 16.0;
  }
}