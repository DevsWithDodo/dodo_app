import 'package:csocsort_szamla/components/auth/pin_pad.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/join_group_page.dart';
import 'package:csocsort_szamla/pages/app/main_page.dart';
import 'package:csocsort_szamla/pages/auth/login/password_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../components/helpers/future_output_dialog.dart';
import '../../../components/helpers/gradient_button.dart';

class LoginPinPage extends StatefulWidget {
  final String? inviteUrl;
  final String? username;
  const LoginPinPage({super.key, this.inviteUrl, this.username});
  @override
  State<LoginPinPage> createState() => _LoginPinPageState();
}

class _LoginPinPageState extends State<LoginPinPage> {
  String _pin = '';
  String? _validationText;
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
                          onPinChanged: (newPin) => setState(() => _pin = newPin),
                          validationText: _validationText,
                          onValidationTextChanged: (newText) => setState(() => _validationText = newText),
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
                        child: Icon(Icons.arrow_left),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      GradientButton(
                        child: Icon(Icons.send),
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
    showFutureOutputDialog(
        context: context,
        future: context.read<UserNotifier>().login(username!, pin, context),
        outputCallbacks: {
          LoginFutureOutputs.main: () => Navigator.of(context)
              .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => MainPage()), (r) => false),
          LoginFutureOutputs.joinGroup: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => JoinGroupPage()),
                (route) => false,
              ),
          LoginFutureOutputs.joinGroupFromAuth: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => JoinGroupPage(
                          fromAuth: true,
                        )),
                (route) => false,
              ),
        });
  }
}
