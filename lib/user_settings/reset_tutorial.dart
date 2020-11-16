import 'package:flutter/material.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class ResetTutorial extends StatefulWidget {
  @override
  _ResetTutorialState createState() => _ResetTutorialState();
}

class _ResetTutorialState extends State<ResetTutorial> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Text(
                  'reset_tutorial'.tr(),
                  style: Theme.of(context).textTheme.headline6,
                )
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              'reset_tutorial_explanation'.tr(),
              style: Theme.of(context).textTheme.subtitle2,
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 20,
            ),
            Center(
              child: RaisedButton.icon(
                color: Theme.of(context).colorScheme.secondary,
                label: Text('okay'.tr(),
                    style: Theme.of(context).textTheme.button),
                icon: Icon(Icons.check,
                    color: Theme.of(context).colorScheme.onSecondary),
                onPressed: () {
                  FeatureDiscovery.clearPreferences(context, ['drawer', 'shopping_list', 'group_settings', 'add_payment_expense', 'settings']);
                  SharedPreferences.getInstance().then((value) => value.setBool('show_tutorial', true));
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
