import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:csocsort_szamla/common.dart' as common;
import 'package:csocsort_szamla/components/helpers/category_picker_icon_button.dart';
import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/components/statistics/interval_picker.dart';
import 'package:csocsort_szamla/components/statistics/legend.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/date_time.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/navigator_service.dart';
import 'package:csocsort_szamla/helpers/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/main.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class StatisticsPage extends StatefulWidget {
  final DateTime? groupCreation;
  const StatisticsPage({super.key, this.groupCreation});
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late Future<PaymentStatisticsData> _paymentStats;
  late Future<PurchaseStatisticsData> _purchaseStats;
  late Future<GroupStatisticsData> _groupStats;

  DateTime? _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Category? _category = Category.fromType(null);

  void refreshStatistics() {
    _paymentStats = _getStats(StatisticsType.payments);
    _purchaseStats = _getStats(StatisticsType.purchases);
    _groupStats = _getStats(StatisticsType.group);
  }

  @override
  void initState() {
    super.initState();

    if (widget.groupCreation != null && _startDate!.isBefore(widget.groupCreation!)) {
      _startDate = widget.groupCreation;
    }
    refreshStatistics();
  }

  Future<T> _getStats<T extends StatisticsData>(StatisticsType type) async {
    try {
      String startDate = DateFormat('yyyy-MM-dd').format(_startDate!);
      String endDate = DateFormat('yyyy-MM-dd').format(_endDate);
      Response response = await Http.get(
          useCache: false,
          overwriteCache: true,
          uri: generateUri(
            type == StatisticsType.payments
                ? GetUriKeys.statisticsPayments
                : type == StatisticsType.purchases
                    ? GetUriKeys.statisticsPurchases
                    : GetUriKeys.statisticsAll,
            context,
            queryParams: {
              'from_date': startDate,
              'until_date': endDate,
              ...(_category != null ? {'category': _category?.text} : {}),
            },
          ));
      Map<String, dynamic> decoded = jsonDecode(response.body);

      if (type == StatisticsType.payments) {
        return PaymentStatisticsData.fromJson(decoded['data']) as T;
      } else if (type == StatisticsType.purchases) {
        return PurchaseStatisticsData.fromJson(decoded['data']) as T;
      } else {
        return GroupStatisticsData.fromJson(decoded['data']) as T;
      }
    } catch (_) {
      rethrow;
    }
  }

  BarTooltipItem? Function(BarChartGroupData, int, BarChartRodData, int) _purchasePaymentGetTooltipItem(PurchasePaymentStatisticsData data) => (BarChartGroupData group, int groupIndex, BarChartRodData rod, int rodIndex) {
        final entry = data.groupedEntries[groupIndex];
        double value = rodIndex == 0 ? entry.given : entry.received;
        Color color = rodIndex == 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.tertiary;
        if (value == 0) {
          return null;
        }
        return BarTooltipItem(
          value.toMoneyString(
            context.read<UserState>().currentGroup!.currency,
            withSymbol: true,
          ),
          Theme.of(context).textTheme.bodySmall!.copyWith(color: color),
        );
      };

  BarTooltipItem? Function(BarChartGroupData, int, BarChartRodData, int) _groupGetTooltipItem(GroupStatisticsData data) => (BarChartGroupData group, int groupIndex, BarChartRodData rod, int rodIndex) {
        final entry = data.groupedEntries[groupIndex];
        double value = rodIndex == 0 ? entry.purchases : entry.payments;
        Color color = rodIndex == 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.tertiary;
        if (value == 0) {
          return null;
        }
        return BarTooltipItem(
          value.toMoneyString(
            context.read<UserState>().currentGroup!.currency,
            withSymbol: true,
          ),
          Theme.of(context).textTheme.bodySmall!.copyWith(color: color),
        );
      };

  BarChartData _generateChartData(StatisticsData data) {
    if (kDebugMode) {
      debugPrint('generate chart data');
      debugPrint(data.groupedEntries.length.toString());
    }
    int minX = data.startDate.millisecondsSinceEpoch;
    int maxX = data.endDate.millisecondsSinceEpoch;
    double minY = data.minY;
    double maxY = data.maxY;
    double sideScale = 1;
    double difference = maxY - minY;
    if (maxY > 0) {
      sideScale = pow(10, (log(difference) / log(10)).floor() - 1).toDouble();
    }
    if (difference == 0) {
      maxY = 1;
      minY = -1;
      difference = 2;
    }

    maxY += maxY * 0.2;
    minY += minY * 0.2;

    double? sideInterval = ((difference / sideScale).round() + (3 - (difference / sideScale).round()) % 3).toDouble() * sideScale / 3;

    int bottomDivider;
    Duration bottomDuration = Duration(milliseconds: maxX - minX);
    if (bottomDuration.inDays > 30) {
      bottomDivider = 15;
    } else {
      bottomDivider = (bottomDuration.inDays / 3).round();
      if (bottomDivider < 1) {
        bottomDivider = 1;
      }
    }

    return BarChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: sideInterval,
      ),
      borderData: FlBorderData(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          direction: TooltipDirection.top,
          getTooltipColor: (group) => Theme.of(context).colorScheme.surfaceContainerHigh,
          tooltipRoundedRadius: 8,
          getTooltipItem: data.type == StatisticsType.group ? _groupGetTooltipItem(data as GroupStatisticsData) : _purchasePaymentGetTooltipItem(data as PurchasePaymentStatisticsData),
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: AxisTitles(),
        rightTitles: AxisTitles(),
        leftTitles: AxisTitles(
          axisNameSize: 22,
          axisNameWidget: Text(
            '${'amount'.tr()} (${context.watch<UserState>().currentGroup!.currency.symbol})',
          ),
          sideTitles: SideTitles(
            reservedSize: 50,
            interval: sideInterval,
            showTitles: true,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              axisSide: AxisSide.left,
              child: value == maxY || value == minY
                  ? Container()
                  : Text(
                      value.abs().toMoneyString(
                            context.watch<UserState>().currentGroup!.currency,
                          ),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: Duration(days: 10).inMilliseconds * 1.0,
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              final entry = data.groupedEntries.firstWhere((element) => element.dateRange.start == date);
              return SideTitleWidget(
                axisSide: AxisSide.bottom,
                child: Text(
                  data.groupingInterval.formattedDate(entry.start, entry.end),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              );
            },
          ),
        ),
      ),
      barGroups: data.groupedEntries
          .map(
            (entry) => BarChartGroupData(
              x: entry.start.millisecondsSinceEpoch,
              groupVertically: data.type != StatisticsType.group,
              barRods: [
                BarChartRodData(
                  width: 20,
                  fromY: data.type != StatisticsType.group ? (entry as GroupedPurchasePaymentStatisticsDataEntry).given : (entry as GroupedGroupStatisticsDataEntry).purchases,
                  toY: 0,
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
                BarChartRodData(
                  width: 20,
                  fromY: data.type != StatisticsType.group ? -(entry as GroupedPurchasePaymentStatisticsDataEntry).received : (entry as GroupedGroupStatisticsDataEntry).payments,
                  toY: 0,
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.vertical(
                    bottom: data.type != StatisticsType.group ? Radius.circular(2) : Radius.zero,
                    top: data.type == StatisticsType.group ? Radius.circular(2) : Radius.zero,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.watch<ScreenSize>().isMobile;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        title: Text(
          'statistics'.tr(),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(110),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 550),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${DateFormat.yMd(context.locale.languageCode).format(_startDate!)} - ${DateFormat.yMd(context.locale.languageCode).format(_endDate)}',
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.date_range, color: Theme.of(context).colorScheme.primary),
                          onPressed: () async {
                            DateTimeRange? range = await showDateRangePicker(
                                context: context,
                                firstDate: widget.groupCreation!,
                                lastDate: DateTime.now(),
                                currentDate: DateTime.now(),
                                initialDateRange: DateTimeRange(start: _startDate!, end: _endDate),
                                builder: (context, child) {
                                  return child!;
                                });
                            if (range != null) {
                              _startDate = range.start;
                              _endDate = range.end;
                              setState(refreshStatistics);
                            }
                          },
                        )
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'category'.tr(),
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        CategoryPickerIconButton(
                          selectedCategory: _category,
                          onCategoryChanged: (category) {
                            if (_category?.type == category?.type) {
                              _category = null;
                            } else {
                              _category = category;
                            }
                            setState(refreshStatistics);
                          },
                        )
                      ],
                    ),
                    SizedBox(height: 5),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: isMobile
          ? Container(
              color: Theme.of(context).colorScheme.surface,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: StatisticsType.values.mapIndexed((index, type) => childFromType(type, index == StatisticsType.values.length - 1)).toList(),
                  ),
                ),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    margin: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: StatisticsType.values.take(2).mapIndexed((index, type) => childFromType(type, index == 0)).toList(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    margin: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(15),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        childFromType(StatisticsType.group),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget childFromType(StatisticsType type, [bool showDivider = false]) {
    final screenSize = context.watch<ScreenSize>();
    return Column(
      children: [
        Text(
          'statistics.${type.name}'.tr(),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: 10,
        ),
        FutureBuilder(
          future: (type == StatisticsType.payments
              ? _paymentStats
              : type == StatisticsType.purchases
                  ? _purchaseStats
                  : _groupStats) as Future<StatisticsData>,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return CircularProgressIndicator();
            }
            if (!snapshot.hasData) {
              return ErrorMessage(
                error: snapshot.error.toString(),
                errorLocation: 'statistics',
                onTap: () => setState(() {
                  if (type == StatisticsType.payments) {
                    _paymentStats = _getStats(type);
                  } else if (type == StatisticsType.purchases) {
                    _purchaseStats = _getStats(type);
                  } else {
                    _groupStats = _getStats(type);
                  }
                }),
              );
            }
            if (snapshot.data!.isEmpty) {
              return Text(
                'statistics.no-data-for-period'.tr(),
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
            final calculatedWidth = snapshot.data!.groupedEntries.length * (type == StatisticsType.group ? 60.0 : 40.0);
            final availableWidth = screenSize.isMobile ? screenSize.width - 30 : (screenSize.width - 40) / 2 - 30;
            final physics = calculatedWidth > availableWidth ? BouncingScrollPhysics() : NeverScrollableScrollPhysics();
            return Column(
              children: [
                StatisticsIntervalPicker(
                  data: snapshot.data!,
                  onIntervalChanged: (interval) => setState(() {
                    snapshot.data!.groupingInterval = interval;
                  }),
                ),
                SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: physics,
                  child: SizedBox(
                    height: 250,
                    width: max(calculatedWidth, availableWidth),
                    child: BarChart(
                      _generateChartData(snapshot.data!),
                      swapAnimationCurve: Curves.easeInOutCubic,
                      swapAnimationDuration: Duration(milliseconds: 500),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Legend(
                    type: LegendFor.fromStatisticsType(type),
                    sums: type == StatisticsType.group
                        ? [
                            (snapshot.data! as GroupStatisticsData).sumPurchases,
                            (snapshot.data! as GroupStatisticsData).sumPayments,
                          ]
                        : [
                            (snapshot.data! as PurchasePaymentStatisticsData).sumGiven,
                            (snapshot.data! as PurchasePaymentStatisticsData).sumReceived,
                          ]),
              ],
            );
          },
        ),
        ...(showDivider
            ? [
                SizedBox(height: 10),
                Divider(),
                SizedBox(height: 10),
              ]
            : []),
      ],
    );
  }
}

enum StatisticsType { payments, purchases, group }

enum GroupingInterval {
  daily,
  weekly,
  monthly,
  yearly;

  static fromIntervalLength(int length) {
    if (length < 14) {
      return daily;
    }
    if (length < 60) {
      return weekly;
    }
    if (length < 730) {
      return monthly;
    }
    return yearly;
  }

  Duration get duration {
    switch (this) {
      case daily:
        return Duration(days: 0);
      case weekly:
        return Duration(days: 6);
      case monthly:
        return Duration(days: 29);
      case yearly:
        return Duration(days: 364);
    }
  }

  DateTime periodStart(DateTime date) {
    switch (this) {
      case daily:
        return date;
      case weekly:
        return date.firstDayOf(DayOfModifier.week);
      case monthly:
        return date.firstDayOf(DayOfModifier.month);
      case yearly:
        return date.firstDayOf(DayOfModifier.year);
    }
  }

  DateTime periodEnd(DateTime date) {
    DateTime end = date;
    switch (this) {
      case daily:
        end = date;
        break;
      case weekly:
        end = end.lastDayOf(DayOfModifier.week);
        break;
      case monthly:
        end = end.lastDayOf(DayOfModifier.month);
        break;
      case yearly:
        end = end.lastDayOf(DayOfModifier.year);
        break;
    }
    return end.endOfDay();
  }

  String formattedDate(DateTime start, DateTime end) {
    BuildContext context = getIt.get<NavigationService>().navigatorKey.currentContext!;
    switch (this) {
      case daily:
        return DateFormat.d(context.locale.languageCode).format(start);
      case weekly:
        return '${DateFormat.d(context.locale.languageCode).format(start)}-${DateFormat.d(context.locale.languageCode).format(end)}';
      case monthly:
        return DateFormat.MMM(context.locale.languageCode).format(start);
      case yearly:
        return DateFormat.y(context.locale.languageCode).format(start);
    }
  }
}

abstract class StatisticsDataEntry {
  final DateTime date;
  const StatisticsDataEntry(this.date);
}

class PurchasePaymentStatisticsDataEntry extends StatisticsDataEntry {
  final double given;
  final double received;
  const PurchasePaymentStatisticsDataEntry(
    super.date,
    this.given,
    this.received,
  );
}

abstract class GroupedStatisticsDataEntry {
  final DateTimeRange dateRange;
  const GroupedStatisticsDataEntry(this.dateRange);

  DateTime get start => dateRange.start;
  DateTime get end => dateRange.end;
}

class GroupedPurchasePaymentStatisticsDataEntry extends GroupedStatisticsDataEntry {
  final double given;
  final double received;

  GroupedPurchasePaymentStatisticsDataEntry(
    super.dateRange,
    this.given,
    this.received,
  );

  GroupedPurchasePaymentStatisticsDataEntry add(
    double given,
    double received,
  ) {
    return GroupedPurchasePaymentStatisticsDataEntry(
      dateRange,
      this.given + given,
      this.received + received,
    );
  }
}

class GroupedGroupStatisticsDataEntry extends GroupedStatisticsDataEntry {
  final double purchases;
  final double payments;

  GroupedGroupStatisticsDataEntry(
    super.dateRange,
    this.purchases,
    this.payments,
  );

  @override
  DateTime get start => dateRange.start;
  @override
  DateTime get end => dateRange.end;

  GroupedGroupStatisticsDataEntry add(
    double purchases,
    double payments,
  ) {
    return GroupedGroupStatisticsDataEntry(
      dateRange,
      this.purchases + purchases,
      this.payments + payments,
    );
  }
}

class GroupStatisticsDataEntry extends StatisticsDataEntry {
  final double purchases;
  final double payments;
  const GroupStatisticsDataEntry(super.date, this.purchases, this.payments);
}

abstract class StatisticsData<T extends StatisticsDataEntry, U extends GroupedStatisticsDataEntry> {
  GroupingInterval groupingInterval;
  final DateTime startDate;
  final DateTime endDate;
  final List<T> entries;
  final StatisticsType type;
  StatisticsData({
    required this.groupingInterval,
    required this.startDate,
    required this.endDate,
    required this.entries,
    required this.type,
  });

  List<U> get groupedEntries;
  double get maxY;
  double get minY;
  bool get isEmpty;
}

abstract class PurchasePaymentStatisticsData extends StatisticsData<PurchasePaymentStatisticsDataEntry, GroupedPurchasePaymentStatisticsDataEntry> {
  PurchasePaymentStatisticsData({
    required super.groupingInterval,
    required super.startDate,
    required super.endDate,
    required super.entries,
    required super.type,
  });

  double get sumGiven {
    return entries.fold<double>(0, (previousValue, element) {
      return previousValue + element.given;
    });
  }

  double get sumReceived {
    return entries.fold<double>(0, (previousValue, element) {
      return previousValue + element.received;
    });
  }

  @override
  get groupedEntries => entries.fold<List<GroupedPurchasePaymentStatisticsDataEntry>>([], (previousValue, element) {
        if (previousValue.isEmpty || previousValue.last.end.isBefore(element.date)) {
          return [
            ...previousValue,
            GroupedPurchasePaymentStatisticsDataEntry(
              DateTimeRange(
                start: common.maxDateTime(groupingInterval.periodStart(element.date), startDate),
                end: common.minDateTime(groupingInterval.periodEnd(element.date), endDate),
              ),
              element.given,
              element.received,
            )
          ];
        }
        return [...previousValue.sublist(0, previousValue.length - 1), previousValue.last.add(element.given, element.received)];
      }).toList();

  @override
  double get maxY => groupedEntries.fold<double>(0, (value, element) => max(value, element.given));

  @override
  double get minY => -groupedEntries.fold<double>(0, (value, element) => max(value, element.received));
  @override
  bool get isEmpty => sumGiven == 0 && sumReceived == 0;
}

class PaymentStatisticsData extends PurchasePaymentStatisticsData {
  PaymentStatisticsData._internal({
    required super.groupingInterval,
    required super.startDate,
    required super.endDate,
    required super.type,
    required super.entries,
  });

  factory PaymentStatisticsData(List<PurchasePaymentStatisticsDataEntry> entries, [GroupingInterval? interval]) {
    return PaymentStatisticsData._internal(
      groupingInterval: interval ?? GroupingInterval.fromIntervalLength(entries.length),
      startDate: entries[0].date,
      endDate: entries[entries.length - 1].date,
      type: StatisticsType.payments,
      entries: entries,
    );
  }

  factory PaymentStatisticsData.fromJson(Map<String, dynamic> data, [GroupingInterval? interval]) {
    return PaymentStatisticsData(
      (data['payed'] as Map<String, dynamic>).keys.map((dateString) {
        return PurchasePaymentStatisticsDataEntry(
          DateTime.parse(dateString),
          data['payed'][dateString] * 1.0,
          data['taken'][dateString] * 1.0,
        );
      }).toList(),
    );
  }
}

class PurchaseStatisticsData extends PurchasePaymentStatisticsData {
  PurchaseStatisticsData._internal({
    required super.groupingInterval,
    required super.startDate,
    required super.endDate,
    required super.type,
    required super.entries,
  });

  factory PurchaseStatisticsData(List<PurchasePaymentStatisticsDataEntry> entries) {
    return PurchaseStatisticsData._internal(
      groupingInterval: GroupingInterval.fromIntervalLength(entries.length),
      startDate: entries[0].date,
      endDate: entries[entries.length - 1].date,
      type: StatisticsType.purchases,
      entries: entries,
    );
  }

  factory PurchaseStatisticsData.fromJson(Map<String, dynamic> data) {
    return PurchaseStatisticsData(
      (data['bought'] as Map<String, dynamic>).keys.map((dateString) {
        return PurchasePaymentStatisticsDataEntry(
          DateTime.parse(dateString),
          data['bought'][dateString] * 1.0,
          data['received'][dateString] * 1.0,
        );
      }).toList(),
    );
  }
}

class GroupStatisticsData extends StatisticsData<GroupStatisticsDataEntry, GroupedGroupStatisticsDataEntry> {
  GroupStatisticsData._internal({
    required super.groupingInterval,
    required super.startDate,
    required super.endDate,
    required super.entries,
    required super.type,
  });

  double get sumPurchases {
    return entries.fold<double>(0, (previousValue, element) {
      return previousValue + element.purchases;
    });
  }

  double get sumPayments {
    return entries.fold<double>(0, (previousValue, element) {
      return previousValue + element.payments;
    });
  }

  @override
  bool get isEmpty => sumPurchases == 0 && sumPayments == 0;

  @override
  get groupedEntries {
    return entries.fold<List<GroupedGroupStatisticsDataEntry>>([], (previousValue, element) {
      if (previousValue.isEmpty || previousValue.last.end.isBefore(element.date)) {
        return [
          ...previousValue,
          GroupedGroupStatisticsDataEntry(
            DateTimeRange(
              start: common.maxDateTime(groupingInterval.periodStart(element.date), startDate),
              end: common.minDateTime(groupingInterval.periodEnd(element.date), endDate),
            ),
            element.purchases,
            element.payments,
          )
        ];
      }
      return [...previousValue.sublist(0, previousValue.length - 1), previousValue.last.add(element.purchases, element.payments)];
    }).toList();
  }

  @override
  double get maxY => groupedEntries.fold<double>(0, (value, element) {
        return max(value, max(element.purchases, element.payments));
      });

  @override
  double get minY => 0;

  factory GroupStatisticsData(List<GroupStatisticsDataEntry> entries) {
    return GroupStatisticsData._internal(
      type: StatisticsType.group,
      groupingInterval: GroupingInterval.fromIntervalLength(entries.length),
      startDate: entries[0].date,
      endDate: entries[entries.length - 1].date,
      entries: entries,
    );
  }

  factory GroupStatisticsData.fromJson(Map<String, dynamic> data) {
    return GroupStatisticsData(
      (data['purchases'] as Map<String, dynamic>).keys.map((dateString) {
        return GroupStatisticsDataEntry(
          DateTime.parse(dateString),
          data['purchases'][dateString] * 1.0,
          data['payments'][dateString] * 1.0,
        );
      }).toList(),
    );
  }
}
