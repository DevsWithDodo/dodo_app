import 'package:csocsort_szamla/balance/necessary_payments_entry.dart';
import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/payments_needed.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class NecessaryPaymentsDialog extends StatefulWidget {
  final List<Member> members;

  const NecessaryPaymentsDialog({
    required this.members,
    super.key,
  });

  @override
  State<NecessaryPaymentsDialog> createState() => _NecessaryPaymentsDialogState();
}

class _NecessaryPaymentsDialogState extends State<NecessaryPaymentsDialog> {
  late List<Payment> _payments;

  @override
  void initState() {
    super.initState();
    _payments = necessaryPayments(widget.members, context);
  }
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
                    int longestPayerNick = _payments
                        .map((e) => e.payerNickname.length)
                        .reduce((value, element) =>
                            value > element ? value : element);
                    int longestTakerNick = _payments
                        .map((e) => e.takerNickname.length)
                        .reduce((value, element) =>
                            value > element ? value : element);
                    Clipboard.setData(ClipboardData(
                      text: _payments.map((payment) {
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
    for (Payment payment in _payments) {
      if (paymentsByPayer.containsKey(payment.payerId)) {
        paymentsByPayer[payment.payerId]!.add(payment);
      } else {
        paymentsByPayer[payment.payerId] = [payment];
      }
    }
    List<Widget> paymentEntries = <Widget>[];
    for (int payerId in paymentsByPayer.keys) {
      paymentEntries.add(
        NecessaryPaymentsEntry(
          payments: paymentsByPayer[payerId]!,
          takers: widget.members.where((element) => paymentsByPayer[payerId]!.any((payment) => payment.takerId == element.id)).toList(),
        ),
      );
    }
    return paymentEntries;
  }
}
