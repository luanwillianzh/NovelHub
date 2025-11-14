import 'package:flutter/foundation.dart';

enum ThemeOption { system, light, dark }

class SettingsModel extends ChangeNotifier {
  ThemeOption _themeOption = ThemeOption.system;
  double _fontSize = 16.0;

  ThemeOption get themeOption => _themeOption;
  double get fontSize => _fontSize;

  void setThemeOption(ThemeOption option) {
    _themeOption = option;
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  // Method to get the actual brightness based on theme option and system
  Brightness getBrightnessForTheme(Brightness systemBrightness) {
    switch (_themeOption) {
      case ThemeOption.light:
        return Brightness.light;
      case ThemeOption.dark:
        return Brightness.dark;
      case ThemeOption.system:
      default:
        return systemBrightness;
    }
  }
}