import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/settings_model.dart';
import 'services/novel_database_provider.dart';
import 'services/settings_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SettingsModel _settingsModel;
  late NovelDatabaseProvider _novelDatabaseProvider;

  @override
  void initState() {
    super.initState();
    _settingsModel = SettingsModel();
    _novelDatabaseProvider = NovelDatabaseProvider();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final themeOption = await SettingsService.getThemeOption();
    final fontSize = await SettingsService.getFontSize();
    
    setState(() {
      _settingsModel.setThemeOption(themeOption);
      _settingsModel.setFontSize(fontSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _settingsModel),
        ChangeNotifierProvider.value(value: _novelDatabaseProvider),
      ],
      child: Consumer2<SettingsModel, NovelDatabaseProvider>(
        builder: (context, settingsModel, novelDbProvider, child) {
          return MaterialApp(
            title: 'Novel Reader',
            theme: _buildTheme(Brightness.light, settingsModel),
            darkTheme: _buildTheme(Brightness.dark, settingsModel),
            themeMode: _getThemeMode(settingsModel.themeOption),
            debugShowCheckedModeBanner: false,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }

  ThemeMode _getThemeMode(ThemeOption themeOption) {
    switch (themeOption) {
      case ThemeOption.light:
        return ThemeMode.light;
      case ThemeOption.dark:
        return ThemeMode.dark;
      case ThemeOption.system:
      default:
        return ThemeMode.system;
    }
  }

  ThemeData _buildTheme(Brightness brightness, SettingsModel settingsModel) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: brightness,
      ),
      // Default text style that respects font size setting
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: settingsModel.fontSize),
        bodyMedium: TextStyle(fontSize: settingsModel.fontSize * 0.85),
        bodySmall: TextStyle(fontSize: settingsModel.fontSize * 0.75),
      ),
    );
  }
}