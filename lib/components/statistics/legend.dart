import 'package:collection/collection.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/statistics_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum LegendFor {
  purchase("statistics.legend.purchases"),
  payment("statistics.legend.payments"),
  group("statistics.legend.group");

  final String translationKey;

  const LegendFor(this.translationKey);

  static List<String> entries = [
    "first",
    "second",
  ];

  static fromStatisticsType(StatisticsType type) {
    switch (type) {
      case StatisticsType.purchases:
        return LegendFor.purchase;
      case StatisticsType.payments:
        return LegendFor.payment;
      case StatisticsType.group:
        return LegendFor.group;
    }
  }
}

class Legend extends StatelessWidget {
  const Legend({required this.type, required this.sums, super.key});

  final LegendFor type;
  final List<double> sums;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...LegendFor.entries.mapIndexed(
          (index, entry) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                    color: index == 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(50)),
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                "${type.translationKey}.${entry}".tr(),
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            ],
          ),
        ),
        SizedBox(
          height: 10,
        ),
        ...LegendFor.entries.mapIndexed((index, entry) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'statistics.legend.sum-of'.tr() + ' ',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                          color: index == 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(15)),
                    ),
                  ],
                ),
                Flexible(
                  child: Text(
                    sums[index].toMoneyString(
                        context.watch<UserState>().currentGroup!.currency,
                        withSymbol: true),
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                )
              ],
            ))
      ],
    );
  }
}
