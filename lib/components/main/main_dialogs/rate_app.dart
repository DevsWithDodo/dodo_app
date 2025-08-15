import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/main/dialogs/custom_alert_dialog.dart';
import 'package:csocsort_szamla/components/main/main_dialogs/main_dialog.dart';
import 'package:csocsort_szamla/helpers/providers/user_usage_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class RateAppMainDialog extends MainDialog {
  const RateAppMainDialog({
    super.key,
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
        'title': 'rate-app-dialog.title',
        'body': ['rate-app-dialog.content'],
      },
      actions: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientButton(
            useSecondary: true,
            child: Text('rate-app-dialog.later'.tr()),
            onPressed: () => super.onDismiss?.call(context),
          ),
          SizedBox(height: 8),
          GradientButton(
            child: Text('rate-app-dialog.rate-now'.tr()),
            onPressed: () async {
              launchUrlString(getShopURL());
              context.read<UserUsageNotifier>().setRatedApp(true);
              super.onDismiss?.call(context);
            },
          ),
        ],
      ),
    );
  }
}
