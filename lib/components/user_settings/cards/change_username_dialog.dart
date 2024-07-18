import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ChangeUsernameDialog extends StatefulWidget {
  @override
  _ChangeUsernameDialogState createState() => _ChangeUsernameDialogState();
}

class _ChangeUsernameDialogState extends State<ChangeUsernameDialog> {
  var _usernameFormKey = GlobalKey<FormState>();
  var _usernameController = TextEditingController();

  Future<BoolFutureOutput> _updateUsername(String newUsername) async {
    try {
      Map<String, dynamic> body = {'username': newUsername};

      await Http.put(uri: '/user', body: body);
      context.read<UserState>().setUsername(newUsername);
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _usernameFormKey,
      child: Dialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'change_username'.tr(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: TextFormField(
                  validator: (value) => validateTextField([
                    isEmpty(value),
                    minimalLength(value, 1),
                  ]),
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'new_name'.tr(),
                    prefixIcon: Icon(
                      Icons.account_circle,
                    ),
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(20),
                  ],
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GradientButton(
                    onPressed: () {
                      if (_usernameFormKey.currentState!.validate()) {
                        FocusScope.of(context).unfocus();
                        String username = _usernameController.text;
                        showFutureOutputDialog(
                          context: context,
                          future: _updateUsername(username),
                        );
                      }
                    },
                    child: Icon(Icons.check),
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
