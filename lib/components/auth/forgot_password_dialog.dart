import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/pages/auth/login/forgot_password_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';


class ForgotPasswordDialog extends StatelessWidget {
  ForgotPasswordDialog();

  final GlobalKey<FormState> formState = GlobalKey<FormState>();
  final TextEditingController controller =
      TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Form(
      key: formState,
      child: AlertDialog(
        title: Center(
          child: Text(
            'forgot_password'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        content: TextFormField(
          controller: controller,
          initialValue: context.watch<User?>()?.username,
          validator: (value) => validateTextField([
            isEmpty(value),
            minimalLength(value, 3),
          ]),
          decoration: InputDecoration(
            hintText: 'username'.tr(),
            filled: true,
            prefixIcon: Icon(
              Icons.account_circle,
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[a-z0-9]')),
            LengthLimitingTextInputFormatter(15),
          ],
          onFieldSubmitted: (value) => _buttonPush(context),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GradientButton(
                onPressed: () {
                  _buttonPush(context);
                },
                child: Icon(Icons.send),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _buttonPush(BuildContext context) {
    if (formState.currentState!.validate()) {
      String username = controller.text;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ForgotPasswordPage(
            username: username,
          ),
        ),
      );
    }
  }
}
