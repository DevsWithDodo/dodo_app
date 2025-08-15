import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/components/helpers/background_paint.dart';
import 'package:csocsort_szamla/components/user_settings/components/premium_theme_dialog.dart';
import 'package:csocsort_szamla/components/user_settings/components/theme_preview_dialog.dart';
import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_usage_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ThemePicker extends StatefulWidget {
  const ThemePicker({super.key});

  @override
  State<ThemePicker> createState() => _ThemePickerState();
}

class _ThemePickerState extends State<ThemePicker> {
  late Brightness brightness;

  Widget _colorWrap(ThemeType themeType, {required bool enabled}) {
    if (AppTheme.themes.keys.where((element) => element.type == themeType).isEmpty) {
      return SizedBox();
    }
    var themeNames = ThemeName.getThemeNamesByTypeAndBrightness(themeType, brightness);
    if (themeType == ThemeType.simpleColor) {
      themeNames.addAll(ThemeName.getThemeNamesByTypeAndBrightness(ThemeType.rainbow, brightness));
    }

    return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 9,
        spacing: 9,
        children: themeNames.map((entry) {
          return ColorElement(
            updateColor: _updateColor,
            theme: AppTheme.themes[entry]!,
            themeName: entry,
            enabled: enabled,
            dualColor:
                themeType == ThemeType.dualColor || themeType == ThemeType.dynamic || themeType == ThemeType.background,
          );
        }).toList());
  }

  @override
  void initState() {
    super.initState();
    brightness = context.read<AppThemeState>().themeName.brightness;
  }

  void _updateBrightness(Brightness brightness) {
    if (brightness == this.brightness) {
      return;
    }
    AppThemeState provider = context.read<AppThemeState>();
    provider.themeName = provider.themeName.getCounterPart();
    setState(
      () => this.brightness = brightness,
    );
    _updateColor(provider.themeName.storageName);
  }

  Future _updateColor(String name) async {
    Map<String, String?> body = {'theme': name};
    await Http.put(uri: '/user', body: body);
  }

  @override
  Widget build(BuildContext context) {
    // This line is important so that textTheme is updated, don't know why
    // ignore: avoid_print, deprecated_member_use
    print(Theme.of(context).colorScheme.onSurfaceVariant.alpha);
    return Selector<UserNotifier, bool>(
        selector: (context, provider) => provider.user!.useGradients,
        builder: (context, useGradients, _) {
          return CardWithBackground(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Center(
                    child: Text(
                      'change_theme'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          child: IconButton(
                            onPressed: () => _updateBrightness(Brightness.light),
                            isSelected: brightness == Brightness.light,
                            icon: Icon(Icons.light_mode),
                          ),
                        ),
                      ),
                      Switch(
                        value: brightness == Brightness.dark,
                        onChanged: (value) => _updateBrightness(value ? Brightness.dark : Brightness.light),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          child: IconButton(
                            isSelected: brightness == Brightness.dark,
                            onPressed: () => _updateBrightness(Brightness.dark),
                            icon: Icon(Icons.dark_mode),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _colorWrap(ThemeType.simpleColor, enabled: true),
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: context.colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Column(
                      children: [
                        Text(
                          'dual_tone_themes'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 15),
                        _colorWrap(ThemeType.dualColor, enabled: useGradients),
                        SizedBox(height: 15),
                        Text(
                          'gradient_themes'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 15),
                        _colorWrap(ThemeType.gradient, enabled: useGradients),
                        SizedBox(height: 15),
                        Text(
                          'change-theme.background-theme'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 15),
                        _colorWrap(ThemeType.background, enabled: useGradients),
                        Visibility(
                          visible:
                              AppTheme.themes.keys.where((element) => element.type == ThemeType.dynamic).isNotEmpty,
                          child: Column(
                            children: [
                              SizedBox(height: 10),
                              Divider(),
                              SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => launchUrlString('https://m3.material.io/blog/announcing-material-you'),
                                child: Text(
                                  'change-theme.adaptive-theme'.tr(),
                                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontSize: 18,
                                        decoration: TextDecoration.underline,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'change-theme.adaptive-theme.subtitle'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              _colorWrap(ThemeType.dynamic, enabled: useGradients),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}

class ColorElement extends StatelessWidget {
  final Future Function(String name) updateColor;
  final ThemeData theme;
  final ThemeName themeName;
  final bool enabled;
  final bool dualColor;
  const ColorElement({
    super.key,
    required this.updateColor,
    required this.theme,
    required this.themeName,
    this.enabled = true,
    this.dualColor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<AppThemeState, ThemeName>(
      selector: (context, provider) => provider.themeName,
      builder: (context, currentThemeName, _) {
        Color splitColor = theme.colorScheme.onPrimary;
        return Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return ThemePreviewDialog(
                        themeName: themeName,
                        onThemeSelected: () {
                          bool themesEnabled = context.read<UserNotifier>().user!.useGradients;
                          if (themesEnabled) {
                            context.read<AppThemeState>().themeName = themeName;
                            context.read<UserUsageNotifier>().setThemeChangedFlag(true);
                            updateColor(themeName.storageName);
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return PremiumThemeDialog();
                              },
                            );
                          }
                        },
                      );
                    });
              },
              child: Stack(
                children: [
                  Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        strokeAlign: BorderSide.strokeAlignOutside,
                        color: currentThemeName == themeName
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                      gradient: dualColor
                          ? LinearGradient(
                              colors: [
                                theme.colorScheme.primaryContainer,
                                splitColor,
                                splitColor,
                                theme.colorScheme.secondaryContainer,
                              ],
                              stops: [0.48, 0.48, 0.52, 0.52],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            )
                          : AppTheme.gradientFromTheme(themeName),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: dualColor
                              ? LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    splitColor,
                                    splitColor,
                                    theme.colorScheme.secondary
                                  ],
                                  stops: [0.48, 0.48, 0.52, 0.52],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: SizedBox.square(
                          dimension: dualColor ? 40 : 30,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(themeName.emoji ?? '', style: TextStyle(fontSize: 35)),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
