import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/components/balance/necessary_payment_entry.dart';
import 'package:csocsort_szamla/components/helpers/background_paint.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_usage_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class NecessaryPaymentsPage extends StatefulWidget {
  const NecessaryPaymentsPage({
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        title: Text('payments_needed'.tr()),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'payments-needed.page.subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                    IconButton.outlined(
                      icon: Icon(Icons.copy, size: 20),
                      onPressed: () => _copyToClipboard(context),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text("payments-needed.page.payment-method-hint".tr(),
                    style: context.textTheme.bodySmall, textAlign: TextAlign.center)
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: BackgroundPaint(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      child: Column(
                        children: _generatePaymentEntries(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Currency currency = context.read<UserNotifier>().currentGroup!.currency;
    int longestPayerNick = widget.necessaryPayments.map((e) => e.payerNickname.length).reduce(
          (value, element) => value > element ? value : element,
        );
    int longestTakerNick = widget.necessaryPayments.map((e) => e.takerNickname.length).reduce(
          (value, element) => value > element ? value : element,
        );
    String paymentsPart = widget.necessaryPayments.map(
      (payment) {
        String firstSpaces = ' ' * (longestPayerNick - payment.payerNickname.length);
        String secondSpaces = ' ' * (longestTakerNick - payment.takerNickname.length);
        return "${payment.payerNickname}$firstSpaces\t➡️\t${payment.takerNickname}:$secondSpaces\t${payment.amount.toMoneyString(
          currency,
          withSymbol: true,
        )}";
      },
    ).join('\n');
    String paymentMethodsPart = "";
    List<Member> membersToCopy = widget.members
        .where(
          (element) =>
              element.paymentMethods != null &&
              element.paymentMethods!.isNotEmpty &&
              widget.necessaryPayments.any((payment) => payment.takerId == element.id),
        )
        .toList();
    if (membersToCopy.any((element) => element.paymentMethods != null && element.paymentMethods!.isNotEmpty)) {
      paymentMethodsPart = "\n\n${'payment-methods.title'.tr()}\n${membersToCopy.map(
            (member) {
              return member.paymentMethods!.isEmpty
                  ? null
                  // ignore: prefer_interpolation_to_compose_strings
                  : "${member.nickname}: \n" +
                      member.paymentMethods!
                          .map(
                            (method) => "  ${method.name}: ${method.value} ${method.priority ? "(⭐)" : ""}",
                          )
                          .join('\n');
            },
          ).where((e) => e != null).join('\n')}";
    }
    Clipboard.setData(
      ClipboardData(
        text: paymentsPart + paymentMethodsPart,
      ),
    );
    showToast('clipboard.copy-successful'.tr());
    context.read<UserUsageNotifier>().setCopiedSettleUpFlag(true);
  }

  List<Widget> _generatePaymentEntries() {
    Map<int, List<Payment>> paymentsByPayer = {};
    for (Payment payment
        in widget.necessaryPayments.where((payment) => payment.amount > payment.originalCurrency.threshold())) {
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
