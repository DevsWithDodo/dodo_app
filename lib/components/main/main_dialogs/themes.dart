import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/components/main/main_dialogs/bottom_dialog.dart';
import 'package:csocsort_szamla/components/main/main_dialogs/main_dialog.dart';
import 'package:csocsort_szamla/pages/app/user_settings_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ThemesMainDialog extends MainDialog {
  const ThemesMainDialog({
    required super.canShow,
    required super.showTime,
    required super.type,
    super.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return MainBottomDialog(
      title: Text('main-dialog.themes.title'.tr()),
      subtitle: Flexible(
        child: Text('main-dialog.themes.subtitle'.tr()),
      ),
      icon: Icon(Icons.color_lens),
      button: TextButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => UserSettingsPage()),
          );
          EventBus.instance.fire(EventBus.hideMainDialog);
        },
        label: Text('main-dialog.themes.button'.tr()),
        icon: Icon(Icons.settings),
      ),
    );
  }
}