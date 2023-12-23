import 'package:csocsort_szamla/components/balance/necessary_payment_entry.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/payment_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class NecessaryPaymentsPage extends StatefulWidget {
  NecessaryPaymentsPage({
    required this.necessaryPayments,
    required this.members,
    super.key,
  });

  final List<Payment> necessaryPayments;
  final List<Member> members;

  @override
  State<NecessaryPaymentsPage> createState() => _NecessaryPaymentsPageState();
}

class _NecessaryPaymentsPageState extends State<NecessaryPaymentsPage> {
  void onRefreshBalancesEvent() {
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    EventBus.instance.register(
      EventBus.refreshBalances,
      onRefreshBalancesEvent,
    );
  }

  @override
  void dispose() {
    EventBus.instance.unregister(
      EventBus.refreshBalances,
      onRefreshBalancesEvent,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('payments_needed'.tr()),
      ),
      body: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'payments-needed.page.subtitle'.tr(),
                textAlign: TextAlign.center,
                style:
                    Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(height: 15),
              Text(
                'payments-needed.page.payment-method-hint'.tr(),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 5),
              Expanded(
                child: Container(
                  padding: EdgeInsets.fromLTRB(5, 8, 5, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: ElevationOverlay.applyOverlay(
                      context,
                      Theme.of(context).colorScheme.surface,
                      2,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _generatePaymentEntries(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text('payments-needed.page.copy-hint'.tr())),
                  GradientButton(
                    child: Icon(Icons.copy),
                    onPressed: () {
                      Currency currency = context.read<UserState>().currentGroup!.currency;
                      int longestPayerNick = this
                          .widget.necessaryPayments
                          .map((e) => e.payerNickname.length)
                          .reduce((value, element) => value > element ? value : element);
                      int longestTakerNick = this
                          .widget.necessaryPayments
                          .map((e) => e.takerNickname.length)
                          .reduce((value, element) => value > element ? value : element);
                      Clipboard.setData(
                        ClipboardData(
                          text: this.widget.necessaryPayments.map((payment) {
                            String firstSpaces = ' ' * (longestPayerNick - payment.payerNickname.length);
                            String secondSpaces = ' ' * (longestTakerNick - payment.takerNickname.length);
                            return "${payment.payerNickname}${firstSpaces}\t➡️\t${payment.takerNickname}:${secondSpaces}\t${payment.amount.toMoneyString(currency, withSymbol: true)}";
                          }).join('\n'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('payments-needed.page.payment-page-hint'.tr()),
                  GradientButton(
                    child: Icon(Icons.payments),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _generatePaymentEntries() {
    Map<int, List<Payment>> paymentsByPayer = {};
    for (Payment payment
        in this.widget.necessaryPayments.where((payment) => payment.amount > payment.originalCurrency.threshold())) {
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
          takers: widget.members
              .where((element) => paymentsByPayer[payerId]!.any((payment) => payment.takerId == element.id))
              .toList(),
        ),
      );
    }
    return paymentEntries;
  }
}
