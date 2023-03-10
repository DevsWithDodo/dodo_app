import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/app_state_notifier.dart';
import 'package:csocsort_szamla/essentials/app_theme.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/main/iapp_not_supported_dialog.dart';
import 'package:csocsort_szamla/main/in_app_purchase_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorPicker extends StatefulWidget {
  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  List<Widget> _getDynamicColors({bool enabled}) {
    return AppTheme.themes.entries.where((element) => element.key.contains('Dynamic')).map((entry) {
      return ColorElement(
        theme: entry.value,
        themeName: entry.key,
        enabled: enabled,
        dualColor: true,
      );
    }).toList();
  }

  List<Widget> _getSimpleColors() {
    return AppTheme.simpleColorThemes.map((entry) {
      return ColorElement(
        theme: AppTheme.themes[entry],
        themeName: entry,
      );
    }).toList();
  }

  List<Widget> _getDualColors({bool enabled}) {
    return AppTheme.dualColorThemes.map((entry) {
      return ColorElement(
        theme: AppTheme.themes[entry],
        themeName: entry,
        dualColor: true,
        enabled: enabled,
      );
    }).toList();
  }

  List<Widget> _getGradientColors({bool enabled}) {
    return AppTheme.gradientColors.keys.map((entry) {
      return ColorElement(
        theme: AppTheme.themes[entry],
        themeName: entry,
        enabled: enabled,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                  .titleLarge
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            )),
            SizedBox(height: 10),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                runSpacing: 5,
                spacing: 5,
                children: _getSimpleColors(),
              ),
            ),
            SizedBox(
              height: 7,
            ),
            Divider(),
            SizedBox(
              height: 7,
            ),
            Text(
              'dual_tone_themes'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            Visibility(
              visible: !useGradients,
              child: Text(
                'gradient_available_in_paid_version'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 7,
            ),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                runSpacing: 5,
                spacing: 5,
                children: _getDualColors(enabled: useGradients),
              ),
            ),
            Text(
              'gradient_themes'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 10,
            ),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                runSpacing: 5,
                spacing: 5,
                children: _getGradientColors(enabled: useGradients),
              ),
            ),
            Visibility(
              visible: AppTheme.themes.keys.contains('darkDynamic'),
              child: Column(
                children: [
                  SizedBox(
                    height: 7,
                  ),
                  Divider(),
                  SizedBox(
                    height: 7,
                  ),
                  Text(
                    'dynamic_themes'.tr(),
                    style: Theme.of(context).textTheme.titleLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 3,
                  ),
                  Text(
                    'dynamic_themes_explanation'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 3,
                  ),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      runSpacing: 5,
                      spacing: 5,
                      children: _getDynamicColors(enabled: useGradients),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ColorElement extends StatefulWidget {
  final ThemeData theme;
  final String themeName;
  final bool enabled;
  final bool dualColor;
  const ColorElement({this.theme, this.themeName, this.enabled = true, this.dualColor = false});

  @override
  _ColorElementState createState() => _ColorElementState();
}

class _ColorElementState extends State<ColorElement> {
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future _postColor(String name) async {
    Map<String, String> body = {'theme': name};
    await httpPut(context: context, uri: '/user', body: body);
  }

  @override
  Widget build(BuildContext context) {
    return Ink(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: (widget.themeName == currentThemeName)
            ? widget.dualColor
                ? LinearGradient(
                    colors: [widget.theme.colorScheme.primary, widget.theme.colorScheme.secondary],
                    stops: [0.5, 0.5],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  )
                : AppTheme.gradientFromTheme(widget.themeName, useSecondary: true)
            : LinearGradient(colors: [Colors.transparent, Colors.transparent]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (widget.enabled) {
            Provider.of<AppStateNotifier>(context, listen: false).updateTheme(widget.themeName);
            _getPrefs().then((_prefs) {
              _prefs.setString('theme', widget.themeName);
            });
            _postColor(widget.themeName);
          } else if (isIAPPlatformEnabled) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => InAppPurchasePage()));
          } else {
            showDialog(
              context: context,
              builder: (context) {
                return IAPPNotSupportedDialog();
              },
            );
          }
        },
        child: Ink(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: widget.dualColor
                ? LinearGradient(
                    colors: [widget.theme.colorScheme.primary, widget.theme.colorScheme.secondary],
                    stops: [0.5, 0.5],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  )
                : AppTheme.gradientFromTheme(widget.themeName),
            border: Border.all(color: widget.theme.colorScheme.surface, width: 6),
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }
}
