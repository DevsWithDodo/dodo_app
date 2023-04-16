import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/main/report_a_bug_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ReportBug extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Center(
              child: Text(
                'report_bug'.tr(),
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
              'report_bug_explanation'.tr(),
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            )),
            SizedBox(
              height: 20,
            ),
            GradientButton(
              child: Icon(Icons.bug_report),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ReportABugPage()));
              },
            )
          ],
        ),
      ),
    );
  }
}
