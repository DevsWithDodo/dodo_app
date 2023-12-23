import 'package:csocsort_szamla/components/user_settings/components/theme_preview.dart';
import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/components/main/dialogs/iapp_not_supported_dialog.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/pages/app/store_page.dart';
import 'package:csocsort_szamla/pages/app/user_settings_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemePicker extends StatefulWidget {
  @override
  _ThemePickerState createState() => _ThemePickerState();
}

class _ThemePickerState extends State<ThemePicker> {
  late Brightness brightness;

  Widget _colorWrap(ThemeType themeType, {required bool enabled}) {
    if (AppTheme.themes.keys.where((element) => element.type == themeType).isEmpty) {
      return SizedBox();
    }
    return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 15,
        spacing: 15,
        children: ThemeName.getThemeNamesByTypeAndBrightness(themeType, brightness).map((entry) {
          return ColorElement(
            theme: AppTheme.themes[entry]!,
            themeName: entry,
            enabled: enabled,
            dualColor: themeType == ThemeType.dualColor || themeType == ThemeType.dynamic,
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
  }

  @override
  Widget build(BuildContext context) {
    // This line is important so that textTheme is updated, don't know why
    print(Theme.of(context).colorScheme.onSurfaceVariant.alpha);
    return Selector<UserState, bool>(
        selector: (context, provider) => provider.user!.useGradients,
        builder: (context, useGradients, _) {
          return Card(
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
                  Text('change-theme.preview-hint'.tr(), style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center),
                  SizedBox(height: 15),
                  _colorWrap(ThemeType.simpleColor, enabled: true),
                  SizedBox(height: 10),
                  Divider(),
                  SizedBox(height: 10),
                  Text(
                    'dual_tone_themes'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  Visibility(
                    visible: !useGradients,
                    child: Text(
                      'gradient_available_in_paid_version'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall!
                          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
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
                  Visibility(
                    visible: AppTheme.themes.keys.where((element) => element.type == ThemeType.dynamic).isNotEmpty,
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        Divider(),
                        SizedBox(height: 10),
                        Text(
                          'change-theme.adaptive-theme'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 18),
                          textAlign: TextAlign.center,
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
                        SizedBox(height: 10)
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }
}

class ColorElement extends StatelessWidget {
  final ThemeData theme;
  final ThemeName themeName;
  final bool enabled;
  final bool dualColor;
  const ColorElement({
    required this.theme,
    required this.themeName,
    this.enabled = true,
    this.dualColor = false,
  });

  Future _updateColor(String? name) async {
    Map<String, String?> body = {'theme': name};
    await Http.put(uri: '/user', body: body);
  }

  @override
  Widget build(BuildContext context) {
    final stackWidgetState = context.watch<StackWidgetState>();
    return Selector<AppThemeState, ThemeName>(
        selector: (context, provider) => provider.themeName,
        builder: (context, currentThemeName, _) {
          Color splitColor = theme.colorScheme.onPrimary;
          return Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                strokeAlign: BorderSide.strokeAlignOutside,
                color: currentThemeName == themeName ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
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
                          colors: [theme.colorScheme.primary, splitColor, splitColor, theme.colorScheme.secondary],
                          stops: [0.48, 0.48, 0.52, 0.52],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (enabled) {
                      context.read<AppThemeState>().themeName = themeName;
                      _updateColor(themeName.storageName);
                    } else if (context.read<AppConfig>().isIAPPlatformEnabled) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => StorePage()));
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return IAPNotSupportedDialog();
                        },
                      );
                    }
                  },
                  onLongPressStart: (details) => stackWidgetState.setWidget(
                    ThemePreview(
                      themeName: themeName,
                      offset: details.globalPosition,
                    ),
                  ),
                  onLongPressEnd: (_) => stackWidgetState.hideWidget(),
                  onLongPressCancel: () => stackWidgetState.hideWidget(),
                  child: SizedBox.square(
                    dimension: dualColor ? 40 : 30,
                  ),
                ),
              ),
            ),
          );
        });
  }
}
