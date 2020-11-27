import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppStateNotifier extends ChangeNotifier {
  String themeName = 'greenLightTheme';
  ThemeData theme = AppTheme.themes['greenLightTheme'];

  void updateThemeNoNotify(String themeName) {
    this.theme = AppTheme.themes[themeName];
    this.themeName = themeName;
  }

  void updateTheme(String themeName) {
    this.theme = AppTheme.themes[themeName];
    this.themeName = themeName;
    notifyListeners();
  }
}
