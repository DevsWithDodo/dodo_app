import 'dart:convert';

import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/save_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../essentials/http_handler.dart';
import '../../essentials/validation_rules.dart';
import '../../essentials/widgets/future_success_dialog.dart';
import '../../essentials/widgets/gradient_button.dart';
import '../main_group_page.dart';

class RenameGroupDialog extends StatefulWidget {
  @override
  _RenameGroupDialogState createState() => _RenameGroupDialogState();
}

class _RenameGroupDialogState extends State<RenameGroupDialog> {
  var _groupNameFormKey = GlobalKey<FormState>();
  var _groupNameController = TextEditingController();

  Future<bool> _updateGroupName(String groupName) async {
    try {
      Map<String, dynamic> body = {"name": groupName};

      http.Response response =
          await httpPut(uri: '/groups/' + currentGroupId.toString(), context: context, body: body);

      Map<String, dynamic> decoded = jsonDecode(response.body);
      saveGroupName(decoded['group_name']);
      Future.delayed(delayTime()).then((value) => _onUpdateGroupName());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onUpdateGroupName() {
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (context) => MainPage()), (r) => false);
    _groupNameController.text = '';
    clearGroupCache();
    deleteCache(uri: generateUri(GetUriKeys.groups));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _groupNameFormKey,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'rename_group'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    hintText: 'new_name'.tr(),
                    prefixIcon: Icon(
                      Icons.group,
                    ),
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(20),
                  ],
                  onFieldSubmitted: (value) => _buttonPush(),
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
      ),
    );
  }

  void _buttonPush() {
    if (_groupNameFormKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      String groupName = _groupNameController.text;
      showDialog(
          builder: (context) => FutureSuccessDialog(
                future: _updateGroupName(groupName),
                dataTrueText: 'nickname_scf',
                onDataTrue: () {
                  _onUpdateGroupName();
                },
              ),
          barrierDismissible: false,
          context: context);
    }
  }
}
