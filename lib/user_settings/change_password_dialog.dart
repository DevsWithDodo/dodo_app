import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/validation_rules.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../essentials/http_handler.dart';
import '../essentials/widgets/future_success_dialog.dart';
import '../essentials/widgets/gradient_button.dart';
import '../groups/main_group_page.dart';

class ChangePasswordDialog extends StatefulWidget {
  @override
  _ChangePasswordDialogState createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  TextEditingController _oldPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  TextEditingController _passwordReminderController = TextEditingController();
  var _formKey = GlobalKey<FormState>();
  int _index = 0;
  List<TextFormField> textFields = <TextFormField>[];

  Future<bool> _updatePassword(String oldPassword, String newPassword, String reminder) async {
    try {
      Map<String, dynamic> body = {
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
        "password_reminder": reminder,
      };

      await httpPut(uri: '/user', context: context, body: body);
      Future.delayed(delayTime()).then((value) => _onUpdatePassword());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onUpdatePassword() {
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (context) => MainPage()), (route) => false);
  }

  void initTextFields() {
    textFields = [
      TextFormField(
        validator: (value) => validateTextField([isEmpty(value)]),
        decoration: InputDecoration(
          hintText: (usesPassword! ? 'old_password' : 'old_pin').tr(),
          prefixIcon: Icon(
            Icons.password,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        keyboardType: usesPassword! ? null : TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
        ],
        controller: _oldPasswordController,
        obscureText: true,
      ),
      TextFormField(
        validator: (value) => validateTextField([
          isEmpty(value),
          minimalLength(value, 4),
        ]),
        decoration: InputDecoration(
          hintText: (usesPassword! ? 'new_password' : 'new_pin').tr(),
          prefixIcon: Icon(
            Icons.password,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        keyboardType: usesPassword! ? null : TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
        ],
        controller: _newPasswordController,
        obscureText: true,
      ),
      TextFormField(
        validator: (value) => validateTextField([
          matchString(value, _newPasswordController.text),
          isEmpty(value),
          minimalLength(value, 4),
        ]),
        decoration: InputDecoration(
          hintText: (usesPassword! ? 'new_password_confirm' : 'new_pin_confirm').tr(),
          prefixIcon: Icon(
            Icons.password,
          ),
        ),
        keyboardType: usesPassword! ? null : TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
        ],
        controller: _confirmPasswordController,
        obscureText: true,
      ),
      TextFormField(
        validator: (value) => validateTextField([
          isEmpty(value),
          minimalLength(value, 3),
        ]),
        controller: _passwordReminderController,
        decoration: InputDecoration(
          hintText: 'password_reminder'.tr(),
          prefixIcon: Icon(
            Icons.search,
          ),
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(50),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    initTextFields();
    return Form(
      key: _formKey,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                (usesPassword! ? 'change_password' : 'change_pin').tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: textFields[_index],
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Visibility(
                    visible: _index != 0,
                    child: GradientButton(
                      onPressed: () {
                        setState(() {
                          _index--;
                        });
                      },
                      child: Icon(
                        Icons.arrow_left,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  GradientButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        FocusScope.of(context).unfocus();
                        if (_index < (usesPassword! ? 3 : 2)) {
                          setState(() {
                            _index++;
                          });
                        } else {
                          showDialog(
                              builder: (context) => FutureSuccessDialog(
                                    future: _updatePassword(
                                        _oldPasswordController.text,
                                        _newPasswordController.text,
                                        _passwordReminderController.text),
                                    dataTrueText:
                                        usesPassword! ? 'change_password_scf' : 'change_pin_scf',
                                    onDataTrue: () {
                                      _onUpdatePassword();
                                    },
                                  ),
                              barrierDismissible: false,
                              context: context);
                        }
                      }
                    },
                    child: Icon(
                      _index == 3 ? Icons.check : Icons.arrow_right,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
