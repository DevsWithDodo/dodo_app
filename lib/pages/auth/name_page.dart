import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/pages/auth/login/login_pin_page.dart';
import 'package:csocsort_szamla/pages/auth/sign_up/sign_up_pin_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../components/helpers/gradient_button.dart';
import '../../helpers/validation_rules.dart';

class NamePage extends StatefulWidget {
  final bool isLogin;
  const NamePage({super.key, this.isLogin = false});
  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  final TextEditingController _usernameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final ExpandableController _usernameExplanationController = ExpandableController();
  bool _privacyPolicy = false;
  bool _showPrivacyPolicyValidation = false;
  bool _usernameTaken = false;

  @override
  void initState() {
    super.initState();
    if (widget.isLogin) {
      _usernameController.text = context.read<SharedPreferences>().getString('current_username') ?? '';
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
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
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
                                    labelText: 'username'.tr(),
                                    prefixIcon: Icon(
                                      Icons.account_circle,
                                    ),
                                  ),
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(15),
                                  ],
                                ),
                              ),
                              if (!widget.isLogin)
                                IconButton.filledTonal(
                                  onPressed: () {
                                    setState(() {
                                      _usernameExplanationController.expanded = !_usernameExplanationController.expanded;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.info_outline,
                                  ),
                                ),
                            ],
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
                                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                                          '${'accept_privacy_policy'.tr()}*',
                                          style: Theme.of(context).textTheme.labelLarge!.copyWith(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.onSurface),
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
                                  crossFadeState: _showPrivacyPolicyValidation ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                  firstChild: Container(),
                                  secondChild: Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Text(
                                      'must_accept_privacy_policy'.tr(),
                                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
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
                        onPressed: _buttonPush,
                        child: Icon(Icons.arrow_right),
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
      if (_formKey.currentState!.validate()) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPinPage(
              username: _usernameController.text,
            ),
          ),
        );
      }
    } else {
      _usernameTaken = false;
      _showPrivacyPolicyValidation = false;
      if (_formKey.currentState!.validate() && _privacyPolicy) {
        showFutureOutputDialog(context: context, future: _checkUsernameTaken(), outputTexts: {
          BoolFutureOutput.False: 'username_taken'
        }, outputCallbacks: {
          BoolFutureOutput.True: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SignUpPinPage(
                  username: _usernameController.text,
                ),
              ),
            );
          }
        });
      } else if (!_privacyPolicy) {
        setState(() {
          _showPrivacyPolicyValidation = true;
        });
      }
    }
  }

  Future<BoolFutureOutput> _checkUsernameTaken() async {
    http.Response response = await http.post(
      Uri.parse('${context.read<AppConfig>().appUrl}/validate_username'),
      body: {
        'username': _usernameController.text,
      },
    );
    if (response.statusCode == 204) {
      return BoolFutureOutput.True;
    } else {
      _usernameTaken = true;
      _formKey.currentState!.validate();
      return BoolFutureOutput.False;
    }
  }
}
