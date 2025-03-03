import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeProvider extends StatelessWidget {
  AppThemeProvider({super.key, required BuildContext context, required this.builder}) {
    SharedPreferences preferences = context.read<SharedPreferences>();
    String themeName = '';

    if (!preferences.containsKey('theme')) {
      if (PlatformDispatcher.instance.platformBrightness == Brightness.light) {
        preferences.setString('theme', 'dodoLightTheme');
        themeName = 'dodoLightTheme';
      } else {
        preferences.setString('theme', 'dodoDarkTheme');
        themeName = 'dodoDarkTheme';
      }
    } else {
      themeName = preferences.getString('theme')!;
    }

    _appTheme = AppThemeState(ThemeName.fromString(themeName));
  }

  late final AppThemeState _appTheme;
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _appTheme,
      builder: (context, _) => DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          if (lightDynamic != null && !AppTheme.themes.containsKey(ThemeName.lightDynamic)) {
            AppTheme.addDynamicThemes(lightDynamic, darkDynamic!);
          }
          return builder(context);
        },
      ),
    );
  }
}

class AppThemeState extends ChangeNotifier {
  AppThemeState(this._themeName);

  ThemeName _themeName;

  ThemeName get themeName => AppTheme.themes.containsKey(_themeName)
      ? _themeName
      : _themeName.brightness == Brightness.dark
          ? ThemeName.dodoDark
          : ThemeName.dodoLight;

  ThemeData get theme {
    return AppTheme.themes[themeName] ?? AppTheme.generateThemeData(ThemeName.greenLight, Colors.lightGreen).value;
  }

  set themeName(ThemeName newTheme) {
    _themeName = newTheme;
    SharedPreferences.getInstance().then((value) => value.setString('theme', newTheme.storageName));
    notifyListeners();
  }
}
