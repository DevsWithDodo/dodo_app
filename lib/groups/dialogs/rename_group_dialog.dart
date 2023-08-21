import 'dart:convert';

import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../essentials/http.dart';
import '../../essentials/validation_rules.dart';
import '../../essentials/widgets/future_success_dialog.dart';
import '../../essentials/widgets/gradient_button.dart';

class RenameGroupDialog extends StatefulWidget {
  @override
  _RenameGroupDialogState createState() => _RenameGroupDialogState();
}

class _RenameGroupDialogState extends State<RenameGroupDialog> {
  var _groupNameFormKey = GlobalKey<FormState>();
  var _groupNameController = TextEditingController();

  Future<BoolFutureOutput> _updateGroupName(String groupName) async {
    try {
      Map<String, dynamic> body = {"name": groupName};

      http.Response response = await Http.put(
        uri: '/groups/' +
            context.read<AppStateProvider>().currentGroup!.id.toString(),
        body: body,
      );

      Map<String, dynamic> decoded = jsonDecode(response.body);
      context.read<AppStateProvider>().setGroupName(decoded['group_name']);
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
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
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
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

  void _buttonPush() {
    if (_groupNameFormKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      String groupName = _groupNameController.text;
      showFutureOutputDialog(
        context: context,
        future: _updateGroupName(groupName),
        outputCallbacks: {
          BoolFutureOutput.True: () async {
            _groupNameController.text = '';
            await clearGroupCache(context);
            await deleteCache(uri: generateUri(GetUriKeys.groups, context)); // TODO: event bus?
            Navigator.of(context).pop();
          }
        }
      );
    }
  }
}
