import 'dart:convert';

import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/ad_management.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/providers/EventBusProvider.dart';
import 'package:csocsort_szamla/essentials/widgets/error_message.dart';
import 'package:csocsort_szamla/payment/payment_entry.dart';
import 'package:csocsort_szamla/purchase/purchase_entry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../essentials/models.dart';
import 'history_filter.dart';

class AllHistoryRoute extends StatefulWidget {
  ///Defines whether to show purchases (0) or payments (1)
  final int? startingIndex;

  AllHistoryRoute({required this.startingIndex});

  @override
  _AllHistoryRouteState createState() => _AllHistoryRouteState();
}

class _AllHistoryRouteState extends State<AllHistoryRoute>
    with TickerProviderStateMixin {
  DateTime? _startDate;
  DateTime? _endDate;
  Category? _category;
  Future<Map<DateTime, List<Purchase>>>? _purchases;
  Future<Map<DateTime, List<Payment>>>? _payments;

  ScrollController _purchaseScrollController = ScrollController();
  ScrollController _paymentScrollController = ScrollController();
  TabController? _tabController;
  int? _selectedIndex = 0;
  bool _showFilter = false;
  int _selectedMemberId = currentUserId!;

  Future<Map<DateTime, List<Purchase>>> _getPurchases(
      {bool overwriteCache = false}) async {
    try {
      http.Response response = await httpGet(
        uri: generateUri(
          GetUriKeys.purchases,
          queryParams: {
            'group': currentGroupId.toString(),
            'from_date': _startDate == null
                ? null
                : DateFormat('yyyy-MM-dd').format(_startDate!),
            'until_date': _endDate == null
                ? null
                : DateFormat('yyyy-MM-dd').format(_endDate!),
            'user_id': _selectedMemberId.toString(),
            ...(_category == null ? {} : {'category': _category!.text})
          },
        ),
        context: context,
        overwriteCache: overwriteCache,
      );
      List<dynamic> decoded = jsonDecode(response.body)['data'];
      List<Purchase> purchaseData =
          decoded.map((data) => Purchase.fromJson(data)).toList();
      // Group by week starting from now
      Map<DateTime, List<Purchase>> grouped = {};
      DateTime now = DateTime.now();
      DateTime date = DateTime(now.year, now.month, now.day);
      for (Purchase purchase in purchaseData) {
        if (date.difference(purchase.updatedAt).inDays > 7) {
          int toSubtract =
              (date.difference(purchase.updatedAt).inDays / 7).floor();
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

  Future<Map<DateTime, List<Payment>>> _getPayments(
      {bool overwriteCache = false}) async {
    try {
      http.Response response;
      response = await httpGet(
        uri: generateUri(
          GetUriKeys.payments,
          queryParams: {
            'group': currentGroupId.toString(),
            'from_date': _startDate == null
                ? null
                : DateFormat('yyyy-MM-dd').format(_startDate!),
            'until_date': _endDate == null
                ? null
                : DateFormat('yyyy-MM-dd').format(_endDate!),
            'user_id': _selectedMemberId.toString(),
            ...(_category == null ? {} : {'category': _category!.text}),
          },
        ),
        context: context,
        overwriteCache: overwriteCache,
      );

      List<dynamic> decoded = jsonDecode(response.body)['data'];
      List<Payment> paymentData =
          decoded.map((data) => Payment.fromJson(data)).toList();

      // Group by week starting from now
      Map<DateTime, List<Payment>> grouped = {};
      DateTime now = DateTime.now();
      DateTime date = DateTime(now.year, now.month, now.day);
      for (Payment payment in paymentData) {
        if (date.difference(payment.updatedAt).inDays > 7) {
          int toSubtract =
              (date.difference(payment.updatedAt).inDays / 7).floor();
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

  @override
  void initState() {
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.startingIndex!);
    _selectedIndex = widget.startingIndex;

    _purchases = null;
    _purchases = _getPurchases();

    _payments = null;
    _payments = _getPayments();

    final bus = context.read<EventBusProvider>().eventBus;
    bus.on<RefreshPurchases>().listen((_) {
      if (mounted) {
        setState(() {
          _purchases = null;
          _purchases = _getPurchases(overwriteCache: true);
        });
      }
    });
    bus.on<RefreshPayments>().listen((_) {
      if (mounted) {
        setState(() {
          _payments = null;
          _payments = _getPayments(overwriteCache: true);
        });
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        56; //Height without status bar and appbar
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'history'.tr(),
          style: Theme.of(context)
              .textTheme
              .titleLarge!
              .copyWith(color: Theme.of(context).colorScheme.onBackground),
        ),
        actions: [
          IconButton(
            icon:
                Icon(_showFilter ? Icons.arrow_drop_up : Icons.filter_list_alt),
            onPressed: () {
              setState(() {
                _showFilter = !_showFilter;
              });
            },
          )
        ],
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
              selectedIndex: _selectedIndex!,
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.shopping_cart),
                  label: 'purchases'.tr(),
                ),
                NavigationDestination(
                    icon: Icon(Icons.attach_money), label: 'payments'.tr())
              ],
            ),
      body: Column(
        children: [
          AnimatedCrossFade(
            duration: Duration(milliseconds: 250),
            crossFadeState: _showFilter
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Container(),
            secondChild: Visibility(
                visible: _showFilter,
                child: HistoryFilter(
                  selectedCategory: _category,
                  endDate: _endDate,
                  startDate: _startDate,
                  selectedMember: _selectedMemberId,
                  onValuesChanged: (Member newMemberChosen,
                      DateTime? newStartDate,
                      DateTime? newEndDate,
                      Category? newCategory) {
                    setState(() {
                      _selectedMemberId = newMemberChosen.id;
                      _startDate = newStartDate;
                      _endDate = newEndDate;
                      _category = newCategory;
                      _showFilter = false;
                    });
                    _purchases = null;
                    _purchases = _getPurchases(overwriteCache: true);
                    _payments = null;
                    _payments = _getPayments(overwriteCache: true);
                  },
                )),
          ),
          width < tabletViewWidth
              ? Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: NeverScrollableScrollPhysics(),
                    children: _purchasePayment(),
                  ),
                )
              : Expanded(
                  child: Table(
                    columnWidths: {
                      0: FractionColumnWidth(0.5),
                      1: FractionColumnWidth(0.5),
                    },
                    children: [
                      TableRow(
                          children: _purchasePayment()
                              .map(
                                (e) => AspectRatio(
                                  aspectRatio: width / 2 / height,
                                  child: e,
                                ),
                              )
                              .toList())
                    ],
                  ),
                ),
          Visibility(
            visible: MediaQuery.of(context).viewInsets.bottom == 0,
            child: AdUnitForSite(site: 'history'),
          ),
        ],
      ),
      floatingActionButton: Visibility(
        visible: width < tabletViewWidth,
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          onPressed: () {
            if (_selectedIndex == 0 && _purchaseScrollController.hasClients) {
              _purchaseScrollController.animateTo(
                0.0,
                curve: Curves.easeOut,
                duration: const Duration(milliseconds: 300),
              );
            } else if (_selectedIndex == 1 &&
                _paymentScrollController.hasClients) {
              _paymentScrollController.animateTo(
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
      ),
    );
  }

  List<Widget> _purchasePayment() {
    return [
      FutureBuilder(
        future: _purchases,
        builder:
            (context, AsyncSnapshot<Map<DateTime, List<Purchase>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return SingleChildScrollView(
                controller: _purchaseScrollController,
                key: PageStorageKey('purchaseList'),
                child: Column(
                  children: _generatePurchase(snapshot.data!),
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
      ),
      FutureBuilder(
        future: _payments,
        builder:
            (context, AsyncSnapshot<Map<DateTime, List<Payment>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return SingleChildScrollView(
                controller: _paymentScrollController,
                key: PageStorageKey('paymentList'),
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
      ),
    ];
  }

  Widget _generatePaymentWeekWidget(
      DateTime startDate, List<Payment> payments) {
    return Column(
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.all(8),
            child: Text(
              DateFormat('yyyy/MM/dd')
                      .format(startDate.subtract(Duration(days: 7))) +
                  ' - ' +
                  DateFormat('yyyy/MM/dd')
                      .format(startDate.subtract(Duration(days: 1))),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Theme.of(context).colorScheme.onBackground),
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
    return data.entries
        .map((e) => _generatePaymentWeekWidget(e.key, e.value))
        .toList();
  }

  Widget _generatePurchaseWeekWidget(
      DateTime startDate, List<Purchase> purchases) {
    return Column(
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.all(8),
            child: Text(
              DateFormat('yyyy/MM/dd')
                      .format(startDate.subtract(Duration(days: 7))) +
                  ' - ' +
                  DateFormat('yyyy/MM/dd')
                      .format(startDate.subtract(Duration(days: 1))),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Theme.of(context).colorScheme.onBackground),
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

  List<Widget> _generatePurchase(Map<DateTime, List<Purchase>> data) {
    if (data.length == 0) {
      return [
        Padding(
          padding: EdgeInsets.all(25),
          child: Text(
            'nothing_to_show'.tr(),
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: Theme.of(context).colorScheme.onBackground),
            textAlign: TextAlign.center,
          ),
        )
      ];
    }

    return data.entries
        .map((e) => _generatePurchaseWeekWidget(e.key, e.value))
        .toList();
  }
}
