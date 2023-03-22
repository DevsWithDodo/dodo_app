import 'dart:convert';

import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/ad_management.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/widgets/error_message.dart';
import 'package:csocsort_szamla/payment/payment_entry.dart';
import 'package:csocsort_szamla/purchase/purchase_entry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../essentials/models.dart';
import 'history_filter.dart';

class AllHistoryRoute extends StatefulWidget {
  ///Defines whether to show purchases (0) or payments (1)
  final int startingIndex;

  AllHistoryRoute({@required this.startingIndex});

  @override
  _AllHistoryRouteState createState() => _AllHistoryRouteState();
}

class _AllHistoryRouteState extends State<AllHistoryRoute> with TickerProviderStateMixin {
  DateTime _startDate;
  DateTime _endDate;
  Category _category;
  Future<List<Purchase>> _purchases;
  Future<List<Payment>> _payments;

  ScrollController _purchaseScrollController = ScrollController();
  ScrollController _paymentScrollController = ScrollController();
  TabController _tabController;
  int _selectedIndex = 0;
  bool _showFilter = false;
  int _selectedMemberId = currentUserId;

  Future<List<Purchase>> _getPurchases({bool overwriteCache = false}) async {
    try {
      http.Response response;
      response = await httpGet(
        uri: generateUri(GetUriKeys.purchases, queryParams: {
          'from_date': _startDate == null ? null : DateFormat('yyyy-MM-dd').format(_startDate),
          'until_date': _endDate == null ? null : DateFormat('yyyy-MM-dd').format(_endDate),
          'user_id': _selectedMemberId.toString(),
          ...(_category == null ? {} : {'category': _category.text})
        }),
        context: context,
        overwriteCache: overwriteCache,
      );
      List<dynamic> decoded = jsonDecode(response.body)['data'];
      List<Purchase> purchaseData = [];
      for (var data in decoded) {
        purchaseData.add(Purchase.fromJson(data));
      }
      return purchaseData;
    } catch (_) {
      throw _;
    }
  }

  Future<List<Payment>> _getPayments({bool overwriteCache = false}) async {
    try {
      http.Response response;
      response = await httpGet(
        uri: generateUri(GetUriKeys.payments, queryParams: {
          'from_date': _startDate == null ? null : DateFormat('yyyy-MM-dd').format(_startDate),
          'until_date': _endDate == null ? null : DateFormat('yyyy-MM-dd').format(_endDate),
          'user_id': _selectedMemberId.toString(),
          ...(_category == null ? {} : {'category': _category.text})
        }),
        context: context,
        overwriteCache: overwriteCache,
      );

      List<dynamic> decoded = jsonDecode(response.body)['data'];
      List<Payment> paymentData = [];
      for (var data in decoded) {
        paymentData.add(Payment.fromJson(data));
      }
      return paymentData;
    } catch (_) {
      throw _;
    }
  }

