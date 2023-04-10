import 'dart:io';

import 'package:csocsort_szamla/essentials/save_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../essentials/widgets/gradient_button.dart';
import 'custom_alert_dialog.dart';
import 'package:flutter/material.dart';

class RateAppDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomAlertDialog(
      centerBody: true,
      content: {
        'title': 'thank_you',
        'body': [
          'even_one_rating_helps',
        ]
      },
      actions: Center(
        child: GradientButton(
          child: Text(
            'to_store'.tr(),
            style: Theme.of(context)
                .textTheme
                .labelLarge!
                .copyWith(color: Theme.of(context).colorScheme.onPrimary),
          ),
          onPressed: () {
            String url = "";
            switch (Platform.operatingSystem) {
              case "android":
                url = "market://details?id=csocsort.hu.machiato32.csocsort_szamla";
                break;
              case "windows":
                url = "ms-windows-store://pdp/?productid=9NVB4CZJDSQ7";
                break;
              case "ios":
                url = "itms-apps://itunes.apple.com/app/id1558223634?action=write-review";
                break;
              default:
                url =
                    "https://play.google.com/store/apps/details?id=csocsort.hu.machiato32.csocsort_szamla";
                break;
            }
            launchUrlString(url);
            saveRatedApp(true);
          },
        ),
      ),
    );
  }
}
