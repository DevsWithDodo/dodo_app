import 'dart:convert';

import 'package:csocsort_szamla/components/helpers/ad_unit.dart';
import 'package:csocsort_szamla/components/helpers/currency_picker_dropdown.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_usage_provider.dart';
import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:csocsort_szamla/pages/app/main_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _groupName = TextEditingController();
  late TextEditingController _nicknameController;

  final _formKey = GlobalKey<FormState>();
  late Currency _selectedCurrency;

  @override
  void initState() {
    super.initState();
    User user = context.read<UserNotifier>().user!;
    _nicknameController = TextEditingController(); // TODO: initial value from cache
    _selectedCurrency = user.currency;
  }

  Future<BoolFutureOutput> _createGroup(String groupName, String nickname, String? currency) async {
    try {
      Map<String, dynamic> body = {'group_name': groupName, 'currency': currency, 'member_nickname': nickname};
      http.Response response = await Http.post(uri: '/groups', body: body);
      Map<String, dynamic> decoded = jsonDecode(response.body);
      UserNotifier userProvider = context.read<UserNotifier>();
      userProvider.setGroups(userProvider.user!.groups + [Group.fromJson(decoded)], notify: false);
      userProvider.setGroup(userProvider.user!.groups.last);
      context.read<UserUsageNotifier>().incrementGroupsUsedCount();
      return BoolFutureOutput.True;
    } catch (_) {
      rethrow;
    }
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
                                labelText: 'group_name'.tr(),
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
                                labelText: 'nickname-in-group'.tr(),
                                filled: true,
                                prefixIcon: Icon(
                                  Icons.account_circle,
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
                                  'create-group.currency'.tr(),
                                  style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Flexible(
                                  child: CurrencyPickerDropdown(
                                    currencyChanged: (code) => setState(() => _selectedCurrency = code),
                                    currency: _selectedCurrency,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('create-group.currency.hint'.tr(), style: Theme.of(context).textTheme.labelSmall),
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
                child: AdUnit(site: 'create_group'),
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
              showFutureOutputDialog(
                future: _createGroup(token, nickname, _selectedCurrency.code),
                context: context,
                outputCallbacks: {
                  BoolFutureOutput.True: () async {
                    EventBus.instance.fire(EventBus.refreshGroups);
                    EventBus.instance.fire(EventBus.refreshPayments);
                    EventBus.instance.fire(EventBus.refreshPurchases);
                    EventBus.instance.fire(EventBus.refreshShopping);
                    EventBus.instance.fire(EventBus.refreshStatistics);
                    EventBus.instance.fire(EventBus.refreshGroupInfo);
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => MainPage()),
                      (r) => false,
                    );
                  }
                },
              );
            }
          },
        ),
      ),
    );
  }
}
