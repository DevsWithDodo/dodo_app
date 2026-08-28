import 'package:csocsort_szamla/components/helpers/currency_picker_button.dart';
import 'package:csocsort_szamla/components/helpers/currency_picker_sheet.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/main_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class ChangeUserCurrencyDialog extends StatefulWidget {
  const ChangeUserCurrencyDialog({super.key});

  @override
  State<ChangeUserCurrencyDialog> createState() => _ChangeUserCurrencyDialogState();
}

class _ChangeUserCurrencyDialogState extends State<ChangeUserCurrencyDialog> {
  late Currency _currency;

  @override
  void initState() {
    super.initState();
    _currency = context.read<UserNotifier>().user!.currency;
  }

  Future<BoolFutureOutput> _updateUserCurrency(String currency) async {
    try {
      Map<String, dynamic> body = {"default_currency": currency};

      await Http.put(uri: '/user', body: body);
      if (mounted) context.read<UserNotifier>().setUserCurrency(currency);
      return BoolFutureOutput.True;
    } catch (_) {
      rethrow;
    }
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
              'change_user_currency'.tr(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 10,
            ),
            CurrencyPickerButton(
              selectedCurrency: _currency,
              onCurrencyChanged: (currency) => setState(() => _currency = currency),
              defaultCurrencyFrom: DefaultCurrencyFrom.user,
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
                    showFutureOutputDialog(context: context, future: _updateUserCurrency(_currency.code), outputCallbacks: {
                      BoolFutureOutput.True: () async {
                        EventBus.instance.fire(EventBus.refreshBalances);
                        EventBus.instance.fire(EventBus.refreshPurchases);
                        EventBus.instance.fire(EventBus.refreshPayments);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => MainPage()),
                          (r) => false,
                        );
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
