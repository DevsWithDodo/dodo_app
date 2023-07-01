import 'package:csocsort_szamla/essentials/validation_rules.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../essentials/http.dart';
import '../essentials/widgets/future_success_dialog.dart';
import '../essentials/widgets/gradient_button.dart';
import '../groups/main_group_page.dart';

class ChangePasswordDialog extends StatefulWidget {
  @override
  _ChangePasswordDialogState createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  TextEditingController _oldPinController = TextEditingController();
  TextEditingController _newPinController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  var _formKey = GlobalKey<FormState>();
  int _index = 0;
  List<TextFormField> textFields = <TextFormField>[];

  Future<bool> _updatePassword(
      String oldPassword, String newPassword) async {
    try {
      Map<String, dynamic> body = {
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
        "password_reminder": "",
      };

      await Http.put(uri: '/user', body: body);
      Future.delayed(delayTime()).then((value) => _onUpdatePassword());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onUpdatePassword() {
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => MainPage()), (route) => false);
  }

  void initTextFields() {
    textFields = [
      TextFormField(
        validator: (value) => validateTextField([isEmpty(value)]),
        decoration: InputDecoration(
          hintText: 'old_pin'.tr(),
          prefixIcon: Icon(
            Icons.password,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
        ],
        controller: _oldPinController,
        obscureText: true,
      ),
      TextFormField(
        validator: (value) => validateTextField([
          isEmpty(value),
          minimalLength(value, 4),
        ]),
        decoration: InputDecoration(
          hintText: 'new_pin'.tr(),
          prefixIcon: Icon(
            Icons.password,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
        ],
        controller: _newPinController,
        obscureText: true,
      ),
      TextFormField(
        validator: (value) => validateTextField([
          matchString(value, _newPinController.text),
          isEmpty(value),
          minimalLength(value, 4),
        ]),
        decoration: InputDecoration(
          hintText:
              'new_pin_confirm'.tr(),
          prefixIcon: Icon(
            Icons.password,
          ),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
        ],
        controller: _confirmPasswordController,
        obscureText: true,
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
                'change_pin'.tr(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                      child: Icon(Icons.arrow_left),
                    ),
                  ),
                  GradientButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        FocusScope.of(context).unfocus();
                        if (_index < 2) {
                          setState(() {
                            _index++;
                          });
                        } else {
                          showDialog(
                              builder: (context) => FutureSuccessDialog(
                                    future: _updatePassword(
                                        _oldPinController.text,
                                        _newPinController.text,
                                      ),
                                    onDataTrue: () {
                                      _onUpdatePassword();
                                    },
                                  ),
                              barrierDismissible: false,
                              context: context);
                        }
                      }
                    },
                    child: Icon(_index == 3 ? Icons.check : Icons.arrow_right),
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
