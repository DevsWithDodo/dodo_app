import 'package:flutter/foundation.dart';
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
  blackGradientLight(Brightness.light, ThemeType.gradient, 'blackGradientLightTheme', counterPart: 'whiteGradientDarkTheme'),
  whiteGradientDark(Brightness.dark, ThemeType.gradient, 'whiteGradientDarkTheme', counterPart: 'blackGradientLightTheme'),
  rainbowGradientLight(Brightness.light, ThemeType.gradient, 'rainbowGradientLightTheme'),
  rainbowGradientDark(Brightness.dark, ThemeType.gradient, 'rainbowGradientDarkTheme'),
  lightDynamic(Brightness.light, ThemeType.dynamic, 'lightDynamic', counterPart: 'darkDynamic'),
  darkDynamic(Brightness.dark, ThemeType.dynamic, 'darkDynamic', counterPart: 'lightDynamic'),
  greenRedLight(Brightness.light, ThemeType.dualColor, 'greenRedLight'),
  greenRedDark(Brightness.dark, ThemeType.dualColor, 'greenRedDark');

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
    if (_counterPart != null) {
      return ThemeName.values.firstWhere((element) => element.storageName == _counterPart);
    } else {
      String toReplace = brightness == Brightness.light ? 'Light' : 'Dark';
      String replaceWith = brightness == Brightness.light ? 'Dark' : 'Light';
      return ThemeName.fromString(storageName.replaceFirst(toReplace, replaceWith));
    }
  }

  bool isDodo() {
    return this == ThemeName.dodoLight || this == ThemeName.dodoDark;
  }

  bool isRainbow() {
    return this == ThemeName.rainbowGradientLight || this == ThemeName.rainbowGradientDark;
  }
}

class ThemeNotFoundException implements Exception {
  final String message;
  ThemeNotFoundException([this.message = "Theme not found"]);
}

