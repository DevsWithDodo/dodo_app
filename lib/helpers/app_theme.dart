import 'package:flutter/material.dart';

enum ThemeType {
  simpleColor(false),
  dualColor(true),
  gradient(true),
  dynamic(true);

  const ThemeType(this.premium);
  final bool premium;
}

enum ThemeName {
  pinkLight(Brightness.light, ThemeType.simpleColor, 'pinkLightTheme'),
  pinkDark(Brightness.dark, ThemeType.simpleColor, 'pinkDarkTheme'),
  seaBlueLight(Brightness.light, ThemeType.simpleColor, 'seaBlueLightTheme'),
  seaBlueDark(Brightness.dark, ThemeType.simpleColor, 'seaBlueDarkTheme'),
  greenLight(Brightness.light, ThemeType.simpleColor, 'greenLightTheme'),
  greenDark(Brightness.dark, ThemeType.simpleColor, 'greenDarkTheme'),
  amberLight(Brightness.light, ThemeType.simpleColor, 'amberLightTheme'),
  amberDark(Brightness.dark, ThemeType.simpleColor, 'amberDarkTheme'),
  orangeLight(Brightness.light, ThemeType.dualColor, 'orangeLightTheme'),
  orangeDark(Brightness.dark, ThemeType.dualColor, 'orangeDarkTheme'),
  dodoLight(Brightness.light, ThemeType.dualColor, 'dodoLightTheme'),
  dodoDark(Brightness.dark, ThemeType.dualColor, 'dodoDarkTheme'),
  endlessLight(Brightness.light, ThemeType.dualColor, 'endlessLightTheme'),
  endlessDark(Brightness.dark, ThemeType.dualColor, 'endlessDarkTheme'),
  celestialLight(Brightness.light, ThemeType.dualColor, 'celestialLightTheme'),
  celestialDark(Brightness.dark, ThemeType.dualColor, 'celestialDarkTheme'),
  roseannaGradientLight(Brightness.light, ThemeType.gradient, 'roseannaGradientLightTheme'),
  roseannaGradientDark(Brightness.dark, ThemeType.gradient, 'roseannaGradientDarkTheme'),
  passionateBedGradientLight(Brightness.light, ThemeType.gradient, 'passionateBedGradientLightTheme'),
  passionateBedGradientDark(Brightness.dark, ThemeType.gradient, 'passionateBedGradientDarkTheme'),
  plumGradientLight(Brightness.light, ThemeType.gradient, 'plumGradientLightTheme'),
  plumGradientDark(Brightness.dark, ThemeType.gradient, 'plumGradientDarkTheme'),
  sexyBlueGradientLight(Brightness.light, ThemeType.gradient, 'sexyBlueGradientLightTheme'),
  sexyBlueGradientDark(Brightness.dark, ThemeType.gradient, 'sexyBlueGradientDarkTheme'),
  endlessGradientLight(Brightness.light, ThemeType.gradient, 'endlessGradientLightTheme'),
  endlessGradientDark(Brightness.dark, ThemeType.gradient, 'endlessGradientDarkTheme'),
  greenGradientLight(Brightness.light, ThemeType.gradient, 'greenGradientLightTheme'),
  greenGradientDark(Brightness.dark, ThemeType.gradient, 'greenGradientDarkTheme'),
  yellowGradientLight(Brightness.light, ThemeType.gradient, 'yellowGradientLightTheme'),
  yellowGradientDark(Brightness.dark, ThemeType.gradient, 'yellowGradientDarkTheme'),
  orangeGradientLight(Brightness.light, ThemeType.gradient, 'orangeGradientLightTheme'),
  orangeGradientDark(Brightness.dark, ThemeType.gradient, 'orangeGradientDarkTheme'),
  blackGradientLight(Brightness.light, ThemeType.gradient, 'blackGradientLightTheme',
      counterPart: 'whiteGradientDarkTheme'),
  whiteGradientDark(Brightness.dark, ThemeType.gradient, 'whiteGradientDarkTheme',
      counterPart: 'blackGradientLightTheme'),
  rainbowGradientLight(Brightness.light, ThemeType.gradient, 'rainbowGradientLightTheme'),
  rainbowGradientDark(Brightness.dark, ThemeType.gradient, 'rainbowGradientDarkTheme'),
  lightDynamic(Brightness.light, ThemeType.dynamic, 'lightDynamic', counterPart: 'darkDynamic'),
  darkDynamic(Brightness.dark, ThemeType.dynamic, 'darkDynamic', counterPart: 'lightDynamic');

