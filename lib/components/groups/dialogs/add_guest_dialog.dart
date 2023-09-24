import 'package:csocsort_szamla/helpers/providers/app_state_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../helpers/http.dart';
import '../../../helpers/validation_rules.dart';
import '../../helpers/future_output_dialog.dart';
import '../../helpers/gradient_button.dart';

import 'package:csocsort_szamla/helpers/event_bus.dart';

class AddGuestDialog extends StatefulWidget {
  AddGuestDialog();

  @override
  _AddGuestDialogState createState() => _AddGuestDialogState();
}

class _AddGuestDialogState extends State<AddGuestDialog> {
  TextEditingController _nicknameController = TextEditingController();
  var _nicknameFormKey = GlobalKey<FormState>();
  Future<BoolFutureOutput> _addGuest(String username) async {
    try {
      Map<String, dynamic> body = {
        "language": context.locale.languageCode,
        "username": username
      };
      await Http.post(
            uri: '/groups/' + context.read<AppStateProvider>().currentGroup!.id.toString() + '/add_guest',
            body: body,
          );
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
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
                    .titleLarge!
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
                  child: Icon(Icons.check),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _buttonPush() {
    if (_nicknameFormKey.currentState!.validate()) {
      FocusScope.of(context).requestFocus(FocusNode());
      showFutureOutputDialog(
          context: context,
          future: _addGuest(_nicknameController.text),
          outputCallbacks: {
            BoolFutureOutput.True: () async {
              EventBus.instance.fire(EventBus.refreshBalances);
              EventBus.instance.fire(EventBus.refreshGroupMembers);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            }
          }
      );
    }
  }
}
