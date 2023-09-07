import 'package:csocsort_szamla/balance/necessary_payment_entry.dart';
import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class NecessaryPaymentsDialog extends StatelessWidget {
  final List<Payment> necessaryPayments;
  final List<Member> members;

  const NecessaryPaymentsDialog({
    required this.necessaryPayments,
    required this.members,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'payments_needed'.tr(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                'payments_needed.dialog.subtitle'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(height: 15),
              Text(
                'payments_needed.dialog.hint'.tr(),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 5),
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
              GradientButton(
                child: Icon(Icons.copy),
                onPressed: () {
                  String currency = context.read<AppStateProvider>().currentGroup!.currency;
                  int longestPayerNick = this.necessaryPayments
                      .map((e) => e.payerNickname.length)
                      .reduce((value, element) => value > element ? value : element);
                  int longestTakerNick = this.necessaryPayments
                      .map((e) => e.takerNickname.length)
                      .reduce((value, element) => value > element ? value : element);
                  Clipboard.setData(ClipboardData(
                    text: this.necessaryPayments.map((payment) {
                      String firstSpaces = ' ' * (longestPayerNick - payment.payerNickname.length);
                      String secondSpaces = ' ' * (longestTakerNick - payment.takerNickname.length);
                      return "${payment.payerNickname}${firstSpaces}\t➡️\t${payment.takerNickname}:${secondSpaces}\t${payment.amount.toMoneyString(currency, withSymbol: true)}";
                    }).join('\n'),
                  ));
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _generatePaymentEntries() {
    Map<int, List<Payment>> paymentsByPayer = {};
    for (Payment payment
        in this.necessaryPayments.where((payment) => payment.amount > Currency.threshold(payment.originalCurrency))) {
      if (paymentsByPayer.containsKey(payment.payerId)) {
        paymentsByPayer[payment.payerId]!.add(payment);
      } else {
        paymentsByPayer[payment.payerId] = [payment];
      }
    }
    List<Widget> paymentEntries = <Widget>[];
    for (int payerId in paymentsByPayer.keys) {
      paymentEntries.add(
        NecessaryPaymentEntry(
          payments: paymentsByPayer[payerId]!,
          takers: members
              .where((element) => paymentsByPayer[payerId]!.any((payment) => payment.takerId == element.id))
              .toList(),
        ),
      );
    }
    return paymentEntries;
  }
}
