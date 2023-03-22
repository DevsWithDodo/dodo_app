import 'package:csocsort_szamla/auth/login/forgot_password_dialog.dart';
import 'package:csocsort_szamla/auth/login/login_pin_page.dart';
import 'package:csocsort_szamla/auth/registration/register_pin_page.dart';
import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;

import '../essentials/validation_rules.dart';
import '../essentials/widgets/gradient_button.dart';

class NamePage extends StatefulWidget {
  final String inviteUrl;
  final bool isLogin;
  NamePage({this.inviteUrl, this.isLogin = false});
  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  TextEditingController _usernameController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  ExpandableController _usernameExplanationController = ExpandableController();
  bool _privacyPolicy = false;
  bool _showPrivacyPolicyValidation = false;
  bool _usernameTaken = false;

  @override
  void initState() {
    super.initState();
    if (widget.isLogin && currentUsername != null) {
      _usernameController.text = currentUsername;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text((widget.isLogin ? 'login' : 'register').tr()),
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
                    child: Center(
                      child: ListView(
                        padding: EdgeInsets.only(left: 20, right: 20),
                        shrinkWrap: true,
                        children: <Widget>[
                          TextFormField(
                            validator: (value) => validateTextField([
                              isEmpty(value),
                              minimalLength(value, 3),
                              allowedRegEx(value, RegExp(r'[^a-z0-9.]+')),
                              ...(_usernameTaken ? [throwError('username_taken'.tr())] : []),
                            ]),
                            onChanged: (value) => setState(() {}),
                            onFieldSubmitted: (value) => _buttonPush(),
                            controller: _usernameController,
                            decoration: InputDecoration(
                              hintText: 'username'.tr(),
                              helperText: widget.isLogin && _usernameController.text != ''
                                  ? 'username'.tr()
                                  : null,
                              prefixIcon: Icon(
                                Icons.account_circle,
                              ),
                              suffixIcon: widget.isLogin
                                  ? null
                                  : IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _usernameExplanationController.expanded =
                                              !_usernameExplanationController.expanded;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.info_outline,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                            ),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(15),
                            ],
                          ),
                          Visibility(
                            visible: widget.isLogin,
                            child: Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (context) => ForgotPasswordDialog());
                                    },
                                    child: Text(
                                      'forgot_password'.tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          .copyWith(color: Theme.of(context).colorScheme.onSurface),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: !widget.isLogin,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 10,
                                ),
                                Expandable(
                                  controller: _usernameExplanationController,
                                  collapsed: Container(),
                                  expanded: Container(
                                    constraints: BoxConstraints(maxHeight: 80),
                                    padding: EdgeInsets.only(left: 8, right: 8),
                                    child: Text(
                                      'username_explanation'.tr(),
                                      style: Theme.of(context).textTheme.bodySmall.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: TextButton(
                                        onPressed: () {
                                          launchUrlString('https://dodoapp.net/privacy-policy');
                                        },
                                        child: Text(
                                          'accept_privacy_policy'.tr() + '*',
                                          style: Theme.of(context).textTheme.labelLarge.copyWith(
                                              decoration: TextDecoration.underline,
                                              color: Theme.of(context).colorScheme.onSurface),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: _privacyPolicy,
                                      onChanged: (value) {
                                        setState(() {
                                          _privacyPolicy = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                AnimatedCrossFade(
                                  duration: Duration(milliseconds: 100),
                                  crossFadeState: _showPrivacyPolicyValidation
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  firstChild: Container(),
                                  secondChild: Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Text(
                                      'must_accept_privacy_policy'.tr(),
                                      style: Theme.of(context).textTheme.bodySmall.copyWith(
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GradientButton(
                        child: Icon(
                          Icons.arrow_right,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: _buttonPush,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _buttonPush() async {
    _usernameController.text = _usernameController.text.toLowerCase();
    if (widget.isLogin) {
      if (_formKey.currentState.validate()) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPinPage(
              inviteUrl: widget.inviteUrl,
              username: _usernameController.text,
            ),
          ),
        );
      }
    } else {
      _usernameTaken = false;
      _showPrivacyPolicyValidation = false;
      if (_formKey.currentState.validate() && _privacyPolicy) {
        showDialog(
          context: context,
          builder: (context) => FutureSuccessDialog(
            future: _checkUsernameTaken(),
            dataFalseText: 'username_taken',
          ),
        );
      } else if (!_privacyPolicy) {
        setState(() {
          _showPrivacyPolicyValidation = true;
        });
      }
    }
  }

  Future<bool> _checkUsernameTaken() async {
    http.Response response = await http.post(
      Uri.parse((useTest ? TEST_URL : APP_URL) + '/validate_username'),
      body: {
        'username': _usernameController.text,
      },
    );
    if (response.statusCode == 204) {
      Future.delayed(delayTime()).then((value) => _onCheckUsernameTaken());
      return true;
    } else {
      _usernameTaken = true;
      _formKey.currentState.validate();
      return false;
    }
  }

  void _onCheckUsernameTaken() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPinPage(
          inviteUrl: widget.inviteUrl,
          username: _usernameController.text,
        ),
      ),
    );
  }
}
