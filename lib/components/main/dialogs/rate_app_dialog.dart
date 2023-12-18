import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
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
            launchUrlString(getShopURL());
            context.read<UserState>().setRatedApp(true);
          },
        ),
      ),
    );
  }
}
