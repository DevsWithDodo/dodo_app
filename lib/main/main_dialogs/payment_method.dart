import 'package:csocsort_szamla/essentials/event_bus.dart';
import 'package:csocsort_szamla/main/main_dialogs/bottom_dialog.dart';
import 'package:csocsort_szamla/main/main_dialogs/main_dialog.dart';
import 'package:csocsort_szamla/user_settings/user_settings_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PaymentMethodMainDialog extends MainDialog {
  const PaymentMethodMainDialog({
    required super.canShow,
    required super.showTime,
    required super.type,
    super.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return MainBottomDialog(
      title: Text('main-dialog.payment-methods.title'.tr()),
      subtitle: Text('main-dialog.payment-methods.subtitle'.tr()),
      icon: Icon(Icons.payment),
      button: TextButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => Settings()),
          );
          EventBus.instance.fire(EventBus.hideMainDialog);
        },
        child: Text('main-dialog.payment-methods.button'.tr()),
      ),
    );
  }
}
