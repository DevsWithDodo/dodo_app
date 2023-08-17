import 'package:csocsort_szamla/auth/pin_pad.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PinPracticeDialog extends StatefulWidget {
  const PinPracticeDialog({super.key});

  @override
  State<PinPracticeDialog> createState() => _PinPracticeDialogState();
}

class _PinPracticeDialogState extends State<PinPracticeDialog> {
  String pin = '';

  // Future<bool> checkPin() async {
  //   Http.get(uri: generateUri(GetUriKeys.pass, context))
  // }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'pin-practice.title'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                'pin-practice.description'.tr(),
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 20,
              ),
              PinPad(pin: pin, onPinChanged: (text) => setState(() => pin = text)),
              GradientButton.icon(icon: Icon(Icons.check), label: Text('pin-practice.check'.tr()), onPressed: () {},),
              SizedBox(height: 5),
              TextButton(onPressed: () {}, child: Text('pin-practice.forgot-pin'.tr())),
            ],
          ),
        ),
      ),
    );
  }
}