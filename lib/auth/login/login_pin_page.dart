import 'package:csocsort_szamla/auth/login/login_methods.dart';
import 'package:csocsort_szamla/auth/login/password_page.dart';

import 'package:csocsort_szamla/auth/pin_pad.dart';
import 'package:csocsort_szamla/essentials/save_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../essentials/widgets/future_success_dialog.dart';
import '../../essentials/widgets/gradient_button.dart';

class LoginPinPage extends StatefulWidget {
  final String? inviteUrl;
  final String? username;
  LoginPinPage({this.inviteUrl, this.username});
  @override
  State<LoginPinPage> createState() => _LoginPinPageState();
}

class _LoginPinPageState extends State<LoginPinPage> {
  String _pin = '';
  String? _validationText = null;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('login'.tr()),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        PinPad(
                          pin: _pin,
                          onPinChanged: (newPin) =>
                              setState(() => _pin = newPin),
                          validationText: _validationText,
                          onValidationTextChanged: (newText) =>
                              setState(() => _validationText = newText),
                          showConfirm: false,
                        ),
                      ],
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PasswordPage(
                          username: widget.username,
                          inviteUrl: widget.inviteUrl,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'change_to_password'.tr(),
                    style: Theme.of(context).textTheme.labelLarge,
                    textAlign: TextAlign.center,
                  ), //TODO: forgot PIN, forgot password
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 15, 30, 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GradientButton(
                        child: Icon(
                          Icons.arrow_left,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      GradientButton(
                        child: Icon(
                          Icons.send,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: () {
                          if (_pin.length == 4) {
                            _pushedButton();
                          } else {
                            setState(() {
                              _validationText = '4_needed';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pushedButton() {
    String? username = widget.username;
    String pin = _pin;
    saveUsesPassword(false);
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return FutureSuccessDialog(
          future: LoginMethods.login(
              username, pin, context, widget.inviteUrl, false),
        );
      },
    );
  }
}