  const ThemeName(this.brightness, this.type, this.storageName, {String? counterPart}) : _counterPart = counterPart;
  final Brightness brightness;
  final ThemeType type;
  final String storageName;
  final String? _counterPart;

  static List<ThemeName> getThemeNamesByType(ThemeType type) {
    return ThemeName.values.where((element) => element.type == type).toList();
  }

  static List<ThemeName> getThemeNamesByBrightness(Brightness brightness) {
    return ThemeName.values.where((element) => element.brightness == brightness).toList();
  }

  static List<ThemeName> getThemeNamesByTypeAndBrightness(ThemeType type, Brightness brightness) {
    return ThemeName.values.where((element) => element.type == type && element.brightness == brightness).toList();
  }

  static List<ThemeName> premiumThemes(bool premium) {
    return ThemeName.values.where((element) => element.type.premium == premium).toList();
  }

  static ThemeName fromString(String themeName) {
    return ThemeName.values.firstWhere((element) => element.storageName == themeName);
  }

  ThemeName getCounterPart() {
    if (this._counterPart != null) {
      return ThemeName.values.firstWhere((element) => element.storageName == this._counterPart);
    } else {
      String toReplace = this.brightness == Brightness.light ? 'Light' : 'Dark';
      String replaceWith = this.brightness == Brightness.light ? 'Dark' : 'Light';
      return ThemeName.fromString(this.storageName.replaceFirst(toReplace, replaceWith));
    }
  }

  bool isDodo() {
    return this == ThemeName.dodoLight || this == ThemeName.dodoDark;
  }

  bool isRainbow() {
    return this == ThemeName.rainbowGradientLight || this == ThemeName.rainbowGradientDark;
  }
}

class AppTheme {
  static Map<ThemeName, ThemeData> themes = Map.fromEntries([
    generateThemeData(ThemeName.pinkLight, Colors.purple[300]!),
    generateThemeData(ThemeName.pinkDark, Colors.pink[300]!),
    generateThemeData(ThemeName.seaBlueLight, Colors.blue[700]!),
    generateThemeData(ThemeName.seaBlueDark, Colors.blue[400]!),
    generateThemeData(ThemeName.greenLight, Colors.lightGreen),
    generateThemeData(ThemeName.greenDark, Colors.green),
    generateThemeData(ThemeName.amberLight, Colors.amber[700]!),
    generateThemeData(ThemeName.amberDark, Colors.amber[600]!),
    generateThemeData(ThemeName.orangeLight, Color(0xffFF9966)),
    generateThemeData(ThemeName.orangeDark, Color(0xffFF9966)),
    generateThemeData(ThemeName.dodoLight, Color.fromARGB(255, 19, 152, 181)),
    generateThemeData(ThemeName.dodoDark, Color.fromARGB(255, 19, 152, 181)),
    generateThemeData(ThemeName.endlessLight, Color(0xff006c51)),
    generateThemeData(ThemeName.endlessDark, Color(0xff006c51)),
    generateThemeData(ThemeName.celestialLight, Color(0xffaf2756)),
    generateThemeData(ThemeName.celestialDark, Color(0xffaf2756)),
    generateThemeData(ThemeName.roseannaGradientLight, Color.fromARGB(255, 255, 175, 189)),
    generateThemeData(ThemeName.roseannaGradientDark, Color.fromARGB(255, 255, 175, 189)),
    generateThemeData(ThemeName.passionateBedGradientLight, Color.fromARGB(255, 255, 117, 140)),
    generateThemeData(ThemeName.passionateBedGradientDark, Color.fromARGB(255, 255, 117, 140)),
    generateThemeData(ThemeName.plumGradientLight, Color.fromARGB(255, 152, 108, 240)),
    generateThemeData(ThemeName.plumGradientDark, Color.fromARGB(255, 152, 108, 240)),
    generateThemeData(ThemeName.sexyBlueGradientLight, Color.fromARGB(255, 33, 147, 176)),
    generateThemeData(ThemeName.sexyBlueGradientDark, Color.fromARGB(255, 33, 147, 176)),
    generateThemeData(ThemeName.endlessGradientLight, Color.fromARGB(255, 67, 206, 162)),
    generateThemeData(ThemeName.endlessGradientDark, Color.fromARGB(255, 67, 206, 162)),
    generateThemeData(ThemeName.greenGradientLight, Color.fromARGB(255, 24, 219, 56)),
    generateThemeData(ThemeName.greenGradientDark, Color.fromARGB(255, 24, 219, 56)),
    generateThemeData(ThemeName.yellowGradientLight, Color.fromARGB(255, 255, 208, 0)),
    generateThemeData(ThemeName.yellowGradientDark, Color.fromARGB(255, 255, 208, 0)),
    generateThemeData(ThemeName.orangeGradientLight, Color.fromARGB(255, 255, 153, 102)),
    generateThemeData(ThemeName.orangeGradientDark, Color.fromARGB(255, 255, 153, 102)),
    generateThemeData(ThemeName.blackGradientLight, Color.fromARGB(255, 67, 67, 67)),
    generateThemeData(ThemeName.whiteGradientDark, Color.fromARGB(255, 253, 251, 251)),
    generateThemeData(ThemeName.rainbowGradientLight, Colors.purple),
    generateThemeData(ThemeName.rainbowGradientDark, Colors.purple),
  ]);

