import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/components/helpers/currency_picker_dropdown.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChangeGroupCurrencyDialog extends StatefulWidget {
  @override
  _ChangeGroupCurrencyDialogState createState() => _ChangeGroupCurrencyDialogState();
}

class _ChangeGroupCurrencyDialogState extends State<ChangeGroupCurrencyDialog> {
  late Currency _currency;

  Future<BoolFutureOutput> _updateGroupCurrency(Currency currency) async {
    try {
      Map<String, dynamic> body = {"currency": currency.code};

      await Http.put(
        uri: '/groups/' + context.read<UserState>().currentGroup!.id.toString(),
        body: body,
      );
      context.read<UserState>().setGroupCurrency(currency);

      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }

  @override
  void initState() {
    super.initState();
    _currency = context.read<UserState>().currentGroup!.currency;
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
                currency: _currency,
                currencyChanged: (currency) => setState(() => _currency = currency),
              ),
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
                    showFutureOutputDialog(context: context, future: _updateGroupCurrency(_currency), outputCallbacks: {
                      BoolFutureOutput.True: () async {
                        await clearGroupCache(context);
                        EventBus.instance.fire(EventBus.refreshBalances);
                        Navigator.of(context).pop();
                      }
                    });
                  },
                  child: Icon(Icons.check),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
