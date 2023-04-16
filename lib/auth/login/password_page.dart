import 'package:csocsort_szamla/auth/login/login_methods.dart';
import 'package:csocsort_szamla/auth/login/login_pin_page.dart';
import 'package:csocsort_szamla/essentials/save_preferences.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../essentials/validation_rules.dart';
import '../../essentials/widgets/gradient_button.dart';

class PasswordPage extends StatefulWidget {
  final String? inviteUrl;
  final String? username;
  PasswordPage({this.inviteUrl, this.username});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  TextEditingController _passwordController = TextEditingController();
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
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Center(
                  child: Text(
                    'password_login_deprecated'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
                Center(
                  child: Text(
                    'password_login_deprecated_explanation'.tr(),
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        TextFormField(
                          validator: (value) => validateTextField([
                            isEmpty(value),
                          ]),
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: 'password'.tr(),
                            helperText: _passwordController.text != ''
                                ? 'password'.tr()
                                : null,
                            prefixIcon: Icon(
                              Icons.password,
                            ),
                          ),
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp('[A-Za-z0-9]')),
                          ],
                          onChanged: (value) => setState(() {}),
                          onFieldSubmitted: (value) => _pushButton(),
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
                        builder: (context) => LoginPinPage(
                          username: widget.username,
                          inviteUrl: widget.inviteUrl,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'change_to_pin'.tr(),
                    style: Theme.of(context).textTheme.labelLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 15, 10, 30),
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
                        onPressed: _pushButton,
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

  void _pushButton() {
    saveUsesPassword(true);
    showDialog(
      context: context,
      builder: (context) => FutureSuccessDialog(
        future: LoginMethods.login(
          widget.username,
          _passwordController.text,
          context,
          widget.inviteUrl,
          true,
        ),
      ),
    );
  }
}
