import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/save_preferences.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../essentials/widgets/currency_picker_dropdown.dart';
import '../main_group_page.dart';

class ChangeGroupCurrencyDialog extends StatefulWidget {
  @override
  _ChangeGroupCurrencyDialogState createState() => _ChangeGroupCurrencyDialogState();
}

class _ChangeGroupCurrencyDialogState extends State<ChangeGroupCurrencyDialog> {
  String? _currencyCode = currentGroupCurrency;

  Future<bool> _updateGroupCurrency(String? code) async {
    try {
      Map<String, dynamic> body = {"currency": code};

      await httpPut(uri: '/groups/' + currentGroupId.toString(), context: context, body: body);
      saveGroupCurrency(code);
      Future.delayed(delayTime()).then((value) => _onUpdateGroupCurrency());
      return true;
    } catch (_) {
      throw _;
    }
  }

  Future<void> _onUpdateGroupCurrency() async {
    await clearGroupCache();
    await deleteCache(uri: generateUri(GetUriKeys.groups));
    await deleteCache(uri: generateUri(GetUriKeys.userBalanceSum));
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (context) => MainPage()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'change_group_currency'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: CurrencyPickerDropdown(
                  defaultCurrencyValue: _currencyCode,
                  currencyChanged: (currency) {
                    _currencyCode = currency;
                  }),
            ),
            SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GradientButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    showDialog(
                        builder: (context) => FutureSuccessDialog(
                              future: _updateGroupCurrency(_currencyCode),
                              dataTrueText: 'currency_scf',
                              onDataTrue: () {
                                _onUpdateGroupCurrency();
                              },
                            ),
                        barrierDismissible: false,
                        context: context);
                  },
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
}
