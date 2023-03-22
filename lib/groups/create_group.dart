import 'dart:convert';

import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/ad_management.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/save_preferences.dart';
import 'package:csocsort_szamla/essentials/widgets/currency_picker_dropdown.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../essentials/validation_rules.dart';
import 'main_group_page.dart';

class CreateGroup extends StatefulWidget {
  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  TextEditingController _groupName = TextEditingController();
  TextEditingController _nicknameController =
      TextEditingController(text: currentUsername[0].toUpperCase() + currentUsername.substring(1));

  var _formKey = GlobalKey<FormState>();
  String _defaultCurrencyValue = currentUserCurrency;

  Future<bool> _createGroup(String groupName, String nickname, String currency) async {
    try {
      Map<String, dynamic> body = {
        'group_name': groupName,
        'currency': currency,
        'member_nickname': nickname
      };
      http.Response response = await httpPost(uri: '/groups', body: body, context: context);
      Map<String, dynamic> decoded = jsonDecode(response.body);
      saveGroupName(decoded['group_name']);
      saveGroupId(decoded['group_id']);
      saveGroupCurrency(decoded['currency']);
      if (usersGroups == null) {
        usersGroups = <String>[];
        usersGroupIds = <int>[];
      }
      usersGroups.add(decoded['group_name']);
      usersGroupIds.add(decoded['group_id']);
      Future.delayed(delayTime()).then((value) => _onCreateGroup());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onCreateGroup() async {
    await clearAllCache();
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (context) => MainPage()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'create'.tr(),
          ),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(top: 5),
                  children: <Widget>[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: [
                            TextFormField(
                              validator: (value) => validateTextField([
                                isEmpty(value),
                                minimalLength(value.trim(), 1),
                              ]),
                              decoration: InputDecoration(
                                hintText: 'group_name'.tr(),
                                prefixIcon: Icon(
                                  Icons.group,
                                ),
                              ),
                              controller: _groupName,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(20),
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            TextFormField(
                              validator: (value) => validateTextField([
                                isEmpty(value),
                                minimalLength(value, 1),
                              ]),
                              decoration: InputDecoration(
                                hintText: 'nickname_in_group'.tr(),
                                labelText: 'nickname_in_group'.tr(),
                                filled: true,
                                prefixIcon: Icon(
                                  Icons.account_circle,
                                ),
                                border: UnderlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              controller: _nicknameController,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(15),
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Row(
                              children: <Widget>[
                                Text(
                                  'currency_of_group'.tr(),
                                  style: Theme.of(context).textTheme.labelLarge.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Flexible(
                                  child: CurrencyPickerDropdown(
                                    currencyChanged: (newValue) {
                                      setState(() {
                                        _defaultCurrencyValue = newValue;
                                      });
                                    },
                                    defaultCurrencyValue: _defaultCurrencyValue,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GradientButton(
                                  child: Text('create_group'.tr(),
                                      style: Theme.of(context).textTheme.labelLarge.copyWith(
                                          color: Theme.of(context).colorScheme.onPrimary)),
                                  onPressed: () {
                                    if (_formKey.currentState.validate()) {
                                      String token = _groupName.text;
                                      String nickname = _nicknameController.text;
                                      showDialog(
                                          builder: (context) => FutureSuccessDialog(
                                                future: _createGroup(
                                                    token, nickname, _defaultCurrencyValue),
                                                onDataTrue: () {
                                                  _onCreateGroup();
                                                },
                                                dataTrueText: 'creation_scf',
                                              ),
                                          barrierDismissible: false,
                                          context: context);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: MediaQuery.of(context).viewInsets.bottom == 0,
                child: AdUnitForSite(site: 'create_group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
