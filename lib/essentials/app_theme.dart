import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static final Map<String, ThemeData> themes = {
    'pinkLightTheme': generateThemeData(
      Colors.purple[300]!,
      Brightness.light,
    ),
    'pinkDarkTheme': generateThemeData(
      Colors.pink[300]!,
      Brightness.dark,
    ),
    'seaBlueLightTheme': generateThemeData(
      Colors.blue[700]!,
      Brightness.light,
    ),
    'seaBlueDarkTheme': generateThemeData(
      Colors.blue[400]!,
      Brightness.dark,
    ),
    'greenLightTheme': generateThemeData(
      Colors.lightGreen,
      Brightness.light,
    ),
    'greenDarkTheme': generateThemeData(
      Colors.green,
      Brightness.dark,
    ),
    'amberLightTheme': generateThemeData(
      Colors.amber[700]!,
      Brightness.light,
    ),
    'amberDarkTheme': generateThemeData(
      Colors.amber[600]!,
      Brightness.dark,
    ),
    'orangeLightTheme': generateThemeData(
      Color(0xffFF9966),
      Brightness.light,
      themeName: 'orangeLightTheme',
    ),
    'orangeDarkTheme': generateThemeData(
      Color(0xffFF9966),
      Brightness.dark,
      themeName: 'orangeDarkTheme',
    ),
    'dodoLightTheme': generateThemeData(
      Color.fromARGB(255, 19, 152, 181),
      Brightness.light,
      themeName: 'dodoLightTheme',
    ),
    'dodoDarkTheme': generateThemeData(
      Color.fromARGB(255, 19, 152, 181),
      Brightness.dark,
      themeName: 'dodoDarkTheme',
    ),
    'endlessLightTheme': generateThemeData(
      Color(0xff006c51),
      Brightness.light,
      themeName: 'endlessLightTheme',
    ),
    'endlessDarkTheme': generateThemeData(
      Color(0xff006c51),
      Brightness.dark,
      themeName: 'endlessDarkTheme',
    ),
    'celestialLightTheme': generateThemeData(
      Color(0xffaf2756),
      Brightness.light,
      themeName: 'celestialLightTheme',
    ),
    'celestialDarkTheme': generateThemeData(
      Color(0xffaf2756),
      Brightness.dark,
      themeName: 'celestialDarkTheme',
    ),
    'roseannaGradientLightTheme': generateThemeData(
      Color.fromARGB(255, 255, 175, 189),
      Brightness.light,
    ),
    'roseannaGradientDarkTheme': generateThemeData(
      Color.fromARGB(255, 255, 175, 189),
      Brightness.dark,
      themeName: 'roseannaGradientDarkTheme',
    ),
    'passionateBedGradientLightTheme': generateThemeData(
      Color.fromARGB(255, 255, 117, 140),
      Brightness.light,
    ),
    'passionateBedGradientDarkTheme': generateThemeData(
      Color.fromARGB(255, 255, 117, 140),
      Brightness.dark,
      themeName: 'passionateBedGradientDarkTheme',
    ),
    'plumGradientLightTheme': generateThemeData(
      Color.fromARGB(255, 152, 108, 240),
      Brightness.light,
    ),
    'plumGradientDarkTheme': generateThemeData(
      Color.fromARGB(255, 152, 108, 240),
      Brightness.dark,
      themeName: 'plumGradientDarkTheme',
    ),
    'sexyBlueGradientLightTheme': generateThemeData(
      Color.fromARGB(255, 33, 147, 176),
      Brightness.light,
    ),
    'sexyBlueGradientDarkTheme': generateThemeData(
      Color.fromARGB(255, 33, 147, 176),
      Brightness.dark,
      themeName: 'sexyBlueGradientDarkTheme',
    ),
    'endlessGradientLightTheme': generateThemeData(
      Color.fromARGB(255, 67, 206, 162),
      Brightness.light,
    ),
    'endlessGradientDarkTheme': generateThemeData(
      Color.fromARGB(255, 67, 206, 162),
      Brightness.dark,
      themeName: 'endlessGradientDarkTheme',
    ),
    'greenGradientLightTheme': generateThemeData(
      Color.fromARGB(255, 24, 219, 56),
      Brightness.light,
    ),
    'greenGradientDarkTheme': generateThemeData(
      // Color.fromARGB(255, 24, 219, 56),
      Color(0xff6dde7a),
      Brightness.dark,
    ),
    'yellowGradientLightTheme': generateThemeData(
      Color.fromARGB(255, 255, 208, 0),
      Brightness.light,
    ),
    'yellowGradientDarkTheme': generateThemeData(
      Color.fromARGB(255, 255, 208, 0),
      Brightness.dark,
      themeName: 'yellowGradientDarkTheme',
    ),
    'orangeGradientLightTheme': generateThemeData(
      Color.fromARGB(255, 255, 153, 102),
      Brightness.light,
    ),
    'orangeGradientDarkTheme': generateThemeData(
      Color.fromARGB(255, 255, 153, 102),
      Brightness.dark,
      themeName: 'orangeGradientDarkTheme',
    ),
    'blackGradientLightTheme': generateThemeData(
      Color.fromARGB(255, 67, 67, 67),
      Brightness.light,
    ),
    'whiteGradientDarkTheme':
        generateThemeData(Color.fromARGB(255, 253, 251, 251), Brightness.dark),
    'rainbowGradientLightTheme':
        generateThemeData(Colors.purple, Brightness.light, themeName: 'rainbowGradientLightTheme'),
    'rainbowGradientDarkTheme':
        generateThemeData(Colors.purple, Brightness.dark, themeName: 'rainbowGradientDarkTheme'),
  };

  static List<String> simpleColorThemes = [
    'pinkLightTheme',
    'pinkDarkTheme',
    'seaBlueLightTheme',
    'seaBlueDarkTheme',
    'greenLightTheme',
    'greenDarkTheme',
    'amberLightTheme',
    'amberDarkTheme',
  ];

  static List<String> dualColorThemes = [
    'orangeLightTheme',
    'orangeDarkTheme',
    'dodoLightTheme',
    'dodoDarkTheme',
    'endlessLightTheme',
    'endlessDarkTheme',
    'celestialLightTheme',
    'celestialDarkTheme',
  ];

  static Map<String, List<Color>> gradientColors = {
    'orangeGradientLightTheme': [
      Color.fromARGB(255, 255, 153, 102),
      Color.fromARGB(255, 255, 94, 98),
    ],
    'orangeGradientDarkTheme': [
      Color.fromARGB(255, 255, 153, 102),
      Color.fromARGB(255, 255, 94, 98),
    ],
    'whiteGradientDarkTheme': [
      Color.fromARGB(255, 235, 237, 238),
      Color.fromARGB(255, 253, 251, 251),
    ],
    'blackGradientLightTheme': [
      Color.fromARGB(255, 67, 67, 67),
      Color.fromARGB(255, 0, 0, 0),
    ],
    'yellowGradientLightTheme': [
      Color.fromARGB(255, 255, 208, 0),
      Color.fromARGB(255, 255, 179, 0),
    ],
    'yellowGradientDarkTheme': [
      Color.fromARGB(255, 255, 208, 0),
      Color.fromARGB(255, 255, 179, 0),
    ],
    'roseannaGradientLightTheme': [
      Color.fromARGB(255, 255, 175, 189),
      Color.fromARGB(255, 255, 195, 160),
    ],
    'roseannaGradientDarkTheme': [
      Color.fromARGB(255, 255, 175, 189),
      Color.fromARGB(255, 255, 195, 160),
    ],
    'passionateBedGradientLightTheme': [
      Color.fromARGB(255, 255, 117, 140),
      Color.fromARGB(255, 255, 148, 192),
    ],
    'passionateBedGradientDarkTheme': [
      Color.fromARGB(255, 255, 117, 140),
      Color.fromARGB(255, 255, 148, 192),
    ],
    'plumGradientLightTheme': [
      Color.fromARGB(255, 152, 108, 240),
      Color.fromARGB(255, 118, 75, 162),
    ],
    'plumGradientDarkTheme': [
      Color(0xffd3bbff),
      Color(0xffBEA8E5),
      // Color.fromARGB(255, 152, 108, 240),
      // Color.fromARGB(255, 126, 95, 158),
    ],
    'sexyBlueGradientLightTheme': [
      Color.fromARGB(255, 33, 147, 176),
      Color.fromARGB(255, 109, 213, 237),
    ],
    'sexyBlueGradientDarkTheme': [
      // Color.fromARGB(255, 33, 147, 176),
      Color(0xff5ad5f9),
      Color(0xff71DEF7),
      // Color.fromARGB(255, 109, 213, 237),
    ],
    'endlessGradientLightTheme': [
      Color.fromARGB(255, 67, 206, 162),
      Color.fromARGB(255, 24, 90, 157),
    ],
    'endlessGradientDarkTheme': [
      Color(0xff56ddb1),
      Color(0xffa4c8ff),
      // Color.fromARGB(255, 24, 90, 157),
      // Color.fromARGB(255, 67, 206, 162),
    ],
    'greenGradientLightTheme': [
      Color.fromARGB(255, 24, 219, 56),
      Color.fromARGB(255, 62, 173, 81),
    ],
    'greenGradientDarkTheme': [
      Color(0xff6dde7a),
      Color(0xff8FE097),
      // Color.fromARGB(255, 24, 219, 56),
      // Color.fromARGB(255, 62, 173, 81),
    ],
    'rainbowGradientLightTheme': [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
    ],
    'rainbowGradientDarkTheme': [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
    ],
  };

  static Gradient gradientFromTheme(
    String? themeName, {
    bool useSecondary = false,
    bool useTertiaryContainer = false,
    bool usePrimaryContainer = false,
    bool useSecondaryContainer = false,
  }) {
    return gradientColors.keys.contains(themeName)
        ? themeName!.contains('rainbow')
            ? LinearGradient(colors: [
                AppTheme.gradientColors[themeName]![0],
                AppTheme.gradientColors[themeName]![1],
                AppTheme.gradientColors[themeName]![2],
                AppTheme.gradientColors[themeName]![3],
                AppTheme.gradientColors[themeName]![4],
              ])
            : LinearGradient(colors: [
                AppTheme.gradientColors[themeName]![0],
                AppTheme.gradientColors[themeName]![1]
              ])
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

  static ThemeData generateThemeData(Color seedColor, Brightness brightness,
      {String themeName = ''}) {
    ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    if (themeName != '') {
      ColorScheme? newColorScheme;
      switch (themeName) {
        case 'plumGradientDarkTheme':
          newColorScheme = colorScheme.copyWith(onPrimary: Color.fromARGB(255, 40, 1, 92));
          break;
        case 'endlessGradientDarkTheme':
          newColorScheme = colorScheme.copyWith(onPrimary: Color(0xff00241A));
          break;
        case 'sexyBlueGradientDarkTheme':
          newColorScheme = colorScheme.copyWith(onPrimary: Color(0xff001D24));
          break;
        case 'roseannaGradientDarkTheme':
          newColorScheme = colorScheme.copyWith(onPrimary: Color(0xff2B0713));
          break;
        case 'passionateBedGradientDarkTheme':
          newColorScheme = colorScheme.copyWith(onPrimary: Color(0xff420015));
          break;
        case 'yellowGradientDarkTheme':
          newColorScheme = colorScheme.copyWith(onPrimary: Color(0xff1C1600));
          break;
        case 'orangeGradientDarkTheme':
          newColorScheme = colorScheme.copyWith(onPrimary: Color(0xff000000));
          break;
        case 'endlessLightTheme':
          newColorScheme = colorScheme.copyWith(
            secondary: Color(0xff1c60a5),
            onSecondary: Color(0xffffffff),
            secondaryContainer: Color(0xffd4e3ff),
            onSecondaryContainer: Color(0xff001c3a),
          );
          break;
        case 'endlessDarkTheme':
          newColorScheme = colorScheme.copyWith(
            secondary: Color(0xffa4c8ff),
            onSecondary: Color(0xff00315d),
            secondaryContainer: Color(0xff004784),
            onSecondaryContainer: Color(0xffd4e3ff),
          );
          break;
        case 'celestialLightTheme':
          newColorScheme = colorScheme.copyWith(
            secondary: Color(0xff4d57a9),
            onSecondary: Color(0xffffffff),
            secondaryContainer: Color(0xffdfe0ff),
            onSecondaryContainer: Color(0xff000964),
          );
          break;
        case 'celestialDarkTheme':
          newColorScheme = colorScheme.copyWith(
            secondary: Color(0xffbdc2ff),
            onSecondary: Color(0xff1c2678),
            secondaryContainer: Color(0xff353e90),
            onSecondaryContainer: Color(0xffdfe0ff),
          );
          break;
        case 'orangeLightTheme':
          newColorScheme = colorScheme.copyWith(
            primary: Color(0xffFF9966),
            secondary: Color(0xffb32631),
            onSecondary: Color(0xffffffff),
            secondaryContainer: Color(0xffffdad8),
            onSecondaryContainer: Color(0xff410007),
          );
          break;
        case 'orangeDarkTheme':
          newColorScheme = colorScheme.copyWith(
            secondary: Color(0xffffb3b0),
            onSecondary: Color(0xff680010),
            secondaryContainer: Color(0xff91071c),
            onSecondaryContainer: Color(0xffffdad8),
          );
          break;
        case 'dodoLightTheme':
          newColorScheme = colorScheme.copyWith(
            primary: Color.fromARGB(255, 19, 152, 181),
            secondary: Color.fromARGB(255, 247, 192, 0),
            secondaryContainer: Color.fromARGB(255, 255, 223, 149),
            onSecondaryContainer: Color.fromARGB(255, 37, 26, 0),
          );
          break;
        case 'dodoDarkTheme':
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
      }
      if (themeName.contains('rainbow')) {
        newColorScheme = colorScheme.copyWith(onPrimary: Colors.white);
      }
      return ThemeData.from(colorScheme: colorScheme, useMaterial3: true)
          .copyWith(
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
          )
          .copyWith(colorScheme: newColorScheme);
    }
    return ThemeData.from(colorScheme: colorScheme, useMaterial3: true).copyWith(
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
  }

  static void addDynamicThemes(ColorScheme lightScheme, ColorScheme darkScheme) {
    try {
      AppTheme.themes['lightDynamic'] = ThemeData.from(
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
      AppTheme.themes['darkDynamic'] = ThemeData.from(
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
