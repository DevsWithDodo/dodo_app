import 'dart:convert';

import 'package:csocsort_szamla/components/auth/pin_pad.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PinVerificationDialog extends StatefulWidget {
  const PinVerificationDialog({super.key});

  @override
  State<PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  String pin = '';

  Future<BoolFutureOutput> checkPin() async {
    var response = await Http.post(
      uri: "/user/verify_password",
      body: {
        'password': pin,
      },
    );
    if (mounted) {
      UserState provider = context.read<UserState>();
      provider.setUserStatus(UserStatus.fromJson(jsonDecode(response.body)));
    }
    return BoolFutureOutput.True;
  }

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
                'pin-verification.title'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                'pin-verification.description'.tr(),
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 20,
              ),
              PinPad(
                pin: pin,
                onPinChanged: (text) => setState(() => pin = text),
                maxWidth: 260,
              ),
              GradientButton.icon(
                icon: Icon(Icons.check),
                label: Text('pin-verification.check'.tr()),
                onPressed: () {
                  showFutureOutputDialog(context: context, future: checkPin(), outputCallbacks: {
                    BoolFutureOutput.True: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  });
                },
              ),
              // SizedBox(height: 5),
              // TextButton(onPressed: () {}, child: Text('pin-verification.forgot-pin'.tr())),
            ],
          ),
        ),
      ),
    );
  }
}
