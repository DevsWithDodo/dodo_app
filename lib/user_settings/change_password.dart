import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'change_password_dialog.dart';

class ChangePassword extends StatefulWidget {
  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
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
                'change_password'.tr(),
                style:
                Theme.of(context).textTheme.headline6,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Center(
                child: Text(
                  'change_password_explanation'.tr(),
                  style:
                  Theme.of(context).textTheme.subtitle2,
                  textAlign: TextAlign.center,
                )
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GradientButton(
                  child: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSecondary,),
                  onPressed: (){
                    showDialog(builder: (context) => ChangePasswordDialog(), context: context);
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
