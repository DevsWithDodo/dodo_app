import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config.dart';
import '../../essentials/http_handler.dart';
import '../../essentials/validation_rules.dart';
import '../../essentials/widgets/future_success_dialog.dart';
import '../../essentials/widgets/gradient_button.dart';
import '../main_group_page.dart';

class AddGuestDialog extends StatefulWidget {
  AddGuestDialog();

  @override
  _AddGuestDialogState createState() => _AddGuestDialogState();
}

class _AddGuestDialogState extends State<AddGuestDialog> {
  TextEditingController _nicknameController = TextEditingController();
  var _nicknameFormKey = GlobalKey<FormState>();
  Future<bool> _addGuest(String username) async {
    try {
      Map<String, dynamic> body = {"language": context.locale.languageCode, "username": username};
      await httpPost(
          uri: '/groups/' + currentGroupId.toString() + '/add_guest', context: context, body: body);
      Future.delayed(delayTime()).then((value) => _onAddGuest());
      return true;
    } catch (_) {
      throw _;
    }
  }

  Future<void> _onAddGuest() async {
    await clearGroupCache();
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (context) => MainPage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                'add_guest'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Form(
              key: _nicknameFormKey,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: TextFormField(
                  validator: (value) => validateTextField([
                    isEmpty(value),
                    minimalLength(value, 1),
                  ]),
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    hintText: 'nickname'.tr(),
                    filled: true,
                    prefixIcon: Icon(
                      Icons.account_circle,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(15),
                  ],
                  onFieldSubmitted: (value) => _buttonPush(),
                ),
              ),
            ),
            SizedBox(
              height: 15,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GradientButton(
                  onPressed: _buttonPush,
                  child: Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _buttonPush() {
    if (_nicknameFormKey.currentState.validate()) {
      FocusScope.of(context).requestFocus(FocusNode());
      showDialog(
          builder: (context) => FutureSuccessDialog(
                future: _addGuest(_nicknameController.text),
                onDataTrue: () async {
                  _onAddGuest();
                },
                dataTrueText: 'add_guest_scf',
              ),
          barrierDismissible: false,
          context: context);
    }
  }
}
