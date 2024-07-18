import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../helpers/http.dart';
import '../../../helpers/validation_rules.dart';
import '../../helpers/future_output_dialog.dart';
import '../../helpers/gradient_button.dart';

class ChangeNicknameDialog extends StatefulWidget {
  final String username;
  final int memberId;
  ChangeNicknameDialog({required this.username, required this.memberId});

  @override
  _ChangeNicknameDialogState createState() => _ChangeNicknameDialogState();
}

class _ChangeNicknameDialogState extends State<ChangeNicknameDialog> {
  TextEditingController _nicknameController = TextEditingController();
  var _nicknameFormKey = GlobalKey<FormState>();

  Future<BoolFutureOutput> _updateNickname(String nickname, int? memberId) async {
    try {
      Map<String, dynamic> body = {"member_id": memberId, "nickname": nickname};
      await Http.put(
            uri: '/groups/' + context.read<UserState>().currentGroup!.id.toString() + '/members',
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
                'edit_nickname'.tr(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                    labelText: 'nickname'.tr(),
                    prefixIcon: Icon(
                      Icons.account_circle,
                    ),
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(15),
                  ],
                  onFieldSubmitted: (value) => _buttonPushed(),
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
                  onPressed: _buttonPushed,
                  child: Icon(Icons.check),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _buttonPushed() {
    if (_nicknameFormKey.currentState!.validate()) {
      FocusScope.of(context).requestFocus(FocusNode());
      String nickname = _nicknameController.text[0].toUpperCase() +
          _nicknameController.text.substring(1);
      showFutureOutputDialog(
        context: context,
        future: _updateNickname(nickname, widget.memberId),
        outputCallbacks: {
          BoolFutureOutput.True: () async {
            _nicknameController.text = '';
            Navigator.pop(context);
            Navigator.pop(context, true);
            EventBus.instance.fire(EventBus.refreshBalances);
            EventBus.instance.fire(EventBus.refreshGroupMembers);
            EventBus.instance.fire(EventBus.refreshPurchases);
            EventBus.instance.fire(EventBus.refreshPayments);
            EventBus.instance.fire(EventBus.refreshShopping);
          }
        }
      );
    }
  }
}
