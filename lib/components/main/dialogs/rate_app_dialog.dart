import 'dart:io';

import 'package:csocsort_szamla/helpers/providers/app_state_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../helpers/gradient_button.dart';
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
          child: Text('to_store'.tr()),
          onPressed: () {
            String url = "";
            switch (Platform.operatingSystem) {
              case "android":
                url =
                    "market://details?id=csocsort.hu.machiato32.csocsort_szamla";
                break;
              case "windows":
                url = "ms-windows-store://pdp/?productid=9NVB4CZJDSQ7";
                break;
              case "ios":
                url =
                    "itms-apps://itunes.apple.com/app/id1558223634?action=write-review";
                break;
              default:
                url =
                    "https://play.google.com/store/apps/details?id=csocsort.hu.machiato32.csocsort_szamla";
                break;
            }
            launchUrlString(url);
            context.read<AppStateProvider>().setRatedApp(true);
          },
        ),
      ),
    );
  }
}
