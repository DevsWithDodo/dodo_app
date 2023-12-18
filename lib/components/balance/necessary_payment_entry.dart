import 'package:csocsort_szamla/components/balance/payment_methods_dialog.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NecessaryPaymentEntry extends StatelessWidget {
  /// The list of payments grouped by the payer.
  final List<Payment> payments;
  final List<Member> takers;
  const NecessaryPaymentEntry({required this.payments, required this.takers, super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<UserState, User>(
        selector: (_, provider) => provider.user!,
        builder: (context, user, _) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: payments[0].payerId == user.id
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Theme.of(context).colorScheme.surfaceVariant,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              payments.first.payerNickname,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                        SizedBox(width: 5),
                        Center(
                          child: Icon(
                            Icons.arrow_right_alt,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                        SizedBox(width: 5),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: payments
                          .map(
                            (payment) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      payment.takerNickname,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      payment.amount.toMoneyString(
                                        context.read<UserState>().currentGroup!.currency,
                                        withSymbol: true,
                                      ),
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return PaymentMethodsDialog(
                                          member: takers.firstWhere((element) => element.id == payment.takerId),
                                        );
                                      },
                                    );
                                  },
                                  child: Icon(Icons.payment),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }
}
