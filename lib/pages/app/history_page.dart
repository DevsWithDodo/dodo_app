import 'dart:convert';

import 'package:csocsort_szamla/components/helpers/ad_unit.dart';
import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/components/history/history_filter.dart';
import 'package:csocsort_szamla/components/payment/payment_entry.dart';
import 'package:csocsort_szamla/components/purchase/purchase_entry.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatefulWidget {
  ///Defines whether to show purchases (0) or payments (1)
  final int? startingIndex;
  final int? selectedMemberId;

  const HistoryPage({
    super.key,
    this.startingIndex,
    this.selectedMemberId,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin {
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Category? _category;
  Future<Map<DateTime, List<Purchase>>>? _purchases;
  Future<Map<DateTime, List<Payment>>>? _payments;

  final ScrollController _purchaseScrollController = ScrollController();
  final ScrollController _paymentScrollController = ScrollController();
  TabController? _tabController;
  late int _selectedIndex;
  late int _selectedMemberId;

  Future<Map<DateTime, List<Purchase>>> _getPurchases({bool overwriteCache = false}) async {
    try {
      Response response = await Http.get(
        uri: generateUri(
          GetUriKeys.purchases,
          context,
          queryParams: {
            'group': context.read<UserState>().currentGroup!.id.toString(),
            'from_date': DateFormat('yyyy-MM-dd').format(_startDate),
            'until_date': DateFormat('yyyy-MM-dd').format(_endDate),
            'user_id': _selectedMemberId.toString(),
            ...(_category == null ? {} : {'category': _category!.text})
          },
        ),
        overwriteCache: overwriteCache,
      );
      List<dynamic> decoded = jsonDecode(response.body)['data'];
      List<Purchase> purchaseData = decoded.map((data) => Purchase.fromJson(data)).toList();
      // Group by week starting from now
      Map<DateTime, List<Purchase>> grouped = {};
      DateTime now = DateTime.now();
      DateTime date = DateTime(now.year, now.month, now.day);
      for (Purchase purchase in purchaseData) {
        if (date.difference(purchase.updatedAt).inDays > 7) {
          int toSubtract = (date.difference(purchase.updatedAt).inDays / 7).floor();
          date = date.subtract(Duration(days: toSubtract * 7));
          grouped[date] = [];
          grouped[date]!.add(purchase);
        } else {
          if (!grouped.containsKey(date)) {
            grouped[date] = [purchase];
          } else {
            grouped[date]!.add(purchase);
          }
        }
      }
      return grouped;
    } catch (_) {
      rethrow;
    }
  }

  Future<Map<DateTime, List<Payment>>> _getPayments({bool overwriteCache = false}) async {
    try {
      Response response = await Http.get(
        uri: generateUri(
          GetUriKeys.payments,
          context,
          queryParams: {
            'group': context.read<UserState>().currentGroup!.id.toString(),
            'from_date': DateFormat('yyyy-MM-dd').format(_startDate),
            'until_date': DateFormat('yyyy-MM-dd').format(_endDate),
            'user_id': _selectedMemberId.toString(),
            ...(_category == null ? {} : {'category': _category!.text}),
          },
        ),
        overwriteCache: overwriteCache,
      );

      List<dynamic> decoded = jsonDecode(response.body)['data'];
      List<Payment> paymentData = decoded.map((data) => Payment.fromJson(data)).toList();

      // Group by week starting from now
      Map<DateTime, List<Payment>> grouped = {};
      DateTime now = DateTime.now();
      DateTime date = DateTime(now.year, now.month, now.day);
      for (Payment payment in paymentData) {
        if (date.difference(payment.updatedAt).inDays > 7) {
          int toSubtract = (date.difference(payment.updatedAt).inDays / 7).floor();
          date = date.subtract(Duration(days: toSubtract * 7));
          grouped[date] = [];
          grouped[date]!.add(payment);
        } else {
          if (!grouped.containsKey(date)) {
            grouped[date] = [payment];
          } else {
            grouped[date]!.add(payment);
          }
        }
      }
      return grouped;
    } catch (_) {
      rethrow;
    }
  }

  void onRefreshPurchasesEvent() {
    setState(() {
      _purchases = null;
      _purchases = _getPurchases(overwriteCache: true);
    });
  }

  void onRefreshPaymentsEvent() {
    setState(() {
      _payments = null;
      _payments = _getPayments(overwriteCache: true);
    });
  }

  late final ScrollController controller;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _selectedMemberId = widget.selectedMemberId ?? context.read<UserState>().user!.id;
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.startingIndex ?? 0);
    _selectedIndex = widget.startingIndex ?? 0;

    _purchases = null;
    _purchases = _getPurchases();

    _payments = null;
    _payments = _getPayments();

    final bus = EventBus.instance;
    bus.register(EventBus.refreshPurchases, onRefreshPurchasesEvent);
    bus.register(EventBus.refreshPayments, onRefreshPaymentsEvent);

    controller = ScrollController();
    controller.addListener(() {
      if ((!_isScrolled && controller.offset > 0) || (_isScrolled && controller.offset <= 0)) {
        setState(() => _isScrolled = !_isScrolled);
      }
    });
  }

  @override
  void dispose() {
    _tabController!.dispose();
    _purchaseScrollController.dispose();
    _paymentScrollController.dispose();
    final bus = EventBus.instance;
    bus.unregister(EventBus.refreshPurchases, onRefreshPurchasesEvent);
    bus.unregister(EventBus.refreshPayments, onRefreshPaymentsEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize screenSize = context.watch<ScreenSize>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        title: Text('history'.tr()),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(180),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: HistoryFilter(
                  selectedCategory: _category,
                  endDate: _endDate,
                  startDate: _startDate,
                  selectedMemberId: _selectedMemberId,
                  onValuesChanged: ({category, startDate, endDate, selectedMemberId, removeCategory}) {
                    setState(() {
                      _selectedMemberId = selectedMemberId ?? _selectedMemberId;
                      _startDate = startDate ?? _startDate;
                      _endDate = endDate ?? _endDate;
                      _category = (removeCategory ?? false) ? null : category ?? _category;
                    });
                    _purchases = null;
                    _purchases = _getPurchases(overwriteCache: true);
                    _payments = null;
                    _payments = _getPayments(overwriteCache: true);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: !screenSize.isMobile
          ? null
          : NavigationBar(
              backgroundColor: Theme.of(context).cardTheme.color,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                  _tabController!.animateTo(index);
                });
              },
              selectedIndex: _selectedIndex,
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.shopping_cart),
                  label: 'purchases'.tr(),
                ),
                NavigationDestination(icon: Icon(Icons.attach_money), label: 'payments'.tr())
              ],
            ),
      body: Column(
        children: [
          Expanded(
            child: screenSize.isMobile
                ? Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: TabBarView(
                      controller: _tabController,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        _buildPurchases(),
                        _buildPayments(),
                      ],
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                            margin: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: _buildPurchases()),
                      ),
                      Expanded(
                        child: Container(
                            margin: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: _buildPayments()),
                      ),
                    ],
                  ),
          ),
          Visibility(
            visible: MediaQuery.of(context).viewInsets.bottom == 0,
            child: AdUnit(site: 'history'),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchases() {
    return FutureBuilder(
      key: ValueKey('purchases'),
      future: _purchases,
      builder: (context, AsyncSnapshot<Map<DateTime, List<Purchase>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return SingleChildScrollView(
              child: Column(
                children: _generatePurchases(snapshot.data!),
              ),
            );
          } else {
            return ErrorMessage(
              error: snapshot.error.toString(),
              errorLocation: 'purchase_history_page',
              onTap: () {
                setState(() {
                  _purchases = null;
                  _purchases = _getPurchases();
                });
              },
            );
          }
        }
        return Center(
          heightFactor: 2,
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _buildPayments() {
    return FutureBuilder(
      key: ValueKey('payments'),
      future: _payments,
      builder: (context, AsyncSnapshot<Map<DateTime, List<Payment>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return SingleChildScrollView(
              child: Column(
                children: _generatePayments(snapshot.data!),
              ),
            );
          } else {
            return ErrorMessage(
              error: snapshot.error.toString(),
              errorLocation: 'payment_history_page',
              onTap: () {
                setState(() {
                  _payments = null;
                  _payments = _getPayments();
                });
              },
            );
          }
        }
        return Center(
          heightFactor: 2,
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _generatePaymentWeekWidget(DateTime startDate, List<Payment> payments) {
    return Column(
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.all(8),
            child: Text(
              '${DateFormat.yMMMd(context.locale.countryCode).format(startDate.subtract(Duration(days: 7)))} - ${DateFormat.yMMMd(context.locale.countryCode).format(startDate.subtract(Duration(days: 1)))}',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
              children: payments
                  .map((e) => PaymentEntry(
                        payment: e,
                        selectedMemberId: _selectedMemberId,
                      ))
                  .toList()),
        ),
      ],
    );
  }

  List<Widget> _generatePayments(Map<DateTime, List<Payment>> data) {
    if (data.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.all(25),
          child: Text(
            'statistics.no-data-for-period'.tr(),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        )
      ];
    }
    return data.entries.map((e) => _generatePaymentWeekWidget(e.key, e.value)).toList();
  }

  Widget _generatePurchaseWeekWidget(DateTime startDate, List<Purchase> purchases) {
    return Column(
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.all(8),
            child: Text(
              '${DateFormat.yMMMd(context.locale.languageCode).format(startDate.subtract(Duration(days: 7)))} - ${DateFormat.yMMMd(context.locale.languageCode).format(startDate.subtract(Duration(days: 1)))}',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
              children: purchases
                  .map((purchase) => PurchaseEntry(
                        purchase: purchase,
                        selectedMemberId: _selectedMemberId,
                      ))
                  .toList()),
        ),
      ],
    );
  }

  List<Widget> _generatePurchases(Map<DateTime, List<Purchase>> data) {
    if (data.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.all(25),
          child: Text(
            'statistics.no-data-for-period'.tr(),
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        )
      ];
    }

    return data.entries.map((e) => _generatePurchaseWeekWidget(e.key, e.value)).toList();
  }
}
