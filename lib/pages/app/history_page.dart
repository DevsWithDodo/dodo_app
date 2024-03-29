import 'dart:convert';

import 'package:csocsort_szamla/components/history/history_filter.dart';
import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/components/helpers/ad_unit.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/components/payment/payment_entry.dart';
import 'package:csocsort_szamla/components/purchase/purchase_entry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class HistoryFilterDelegate extends SliverPersistentHeaderDelegate {
  final HistoryFilter child;

  HistoryFilterDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 250;

  @override
  double get minExtent => 250;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}

class HistoryPage extends StatefulWidget {
  ///Defines whether to show purchases (0) or payments (1)
  final int? startingIndex;
  final int? selectedMemberId;

  HistoryPage({
    this.startingIndex,
    this.selectedMemberId,
  });

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin {
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Category? _category;
  Future<Map<DateTime, List<Purchase>>>? _purchases;
  Future<Map<DateTime, List<Payment>>>? _payments;

  ScrollController _purchaseScrollController = ScrollController();
  ScrollController _paymentScrollController = ScrollController();
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
      throw _;
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
      throw _;
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
    double width = screenSize.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'history'.tr(),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onBackground),
        ),
      ),
      bottomNavigationBar: width > tabletViewWidth
          ? null
          : NavigationBar(
              backgroundColor: Theme.of(context).cardTheme.color,
              onDestinationSelected: (_index) {
                setState(() {
                  _selectedIndex = _index;
                  _tabController!.animateTo(_index);
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
            child: NestedScrollView(
              controller: controller,
              headerSliverBuilder: (context, _) => [
                SliverPersistentHeader(
                  delegate: HistoryFilterDelegate(
                    child: HistoryFilter(
                      isScrolled: _isScrolled,
                      selectedCategory: _category,
                      endDate: _endDate,
                      startDate: _startDate,
                      selectedMemberId: _selectedMemberId,
                      onValuesChanged: (newSelectedMemberId, newStartDate, newEndDate, newCategory) {
                        setState(() {
                          _selectedMemberId = newSelectedMemberId;
                          _startDate = newStartDate;
                          _endDate = newEndDate;
                          _category = newCategory;
                        });
                        _purchases = null;
                        _purchases = _getPurchases(overwriteCache: true);
                        _payments = null;
                        _payments = _getPayments(overwriteCache: true);
                      },
                    ),
                  ),
                ),
              ],
              body: screenSize.isMobile ? TabBarView(
                controller: _tabController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildPurchases(),
                  _buildPayments(),
                ],
              ) : Row(
                children: [
                  Expanded(
                    child: _buildPurchases(),
                  ),
                  Expanded(
                    child: _buildPayments(),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: MediaQuery.of(context).viewInsets.bottom == 0,
            child: AdUnit(site: 'history'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        onPressed: () {
          if (_selectedIndex == 0 && controller.hasClients) {
            controller.animateTo(
              0.0,
              curve: Curves.easeOut,
              duration: const Duration(milliseconds: 300),
            );
          } else if (_selectedIndex == 1 && controller.hasClients) {
            controller.animateTo(
              0.0,
              curve: Curves.easeOut,
              duration: const Duration(milliseconds: 300),
            );
          }
        },
        child: Icon(
          Icons.keyboard_arrow_up,
          color: Theme.of(context).colorScheme.onTertiary,
        ),
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
          child: CircularProgressIndicator(),
          heightFactor: 2,
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
          child: CircularProgressIndicator(),
          heightFactor: 2,
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
              DateFormat.yMMMd(context.locale.countryCode).format(startDate.subtract(Duration(days: 7))) +
                  ' - ' +
                  DateFormat.yMMMd(context.locale.countryCode).format(startDate.subtract(Duration(days: 1))),
              style:
                  Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onBackground),
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
    if (data.length == 0) {
      return [
        Padding(
          padding: EdgeInsets.all(25),
          child: Text(
            'nothing_to_show'.tr(),
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
              DateFormat.yMMMd(context.locale.languageCode).format(startDate.subtract(Duration(days: 7))) +
                  ' - ' +
                  DateFormat.yMMMd(context.locale.languageCode).format(startDate.subtract(Duration(days: 1))),
              style:
                  Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onBackground),
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
    if (data.length == 0) {
      return [
        Padding(
          padding: EdgeInsets.all(25),
          child: Text(
            'nothing_to_show'.tr(),
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onBackground),
            textAlign: TextAlign.center,
          ),
        )
      ];
    }

    return data.entries.map((e) => _generatePurchaseWeekWidget(e.key, e.value)).toList();
  }
}
