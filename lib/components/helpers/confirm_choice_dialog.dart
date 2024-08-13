import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ConfirmChoiceDialog extends StatefulWidget {
  final String choice;

  ///A dialog to ask the user if they really want to do what they just clicked.
  ///Automatically translates the [choice] string given.
  ///Use with .then to get the value chosen by the user: true for confirmed, false for doesn't confirm, null when dismissed.
  ConfirmChoiceDialog({required this.choice});
  @override
  _ConfirmChoiceDialogState createState() => _ConfirmChoiceDialogState();
}

class _ConfirmChoiceDialogState extends State<ConfirmChoiceDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              widget.choice.tr(),
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!,
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 15,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                GradientButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: Text('yes'.tr()),
                ),
                GradientButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: Text('no'.tr()),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
