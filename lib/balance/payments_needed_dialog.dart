import 'package:csocsort_szamla/balance/payment_needed_entry.dart';
import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class PaymentsNeededDialog extends StatefulWidget {
  final List<Payment> payments;

  const PaymentsNeededDialog({
    required this.payments,
    super.key,
  });

  @override
  State<PaymentsNeededDialog> createState() => _PaymentsNeededDialogState();
}

class _PaymentsNeededDialogState extends State<PaymentsNeededDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'payments_needed'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              'payments_needed_explanation'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(
              height: 15,
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _generatePaymentEntries(),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GradientButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('back'.tr()),
                ),
                GradientButton(
                  child: Icon(Icons.copy),
                  onPressed: () {
                    String currency =
                        context.read<AppStateProvider>().currentGroup!.currency;
                    int longestPayerNick = widget.payments
                        .map((e) => e.payerNickname.length)
                        .reduce((value, element) =>
                            value > element ? value : element);
                    int longestTakerNick = widget.payments
                        .map((e) => e.takerNickname.length)
                        .reduce((value, element) =>
                            value > element ? value : element);
                    Clipboard.setData(ClipboardData(
                      text: widget.payments.map((payment) {
                        String firstSpaces = ' ' *
                            (longestPayerNick - payment.payerNickname.length);
                        String secondSpaces = ' ' *
                            (longestTakerNick - payment.takerNickname.length);
                        return "${payment.payerNickname}${firstSpaces}\t➡️\t${payment.takerNickname}:${secondSpaces}\t${payment.amount.toMoneyString(currency, withSymbol: true)}";
                      }).join('\n'),
                    ));
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _generatePaymentEntries() {
    Map<int, List<Payment>> paymentsByPayer = {};
    for (Payment payment in widget.payments) {
      if (paymentsByPayer.containsKey(payment.payerId)) {
        paymentsByPayer[payment.payerId]!.add(payment);
      } else {
        paymentsByPayer[payment.payerId] = [payment];
      }
    }
    List<Widget> paymentEntries = <Widget>[];
    for (int payerId in paymentsByPayer.keys) {
      paymentEntries.add(
        PaymentsNeededEntry(
          payments: paymentsByPayer[payerId]!,
        ),
      );
    }
    return paymentEntries;
  }
}