  void callback({bool purchase = false, bool payment = false}) {
    //TODO: rename
    if (!purchase && !payment) {
      clearGroupCache();
      setState(() {
        _payments = null;
        _payments = _getPayments(overwriteCache: true);
        _purchases = null;
        _purchases = _getPurchases(overwriteCache: true);
      });
      return;
    }
    setState(() {
      if (payment) {
        deleteCache(uri: generateUri(GetUriKeys.payments));
        deleteCache(
            uri: 'payments?group=$currentGroupId&from_date', multipleArgs: true); //payments date
        _payments = null;
        _payments = _getPayments(overwriteCache: true);
      }
      if (purchase) {
        deleteCache(uri: generateUri(GetUriKeys.purchases));
        deleteCache(
            uri: 'purchases?group=$currentGroupId&from_date', multipleArgs: true); //purchases date
        _purchases = null;
        _purchases = _getPurchases(overwriteCache: true);
      }
      deleteCache(uri: generateUri(GetUriKeys.groupCurrent)); //Balances
      deleteCache(uri: generateUri(GetUriKeys.userBalanceSum));
    });
  }

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.startingIndex);
    _selectedIndex = widget.startingIndex;

    _purchases = null;
    _purchases = _getPurchases();

    _payments = null;
    _payments = _getPayments();
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
              .titleLarge
              .copyWith(color: Theme.of(context).colorScheme.onBackground),
        ),
        actions: [
          IconButton(
            icon: Icon(_showFilter ? Icons.arrow_drop_up : Icons.filter_list_alt),
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
                  _tabController.animateTo(_index);
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
          AnimatedCrossFade(
            duration: Duration(milliseconds: 250),
            crossFadeState: _showFilter ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Container(),
            secondChild: Visibility(
                visible: _showFilter,
                child: HistoryFilter(
                  selectedCategory: _category,
                  endDate: _endDate,
                  startDate: _startDate,
                  selectedMember: _selectedMemberId,
                  onValuesChanged: (Member newMemberChosen, DateTime newStartDate,
                      DateTime newEndDate, Category newCategory) {
                    setState(() {
                      _selectedMemberId = newMemberChosen.memberId;
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
            } else if (_selectedIndex == 1 && _paymentScrollController.hasClients) {
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
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return ListView(
                  controller: _purchaseScrollController,
                  key: PageStorageKey('purchaseList'),
                  shrinkWrap: true,
                  children: _generatePurchase(snapshot.data));
            } else {
              return ErrorMessage(
                error: snapshot.error.toString(),
                locationOfError: 'purchase_history_page',
                callback: () {
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
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return ListView(
                  controller: _paymentScrollController,
                  key: PageStorageKey('paymentList'),
                  shrinkWrap: true,
                  children: _generatePayments(snapshot.data));
            } else {
              return ErrorMessage(
                error: snapshot.error.toString(),
                locationOfError: 'payment_history_page',
                callback: () {
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

  List<Widget> _generatePayments(List<Payment> data) {
    print(data.length);
    if (data.length == 0) {
      return [
        Padding(
          padding: EdgeInsets.all(25),
          child: Text(
            'nothing_to_show'.tr(),
            style: Theme.of(context).textTheme.bodyText1,
            textAlign: TextAlign.center,
          ),
        )
      ];
    }
    Function callback = this.callback;
    DateTime nowNow = DateTime.now();
    //Initial
    DateTime now = DateTime(nowNow.year, nowNow.month, nowNow.day);
    Widget initial;
    if (now.difference(data[0].updatedAt).inDays > 7) {
      int toSubtract = (now.difference(data[0].updatedAt).inDays / 7).floor();
      now = now.subtract(Duration(days: toSubtract * 7));
      initial = Column(
        children: [
          Container(
              padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Text(
                DateFormat('yyyy/MM/dd').format(now.subtract(Duration(days: 7))) +
                    ' - ' +
                    DateFormat('yyyy/MM/dd').format(now.subtract(Duration(days: 1))),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    .copyWith(color: Theme.of(context).colorScheme.onBackground),
              )),
        ],
      );
    } else {
      initial = Center(
        child: Container(
            padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: Text(
              DateFormat('yyyy/MM/dd').format(now.subtract(Duration(days: 7))) +
                  ' - ' +
                  DateFormat('yyyy/MM/dd').format(now.subtract(Duration(days: 1))),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  .copyWith(color: Theme.of(context).colorScheme.onBackground),
            )),
      );
    }
    List<Widget> allEntries = [initial];
    List<PaymentEntry> weekEntries = [];
    for (Payment data in data) {
      if (now.difference(data.updatedAt).inDays > 7) {
        int toSubtract = (now.difference(data.updatedAt).inDays / 7).floor();
        now = now.subtract(Duration(days: toSubtract * 7));
        allEntries.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: weekEntries,
          ),
        ));
        weekEntries = [];
        weekEntries.add(PaymentEntry(
          data: data,
          callback: callback,
          selectedMemberId: _selectedMemberId,
        ));
        allEntries.add(Center(
          child: Container(
            padding: EdgeInsets.all(8),
            child: Text(
              DateFormat('yyyy/MM/dd').format(now.subtract(Duration(days: 7))) +
                  ' - ' +
                  DateFormat('yyyy/MM/dd').format(now.subtract(Duration(days: 1))),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  .copyWith(color: Theme.of(context).colorScheme.onBackground),
            ),
          ),
        ));
      } else {
        weekEntries.add(PaymentEntry(
          data: data,
          callback: callback,
          selectedMemberId: _selectedMemberId,
        ));
      }
    }
    if (weekEntries.isNotEmpty) {
      allEntries.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: weekEntries,
        ),
      ));
    }
    return allEntries;
  }

  List<Widget> _generatePurchase(List<Purchase> data) {
    if (data.length == 0) {
      return [
        Padding(
          padding: EdgeInsets.all(25),
          child: Text(
            'nothing_to_show'.tr(),
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                .copyWith(color: Theme.of(context).colorScheme.onBackground),
            textAlign: TextAlign.center,
          ),
        )
      ];
    }
    Function callback = this.callback;
    DateTime nowNow = DateTime.now();
    DateTime now = DateTime(nowNow.year, nowNow.month, nowNow.day);
    Widget initial;
    if (now.difference(data[0].updatedAt).inDays > 7) {
      int toSubtract = (now.difference(data[0].updatedAt).inDays / 7).floor();
      now = now.subtract(Duration(days: toSubtract * 7));
      initial = Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: Text(
              DateFormat('yyyy/MM/dd').format(now.subtract(Duration(days: 7))) +
                  ' - ' +
                  DateFormat('yyyy/MM/dd').format(now.subtract(Duration(days: 1))),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  .copyWith(color: Theme.of(context).colorScheme.onBackground),
            ),
          ),
        ],
      );
    } else {
      initial = Center(
        child: Container(
            padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: Text(
              DateFormat('yyyy/MM/dd').format(now.subtract(Duration(days: 7))) +
                  ' - ' +
                  DateFormat('yyyy/MM/dd').format(now.subtract(Duration(days: 1))),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  .copyWith(color: Theme.of(context).colorScheme.onBackground),
            )),
      );
    }
    List<Widget> allEntries = [initial];
    List<PurchaseEntry> weekEntries = [];
    for (Purchase data in data) {
      if (now.difference(data.updatedAt).inDays > 7) {
        int toSubtract = (now.difference(data.updatedAt).inDays / 7).floor();
        now = now.subtract(Duration(days: toSubtract * 7));
        allEntries.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: weekEntries,
          ),
        ));
        weekEntries = [];
        allEntries.add(Center(
          child: Container(
            padding: EdgeInsets.all(8),
            child: Text(
              DateFormat('yyyy/MM/dd').format(now.subtract(Duration(days: 7))) +
                  ' - ' +
                  DateFormat('yyyy/MM/dd').format(now.subtract(Duration(days: 1))),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  .copyWith(color: Theme.of(context).colorScheme.onBackground),
            ),
          ),
        ));
        weekEntries.add(PurchaseEntry(
          purchase: data,
          callback: callback,
          selectedMemberId: _selectedMemberId,
        ));
      } else {
        weekEntries.add(PurchaseEntry(
          purchase: data,
          callback: callback,
          selectedMemberId: _selectedMemberId,
        ));
      }
    }
    if (weekEntries.isNotEmpty) {
      allEntries.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: weekEntries,
        ),
      ));
    }
    return allEntries;
  }
}
