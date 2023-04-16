import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config.dart';
import '../../essentials/http_handler.dart';
import '../../essentials/validation_rules.dart';
import '../../essentials/widgets/future_success_dialog.dart';
import '../../essentials/widgets/gradient_button.dart';

class ChangeNicknameDialog extends StatefulWidget {
  final String? username;
  final int? memberId;
  ChangeNicknameDialog({required this.username, required this.memberId});

  @override
  _ChangeNicknameDialogState createState() => _ChangeNicknameDialogState();
}

class _ChangeNicknameDialogState extends State<ChangeNicknameDialog> {
  TextEditingController _nicknameController = TextEditingController();
  var _nicknameFormKey = GlobalKey<FormState>();

  Future<bool> _updateNickname(String nickname, int? memberId) async {
    try {
      Map<String, dynamic> body = {"member_id": memberId, "nickname": nickname};
      await httpPut(
          uri: '/groups/' + currentGroupId.toString() + '/members',
          context: context,
          body: body);
      Future.delayed(delayTime()).then((value) => _onUpdateNickname());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onUpdateNickname() {
    _nicknameController.text = '';
    Navigator.pop(context);
    Navigator.pop(context, 'madeAdmin');
    clearGroupCache();
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
                    hintText: 'nickname'.tr(),
                    filled: true,
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
      showDialog(
          builder: (context) => FutureSuccessDialog(
                future: _updateNickname(nickname, widget.memberId),
                onDataTrue: () {
                  _onUpdateNickname();
                },
                dataTrueText: 'nickname_scf',
              ),
          barrierDismissible: false,
          context: context);
    }
  }
}
