import 'package:csocsort_szamla/essentials/event_bus.dart';
import 'package:csocsort_szamla/essentials/widgets/pin_verification_dialog.dart';
import 'package:csocsort_szamla/main/main_dialogs/bottom_dialog.dart';
import 'package:csocsort_szamla/main/main_dialogs/main_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PinVerificationMainDialog extends MainDialog {
  const PinVerificationMainDialog({
    required super.canShow,
    required super.showTime,
    required super.type,
    super.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return MainBottomDialog(
      title: Text('main-dialog.pin-verification.title'.tr()),
      subtitle: Flexible(
        child: Text('main-dialog.pin-verification.subtitle'.tr()),
      ),
      icon: Icon(Icons.password),
      button: TextButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => PinVerificationDialog(),
          );
          EventBus.instance.fire(EventBus.hideMainDialog);
        },
        child: Text('main-dialog.pin-verification.button'.tr()),
      ),
    );
  }
}
