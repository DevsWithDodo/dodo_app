import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ConfirmLeaveDialog extends StatefulWidget {
  final String title;
  final String choice;

  /// Confirms user choice. Has border and title.
  /// Translates the required [title] and [choice] automatically.
  ConfirmLeaveDialog({required this.choice, required this.title});
  @override
  _ConfirmLeaveDialogState createState() => _ConfirmLeaveDialogState();
}

class _ConfirmLeaveDialogState extends State<ConfirmLeaveDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              widget.title.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              widget.choice.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                GradientButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: Text('yes'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge!
                          .copyWith(color: Theme.of(context).colorScheme.onPrimary)),
                ),
                GradientButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: Text('no'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge!
                          .copyWith(color: Theme.of(context).colorScheme.onPrimary)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
