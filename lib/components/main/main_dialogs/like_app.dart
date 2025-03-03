import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/main/dialogs/custom_alert_dialog.dart';
import 'package:csocsort_szamla/components/main/main_dialogs/main_dialog.dart';
import 'package:csocsort_szamla/components/main/dialogs/rate_app_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LikeTheAppMainDialog extends MainDialog {

  const LikeTheAppMainDialog({super.key, 
    required super.canShow,
    required super.showTime,
    required super.type,
    super.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return CustomAlertDialog(
      centerBody: true,
      content: {
        'title': 'like_the_app',
        'body': ['🦤']
      },
      actions: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GradientButton(
            useSecondary: true,
            child: Text('no'.tr()),
            onPressed: () => super.onDismiss?.call(context),
          ),
          GradientButton(
            child: Text('yes'.tr()),
            onPressed: () {
              super.onDismiss?.call(context);
              showDialog(
                context: context, 
                builder: (context) => RateAppDialog(),
              );
            },
          ),
        ],
      ),
    );
  }
}
