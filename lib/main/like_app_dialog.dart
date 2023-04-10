import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/main/custom_alert_dialog.dart';
import 'package:csocsort_szamla/main/rate_app_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LikeTheAppDialog extends StatelessWidget {
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
            child: Text('no'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .labelLarge!
                    .copyWith(color: Theme.of(context).colorScheme.onSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          GradientButton(
            child: Text('yes'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .labelLarge!
                    .copyWith(color: Theme.of(context).colorScheme.onPrimary)),
            onPressed: () {
              Navigator.pop(context);
              showDialog(context: context, builder: (context) => RateAppDialog());
            },
          ),
        ],
      ),
    );
  }
}