  static Map<ThemeName, List<Color>> gradientColors = {
    ThemeName.orangeGradientLight: [
      Color.fromARGB(255, 255, 153, 102),
      Color.fromARGB(255, 255, 94, 98),
    ],
    ThemeName.orangeGradientDark: [
      Color.fromARGB(255, 255, 153, 102),
      Color.fromARGB(255, 255, 94, 98),
    ],
    ThemeName.whiteGradientDark: [
      Color.fromARGB(255, 255, 255, 255),
      Color.fromARGB(255, 215, 215, 215),
    ],
    ThemeName.blackGradientLight: [
      Color.fromARGB(255, 67, 67, 67),
      Color.fromARGB(255, 0, 0, 0),
    ],
    ThemeName.yellowGradientLight: [
      Color.fromARGB(255, 255, 208, 0),
      Color.fromARGB(255, 255, 179, 0),
    ],
    ThemeName.yellowGradientDark: [
      Color.fromARGB(255, 255, 208, 0),
      Color.fromARGB(255, 255, 179, 0),
    ],
    ThemeName.roseannaGradientLight: [
      Color.fromARGB(255, 255, 175, 189),
      Color.fromARGB(255, 255, 195, 160),
    ],
    ThemeName.roseannaGradientDark: [
      Color.fromARGB(255, 255, 175, 189),
      Color.fromARGB(255, 255, 195, 160),
    ],
    ThemeName.passionateBedGradientLight: [
      Color.fromARGB(255, 255, 117, 140),
      Color.fromARGB(255, 255, 148, 192),
    ],
    ThemeName.passionateBedGradientDark: [
      Color.fromARGB(255, 255, 117, 140),
      Color.fromARGB(255, 255, 148, 192),
    ],
    ThemeName.plumGradientLight: [
      Color.fromARGB(255, 152, 108, 240),
      Color.fromARGB(255, 118, 75, 162),
    ],
    ThemeName.plumGradientDark: [
      Color(0xffd3bbff),
      Color(0xFFB497E7),
    ],
    ThemeName.sexyBlueGradientLight: [
      Color.fromARGB(255, 33, 147, 176),
      Color.fromARGB(255, 109, 213, 237),
    ],
    ThemeName.sexyBlueGradientDark: [
      Color(0xff5ad5f9),
      Color(0xff71DEF7),
    ],
    ThemeName.endlessGradientLight: [
      Color.fromARGB(255, 67, 206, 162),
      Color.fromARGB(255, 24, 90, 157),
    ],
    ThemeName.endlessGradientDark: [
      Color(0xff56ddb1),
      Color(0xffa4c8ff),
    ],
    ThemeName.greenGradientLight: [
      Color.fromARGB(255, 24, 219, 56),
      Color.fromARGB(255, 62, 173, 81),
    ],
    ThemeName.greenGradientDark: [
      Color(0xff6dde7a),
      Color(0xff8FE097),
    ],
    ThemeName.rainbowGradientLight: [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
    ],
    ThemeName.rainbowGradientDark: [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
    ],
  };

