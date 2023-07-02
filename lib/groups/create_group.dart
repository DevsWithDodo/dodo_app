import 'dart:convert';

import 'package:csocsort_szamla/essentials/ad_management.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/currency_picker_dropdown.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../essentials/validation_rules.dart';
import 'main_group_page.dart';

class CreateGroup extends StatefulWidget {
  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  TextEditingController _groupName = TextEditingController();
  late TextEditingController _nicknameController;

  var _formKey = GlobalKey<FormState>();
  String? _defaultCurrencyValue;

  @override
  void initState() {
    super.initState();
    User user = context.read<AppStateProvider>().user!;
    _nicknameController = TextEditingController(
      text: user.username[0].toUpperCase() + user.username.substring(1));
    _defaultCurrencyValue = user.currency;
  }

  Future<bool> _createGroup(
      String groupName, String nickname, String? currency) async {
    try {
      Map<String, dynamic> body = {
        'group_name': groupName,
        'currency': currency,
        'member_nickname': nickname
      };
      http.Response response =
          await Http.post(uri: '/groups', body: body);
      Map<String, dynamic> decoded = jsonDecode(response.body);
      AppStateProvider userProvider = context.read<AppStateProvider>();
      userProvider.setGroups(userProvider.user!.groups + [
        Group(
          id: decoded['group_id'],
          name: decoded['group_name'],
          currency: decoded['currency'],
        )
      ], notify: false);
      userProvider.setGroup(userProvider.user!.groups.last);
      Future.delayed(delayTime()).then((value) => _onCreateGroup());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onCreateGroup() async {
    await clearAllCache();
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => MainPage()), (r) => false);
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
                child: Align(
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 500,
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              validator: (value) => validateTextField([
                                isEmpty(value),
                                minimalLength(value!.trim(), 1),
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: MediaQuery.of(context).viewInsets.bottom == 0,
                child: AdUnitForSite(site: 'create_group'),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            Icons.send,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
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
      ),
    );
  }
}
