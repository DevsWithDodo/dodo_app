import 'package:csocsort_szamla/pages/app/statistics_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class StatisticsIntervalPicker extends StatelessWidget {
  const StatisticsIntervalPicker({
    super.key,
    required this.data,
    required this.onIntervalChanged,
  });

  final void Function(GroupingInterval) onIntervalChanged;
  final StatisticsData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: GroupingInterval.values
            .map(
              (interval) => Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onIntervalChanged(interval),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: data.groupingInterval == interval ? Theme.of(context).colorScheme.secondaryContainer : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text("statistics.${interval.name}".tr(), style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: data.groupingInterval == interval ? Theme.of(context).colorScheme.onSecondaryContainer : Theme.of(context).colorScheme.onSurface,
                    )),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