  static Color textColorOnGradient(
    ThemeName themeName, {
    bool useSecondary = false,
    bool useTertiaryContainer = false,
    bool usePrimaryContainer = false,
    bool useSecondaryContainer = false,
  }) {
    return themeName.type == ThemeType.gradient
        ? AppTheme.themes[themeName]!.colorScheme.onPrimary
        : useSecondary
            ? AppTheme.themes[themeName]!.colorScheme.onSecondary
            : useTertiaryContainer
                ? AppTheme.themes[themeName]!.colorScheme.onTertiaryContainer
                : usePrimaryContainer
                    ? AppTheme.themes[themeName]!.colorScheme.onPrimaryContainer
                    : useSecondaryContainer
                        ? AppTheme.themes[themeName]!.colorScheme.onSecondaryContainer
                        : AppTheme.themes[themeName]!.colorScheme.onPrimary;
  }

  static Gradient gradientFromTheme(
    ThemeName themeName, {
    bool useSecondary = false,
    bool useTertiaryContainer = false,
    bool usePrimaryContainer = false,
    bool useSecondaryContainer = false,
  }) {
    return themeName.type == ThemeType.gradient
        ? themeName.isRainbow()
            ? LinearGradient(colors: [
                AppTheme.gradientColors[themeName]![0],
                AppTheme.gradientColors[themeName]![1],
                AppTheme.gradientColors[themeName]![2],
                AppTheme.gradientColors[themeName]![3],
                AppTheme.gradientColors[themeName]![4],
              ])
            : LinearGradient(colors: [AppTheme.gradientColors[themeName]![0], AppTheme.gradientColors[themeName]![1]])
        : useSecondary
            ? LinearGradient(colors: [
                AppTheme.themes[themeName]!.colorScheme.secondary,
                AppTheme.themes[themeName]!.colorScheme.secondary
              ])
            : usePrimaryContainer
                ? LinearGradient(colors: [
                    AppTheme.themes[themeName]!.colorScheme.primaryContainer,
                    AppTheme.themes[themeName]!.colorScheme.primaryContainer
                  ])
                : useSecondaryContainer
                    ? LinearGradient(colors: [
                        AppTheme.themes[themeName]!.colorScheme.secondaryContainer,
                        AppTheme.themes[themeName]!.colorScheme.secondaryContainer
                      ])
                    : useTertiaryContainer
                        ? LinearGradient(colors: [
                            AppTheme.themes[themeName]!.colorScheme.tertiaryContainer,
                            AppTheme.themes[themeName]!.colorScheme.tertiaryContainer
                          ])
                        : LinearGradient(colors: [
                            AppTheme.themes[themeName]!.colorScheme.primary,
                            AppTheme.themes[themeName]!.colorScheme.primary
                          ]);
  }

