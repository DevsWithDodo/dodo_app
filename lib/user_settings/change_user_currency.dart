import 'package:csocsort_szamla/user_settings/change_user_currency_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../essentials/widgets/gradient_button.dart';

class ChangeUserCurrency extends StatelessWidget {
  const ChangeUserCurrency();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Text(
                'change_user_currency'.tr(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Center(
                child: Text(
              'change_user_currency_explanation'.tr(),
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            )),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GradientButton(
                  child: Icon(Icons.edit),
                  onPressed: () {
                    showDialog(
                        builder: (context) => ChangeUserCurrencyDialog(),
                        context: context);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