class AppTheme {
  static ThemeData getTheme(ThemeName themeName) {
    if (AppTheme.themes.containsKey(themeName)) {
      return AppTheme.themes[themeName]!;
    } else {
      throw ThemeNotFoundException();
    }
  }

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
    generateThemeData(ThemeName.greenRedLight, Color(0xff94483c)),
    generateThemeData(ThemeName.greenRedDark, Color(0xffffb4a7)),
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
            ? LinearGradient(colors: [AppTheme.themes[themeName]!.colorScheme.secondary, AppTheme.themes[themeName]!.colorScheme.secondary])
            : usePrimaryContainer
                ? LinearGradient(colors: [AppTheme.themes[themeName]!.colorScheme.primaryContainer, AppTheme.themes[themeName]!.colorScheme.primaryContainer])
                : useSecondaryContainer
                    ? LinearGradient(colors: [AppTheme.themes[themeName]!.colorScheme.secondaryContainer, AppTheme.themes[themeName]!.colorScheme.secondaryContainer])
                    : useTertiaryContainer
                        ? LinearGradient(colors: [AppTheme.themes[themeName]!.colorScheme.tertiaryContainer, AppTheme.themes[themeName]!.colorScheme.tertiaryContainer])
                        : LinearGradient(colors: [AppTheme.themes[themeName]!.colorScheme.primary, AppTheme.themes[themeName]!.colorScheme.primary]);
  }

  static MapEntry<ThemeName, ThemeData> generateThemeData(ThemeName themeName, Color seedColor) {
    ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: themeName.brightness,
      // dynamicSchemeVariant: DynamicSchemeVariant.expressive
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
          surface: Color.fromARGB(255, 25, 28, 29),
          onSurface: Color.fromARGB(255, 225, 227, 228),
          surfaceContainer: Color(0xff1d2a2e),
          surfaceContainerLow: Color(0xff1c2528),
          surfaceContainerHigh: Color.fromARGB(255, 42, 51, 54),
          surfaceContainerHighest: Color.fromARGB(255, 64, 72, 75),
          onSurfaceVariant: Color.fromARGB(255, 191, 200, 204),
          surfaceTint: Color.fromARGB(255, 88, 214, 247),
        );
        break;
      case ThemeName.greenRedLight:
        newColorScheme = colorScheme.copyWith(
          primary: Color(0xff94483c),
          primaryContainer: Color(0xffffdad4),
          onPrimaryContainer: Color(0xff3d0603),
          secondary: Color(0xff3f6655),
          onSecondary: Color(0xffffffff),
          secondaryContainer: Color(0xffc1ecd6),
          onSecondaryContainer: Color(0xff002115),
          tertiary: Color(0xff1a6966),
          onTertiary: Color(0xffffffff),
          tertiaryContainer: Color(0xffa8efeb),
          onTertiaryContainer: Color(0xff00201f),
          error: Color(0xffba1a1a),
          errorContainer: Color(0xffffdad6),
          onErrorContainer: Color(0xff410002),
          surface: Color(0xfff6fff6),
          onSurface: Color(0xff151d18),
          surfaceContainer: Color(0xffeef0e7),
          surfaceContainerLow: Color(0xfff1f5ec),
          surfaceContainerHigh: Color(0xffd4e3d9),
          surfaceContainerHighest: Color(0xffebeae1),
          onSurfaceVariant: Color(0xff3c4a41),
          outline: Color(0xff6a7a6f),
          outlineVariant: Color(0xffbacbbe),
          inverseSurface: Color(0xff2a322d),
          onInverseSurface: Color(0xffeaf3ea),
          inversePrimary: Color(0xffffb4a7),
          surfaceTint: Color(0xff94483c),
        );
        break;
      case ThemeName.greenRedDark:
        newColorScheme = ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xffffb4a7),
          onPrimary: Color(0xff591b13),
          primaryContainer: Color(0xff763127),
          onPrimaryContainer: Color(0xffffdad4),
          secondary: Color(0xffa5d0ba),
          onSecondary: Color(0xff0d3728),
          secondaryContainer: Color(0xff274e3e),
          onSecondaryContainer: Color(0xffc1ecd6),
          tertiary: Color(0xff8cd3cf),
          onTertiary: Color(0xff003735),
          tertiaryContainer: Color(0xff00504d),
          onTertiaryContainer: Color(0xffa8efeb),
          error: Color(0xffffb4ab),
          onError: Color(0xff690005),
          errorContainer: Color(0xff93000a),
          onErrorContainer: Color(0xffffb4ab),
          surface: Color(0xff151d18),
          onSurface: Color(0xffdce5dc),
          surfaceContainerHighest: Color(0xff3c4a41),
          surfaceContainerLow: Color(0xff20241f),
          surfaceContainer: Color(0xff272823),
          onSurfaceVariant: Color(0xffbacbbe),
          outline: Color(0xff859589),
          outlineVariant: Color(0xff3c4a41),
          inverseSurface: Color(0xffdce5dc),
          onInverseSurface: Color(0xff2a322d),
          inversePrimary: Color(0xff94483c),
          surfaceTint: Color(0xffffb4a7),
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
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surfaceContainerHigh, // Temporary fix
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: UnderlineInputBorder(),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: PredictiveBackPageTransitionsBuilder()}),
    );
    if (newColorScheme != null) {
      data = data.copyWith(
          colorScheme: newColorScheme,
          scaffoldBackgroundColor: newColorScheme.surface,
          dialogTheme: DialogTheme(
            backgroundColor: newColorScheme.surfaceContainerHigh, // Temporary fix
          ));
    }
    return MapEntry(themeName, data);
  }

  static void removeDynamicThemes() {
    AppTheme.themes.remove(ThemeName.lightDynamic);
    AppTheme.themes.remove(ThemeName.darkDynamic);
  }

  static void addDynamicThemes(ColorScheme lightScheme, ColorScheme darkScheme) {
    try {
      ColorScheme otherlightScheme = ColorScheme.fromSeed(seedColor: lightScheme.primary, brightness: Brightness.light);
      ColorScheme otherDarkScheme = ColorScheme.fromSeed(seedColor: darkScheme.primary, brightness: Brightness.dark);

      lightScheme = lightScheme.copyWith(
        surface: otherlightScheme.surface,
        onSurface: otherlightScheme.onSurface,
        surfaceBright: otherlightScheme.surfaceBright,
        surfaceDim: otherlightScheme.surfaceDim,
        surfaceContainer: otherlightScheme.surfaceContainer,
        surfaceContainerHigh: otherlightScheme.surfaceContainerHigh,
        surfaceContainerLow: otherlightScheme.surfaceContainerLow,
        surfaceContainerHighest: otherlightScheme.surfaceContainerHighest,
        surfaceContainerLowest: otherlightScheme.surfaceContainerLowest,
      );

      darkScheme = darkScheme.copyWith(
        surface: otherDarkScheme.surface,
        onSurface: otherDarkScheme.onSurface,
        surfaceBright: otherDarkScheme.surfaceBright,
        surfaceDim: otherDarkScheme.surfaceDim,
        surfaceContainer: otherDarkScheme.surfaceContainer,
        surfaceContainerHigh: otherDarkScheme.surfaceContainerHigh,
        surfaceContainerLow: otherDarkScheme.surfaceContainerLow,
        surfaceContainerHighest: otherDarkScheme.surfaceContainerHighest,
        surfaceContainerLowest: otherDarkScheme.surfaceContainerLowest,
      );

      lightScheme = lightScheme.copyWith(
        surfaceContainerLow: ElevationOverlay.applySurfaceTint(lightScheme.surface, lightScheme.primary, 3),
      );

      darkScheme = darkScheme.copyWith(
        surfaceContainerLow: ElevationOverlay.applySurfaceTint(darkScheme.surface, darkScheme.primary, 3),
      );

      AppTheme.themes[ThemeName.lightDynamic] = ThemeData.from(
        colorScheme: lightScheme,
        useMaterial3: true,
      ).copyWith(
        cardTheme: CardTheme(
          color: lightScheme.surfaceContainerLow,
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
          isCollapsed: false,
          border: UnderlineInputBorder(),
        ),
      );
      AppTheme.themes[ThemeName.darkDynamic] = ThemeData.from(
        colorScheme: darkScheme.copyWith(brightness: Brightness.dark),
        useMaterial3: true,
      ).copyWith(
        cardTheme: CardTheme(
          color: darkScheme.surfaceContainerLow,
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
          border: UnderlineInputBorder(),
        ),
      );
    } catch (exception) {
      if (kDebugMode) {
        print(exception);
      }
    }
  }
}