  static MapEntry<ThemeName, ThemeData> generateThemeData(ThemeName themeName, Color seedColor) {
    ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: themeName.brightness,
    );
    ColorScheme? newColorScheme;
    switch (themeName) {
      case ThemeName.plumGradientDark:
        newColorScheme = colorScheme.copyWith(
          onPrimary: Color.fromARGB(255, 40, 1, 92),
          secondary: Color(0xFFB497E7),
        );
        break;
      case ThemeName.endlessGradientDark:
        newColorScheme = colorScheme.copyWith(onPrimary: Color(0xff00241A));
        break;
      case ThemeName.sexyBlueGradientDark:
        newColorScheme = colorScheme.copyWith(onPrimary: Color(0xff001D24));
        break;
      case ThemeName.roseannaGradientDark:
        newColorScheme = colorScheme.copyWith(onPrimary: Color(0xff2B0713));
        break;
      case ThemeName.passionateBedGradientDark:
        newColorScheme = colorScheme.copyWith(onPrimary: Color(0xff420015));
        break;
      case ThemeName.yellowGradientDark:
        newColorScheme = colorScheme.copyWith(onPrimary: Color(0xff1C1600));
        break;
      case ThemeName.orangeGradientDark:
        newColorScheme = colorScheme.copyWith(onPrimary: Color(0xff000000));
        break;
      case ThemeName.endlessLight:
        newColorScheme = colorScheme.copyWith(
          secondary: Color(0xff1c60a5),
          onSecondary: Color(0xffffffff),
          secondaryContainer: Color(0xffd4e3ff),
          onSecondaryContainer: Color(0xff001c3a),
        );
        break;
      case ThemeName.endlessDark:
        newColorScheme = colorScheme.copyWith(
          secondary: Color(0xffa4c8ff),
          onSecondary: Color(0xff00315d),
          secondaryContainer: Color(0xff004784),
          onSecondaryContainer: Color(0xffd4e3ff),
        );
        break;
      case ThemeName.celestialLight:
        newColorScheme = colorScheme.copyWith(
          secondary: Color(0xff4d57a9),
          onSecondary: Color(0xffffffff),
          secondaryContainer: Color(0xffdfe0ff),
          onSecondaryContainer: Color(0xff000964),
        );
        break;
      case ThemeName.celestialDark:
        newColorScheme = colorScheme.copyWith(
          secondary: Color(0xffbdc2ff),
          onSecondary: Color(0xff1c2678),
          secondaryContainer: Color(0xff353e90),
          onSecondaryContainer: Color(0xffdfe0ff),
        );
        break;
      case ThemeName.orangeLight:
        newColorScheme = colorScheme.copyWith(
          primary: Color(0xffFF9966),
          secondary: Color(0xffb32631),
          onSecondary: Color(0xffffffff),
          secondaryContainer: Color(0xffffdad8),
          onSecondaryContainer: Color(0xff410007),
        );
        break;
      case ThemeName.orangeDark:
        newColorScheme = colorScheme.copyWith(
          secondary: Color.fromARGB(255, 254, 200, 198),
          onSecondary: Color.fromARGB(255, 126, 21, 36),
          secondaryContainer: Color(0xff91071c),
          onSecondaryContainer: Color(0xffffdad8),
        );
        break;
      case ThemeName.dodoLight:
        newColorScheme = colorScheme.copyWith(
          primary: Color.fromARGB(255, 19, 152, 181),
          secondary: Color.fromARGB(255, 247, 192, 0),
          secondaryContainer: Color.fromARGB(255, 255, 223, 149),
          onSecondaryContainer: Color.fromARGB(255, 37, 26, 0),
        );
        break;
      case ThemeName.dodoDark:
        newColorScheme = colorScheme.copyWith(
          primary: Color.fromARGB(255, 88, 214, 247),
          onPrimary: Color.fromARGB(255, 0, 54, 66),
          primaryContainer: Color.fromARGB(255, 0, 78, 94),
          onPrimaryContainer: Color.fromARGB(255, 177, 235, 255),
          secondary: Color.fromARGB(255, 245, 191, 0),
          onSecondary: Color.fromARGB(255, 62, 46, 0),
          secondaryContainer: Color.fromARGB(255, 163, 121, 0),
          onSecondaryContainer: Color.fromARGB(255, 255, 239, 184),
          tertiary: Color.fromARGB(255, 253, 187, 59),
          onTertiary: Color.fromARGB(255, 66, 44, 0),
          background: Color.fromARGB(255, 25, 28, 29),
          onBackground: Color.fromARGB(255, 225, 227, 228),
          surface: Color.fromARGB(255, 25, 28, 29),
          onSurface: Color.fromARGB(255, 225, 227, 228),
          surfaceVariant: Color.fromARGB(255, 64, 72, 75),
          onSurfaceVariant: Color.fromARGB(255, 191, 200, 204),
        );
        break;
      default:
        break;
    }
    if (themeName.isRainbow()) {
      newColorScheme = colorScheme.copyWith(onPrimary: Colors.white);
    }

    ThemeData data = ThemeData.from(colorScheme: colorScheme, useMaterial3: true).copyWith(
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
    if (newColorScheme != null) {
      data = data.copyWith(colorScheme: newColorScheme);
    }
    return MapEntry(themeName, data);
  }

  static void removeDynamicThemes() {
    AppTheme.themes.remove(ThemeName.lightDynamic);
    AppTheme.themes.remove(ThemeName.darkDynamic);
  }

  static void addDynamicThemes(ColorScheme lightScheme, ColorScheme darkScheme) {
    try {
      AppTheme.themes[ThemeName.lightDynamic] = ThemeData.from(
        colorScheme: lightScheme,
        useMaterial3: true,
      ).copyWith(
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );
      AppTheme.themes[ThemeName.darkDynamic] = ThemeData.from(
        colorScheme: darkScheme.copyWith(brightness: Brightness.dark),
        useMaterial3: true,
      ).copyWith(
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );
    } catch (exception) {
      print(exception);
    }
  }
}
