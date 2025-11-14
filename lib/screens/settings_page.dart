import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsModel>(
      builder: (context, settingsModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Theme selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Theme',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RadioListTile<ThemeOption>(
                          title: const Text('System Default'),
                          value: ThemeOption.system,
                          groupValue: settingsModel.themeOption,
                          onChanged: (ThemeOption? value) {
                            if (value != null) {
                              settingsModel.setThemeOption(value);
                              SettingsService.saveThemeOption(value);
                            }
                          },
                        ),
                        RadioListTile<ThemeOption>(
                          title: const Text('Light'),
                          value: ThemeOption.light,
                          groupValue: settingsModel.themeOption,
                          onChanged: (ThemeOption? value) {
                            if (value != null) {
                              settingsModel.setThemeOption(value);
                              SettingsService.saveThemeOption(value);
                            }
                          },
                        ),
                        RadioListTile<ThemeOption>(
                          title: const Text('Dark'),
                          value: ThemeOption.dark,
                          groupValue: settingsModel.themeOption,
                          onChanged: (ThemeOption? value) {
                            if (value != null) {
                              settingsModel.setThemeOption(value);
                              SettingsService.saveThemeOption(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Text',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Font size selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Font Size',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Small (${settingsModel.fontSize.round()}px)'),
                            Expanded(
                              child: Slider(
                                value: settingsModel.fontSize,
                                min: 12.0,
                                max: 24.0,
                                divisions: 12, // (24-12) = 12 steps
                                label: settingsModel.fontSize.round().toString(),
                                onChanged: (double value) {
                                  settingsModel.setFontSize(value);
                                  SettingsService.saveFontSize(value);
                                },
                              ),
                            ),
                            const Text('Large'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}