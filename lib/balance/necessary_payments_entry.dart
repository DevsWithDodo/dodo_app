import 'package:collection/collection.dart';
import 'package:csocsort_szamla/balance/payment_methods_dialog.dart';
import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NecessaryPaymentsEntry extends StatelessWidget {
  /// The list of payments grouped by the payer.
  final List<Payment> payments;
  final List<Member> takers;
  const NecessaryPaymentsEntry(
      {required this.payments, required this.takers, super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AppStateProvider, User>(
        selector: (_, provider) => provider.user!,
        builder: (context, user, _) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: payments[0].payerId == user.id
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Theme.of(context).colorScheme.surfaceVariant,
              ),
              child: Table(
                columnWidths: {
                  0: FlexColumnWidth(1),
                  1: FractionColumnWidth(0.1),
                  2: FlexColumnWidth(1),
                  3: FractionColumnWidth(0.1),
                },
                children: payments
                    .mapIndexed(
                      (index, payment) => TableRow(
                        children: [
                          Visibility(
                            visible: index == 0,
                            child: Text(
                              payment.payerNickname,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          Visibility(
                            visible: index == 0,
                            child: Icon(
                              Icons.arrow_right_alt,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                payment.takerNickname,
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                payment.amount.toMoneyString(
                                  context
                                      .read<AppStateProvider>()
                                      .currentGroup!
                                      .currency,
                                  withSymbol: true,
                                ),
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Visibility(
                                visible: payments.length > 1 &&
                                    index != payments.length - 1,
                                child: SizedBox(height: 8),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return PaymentMethodsDialog(
                                      member: takers.firstWhere((element) =>
                                          element.id == payment.takerId),
                                    );
                                  });
                            },
                            icon: Icon(Icons.search),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        });
  }
}
