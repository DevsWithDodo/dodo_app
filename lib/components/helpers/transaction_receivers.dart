import 'package:collection/collection.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum TransactionType { payment, purchase }

class TransactionReceivers extends StatelessWidget {
  const TransactionReceivers({
    super.key,
    required this.type,
    required this.buyerNickname,
    required this.groupedReceivers,
    required this.displayCurrency,
  });

  final Map<double, List<Member>> groupedReceivers;
  final Currency displayCurrency;
  final String buyerNickname;
  final TransactionType type;

  TableRow gapRow(double gap) {
    return TableRow(
      children: [SizedBox(height: gap), SizedBox(height: gap), SizedBox(height: gap), SizedBox(height: gap)],
    );
  }

  @override
  Widget build(BuildContext context) {
    Currency groupCurrency = context.select<UserState, Currency>((provider) => provider.currentGroup!.currency);
    TextStyle titleStyle = Theme.of(context).textTheme.titleMedium!.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    String type = this.type == TransactionType.purchase ? 'purchase' : 'payment';
    String buyer = this.type == TransactionType.purchase ? 'buyer' : 'payer';
    String receiver = this.type == TransactionType.purchase ? 'receivers' : 'receiver';
    String per = this.type == TransactionType.purchase ? 'per' : 'amount';
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: {
          0: FlexColumnWidth(2),
          1: FixedColumnWidth(30),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            children: [
              Center(
                child: Text(
                  '$type-info.table.$buyer'.tr(),
                  style: titleStyle,
                ),
              ),
              SizedBox(),
              Center(
                child: Text(
                  '$type-info.table.$receiver'.tr(),
                  style: titleStyle,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      '$type-info.table.$per'.tr(),
                      style: titleStyle,
                    ),
                  ),
                  Visibility(
                    visible: this.type == TransactionType.purchase,
                    child: Icon(
                      Icons.person,
                      size: 18,
                    ),
                  ),
                ],
              )
            ],
          ),
          gapRow(10),
          ...groupedReceivers.keys
              .mapIndexed((index, amount) {
                Member receiver = groupedReceivers[amount]!.first;
                String amountString =
                    (displayCurrency == groupCurrency ? receiver.balance : receiver.balanceOriginalCurrency)
                        .toMoneyString(
                  displayCurrency,
                  withSymbol: true,
                );
                double gap = index == groupedReceivers.length - 1 ? 0 : 7;
                return [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                        child: Center(child: Text(buyerNickname)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Icon(Icons.arrow_right_alt_rounded),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: groupedReceivers[amount]!
                                    .map(
                                      (receiver) => Flexible(
                                        child: Text(
                                          receiver.nickname,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                          child: Text(amountString),
                        ),
                      ),
                    ],
                  ),
                  gapRow(gap),
                ];
              })
              .flattened
              ,
        ],
      ),
    );
  }
}
