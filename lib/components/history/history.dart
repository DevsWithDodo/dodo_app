import 'dart:convert';

import 'package:csocsort_szamla/components/payment/payment_entry.dart';
import 'package:csocsort_szamla/components/purchase/purchase_entry.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/history_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../helpers/models.dart';
import '../helpers/error_message.dart';
import '../helpers/gradient_button.dart';

class History extends StatefulWidget {
  final int? selectedIndex;
  History({this.selectedIndex});

  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  Future<List<Payment>>? _payments;
  Future<List<Purchase>>? _purchases;
  late int _selectedIndex;
  Future<List<Purchase>> _getPurchases({bool overwriteCache = false}) async {
    try {
      Response response = await Http.get(
        uri: generateUri(
          GetUriKeys.purchases,
          context,
          queryParams: {
            'limit': '6',
            'group': context.read<UserState>().currentGroup!.id.toString(),
          },
        ),
        overwriteCache: overwriteCache,
      );

      List<dynamic> decoded = jsonDecode(response.body)['data'];
      // print(decoded);
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
      Response response = await Http.get(
        uri: generateUri(
          GetUriKeys.payments,
          context,
          queryParams: {
            'limit': '6',
            'group': context.read<UserState>().currentGroup!.id.toString(),
          },
        ),
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

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex ?? 0;
    _payments = null;
    _payments = _getPayments();
    _purchases = null;
    _purchases = _getPurchases();

    final bus = EventBus.instance;
    bus.register(EventBus.refreshPurchases, onRefreshPurchasesEvent);
    bus.register(EventBus.refreshPayments, onRefreshPaymentsEvent);
  }

  @override
  void dispose() {
    final bus = EventBus.instance;
    bus.unregister(EventBus.refreshPurchases, onRefreshPurchasesEvent);
    bus.unregister(EventBus.refreshPayments, onRefreshPaymentsEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: <Widget>[
            Text(
              'history'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              'history_explanation'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 20,
            ),
            SegmentedButton<int>(
              emptySelectionAllowed: false,
              multiSelectionEnabled: false,
              selectedIcon: _selectedIndex == 0
                  ? Icon(Icons.shopping_cart)
                  : Icon(Icons.payment),
              segments: [
                ButtonSegment(
                  value: 0,
                  label: Text('purchases'.tr()),
                  enabled: true,
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('payments'.tr()),
                  enabled: true,
                ),
              ],
              selected: new Set()..add(_selectedIndex),
              onSelectionChanged: (Set<dynamic> selected) {
                _selectedIndex = selected.first;
                setState(() {});
              },
            ),
            AnimatedCrossFade(
              crossFadeState: _selectedIndex == 0
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: Duration(milliseconds: 100),
              firstChild: FutureBuilder(
                future: _purchases,
                builder: (context, AsyncSnapshot<List<Purchase>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      return Column(
                        children: <Widget>[
                          SizedBox(height: 10),
                          if (snapshot.data!.length == 0)
                            Padding(
                              padding: EdgeInsets.all(25),
                              child: Text(
                                'nothing_to_show'.tr(),
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ..._generatePurchases(snapshot.data!),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: GradientButton.icon(
                              useSecondary: true,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HistoryPage(
                                        startingIndex: _selectedIndex),
                                  ),
                                );
                              },
                              icon: Icon(Icons.list),
                              label: Text('history.show-all'.tr()),
                            ),
                          )
                        ],
                      );
                    } else {
                      return ErrorMessage(
                        error: snapshot.error.toString(),
                        errorLocation: 'purchase_history',
                        onTap: () {
                          setState(() {
                            _purchases = null;
                            _purchases = _getPurchases();
                          });
                        },
                      );
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.all(80),
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
              secondChild: FutureBuilder(
                future: _payments,
                builder: (context, AsyncSnapshot<List<Payment>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      return Column(
                        children: <Widget>[
                          SizedBox(
                            height: 10,
                          ),
                          if (snapshot.data!.length == 0)
                            Padding(
                              padding: EdgeInsets.all(25),
                              child: Text(
                                'nothing_to_show'.tr(),
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ..._generatePayments(snapshot.data!),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: GradientButton.icon(
                              useSecondary: true,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HistoryPage(
                                      startingIndex: _selectedIndex,
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(Icons.list),
                              label: Text('history.show-all'.tr()),
                            ),
                          )
                        ],
                      );
                    } else {
                      return ErrorMessage(
                        error: snapshot.error.toString(),
                        errorLocation: 'payment_history',
                        onTap: () {
                          setState(() {
                            _payments = null;
                            _payments = _getPayments();
                          });
                        },
                      );
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.all(80),
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _generatePayments(List<Payment> data) {
    if (data.length > 5) {
      data = data.take(5).toList();
    }
    return data.map((element) {
      return PaymentEntry(
        payment: element,
        selectedMemberId: context.read<UserState>().user!.id,
      );
    }).toList();
  }

  List<Widget> _generatePurchases(List<Purchase> data) {
    if (data.length > 5) {
      data = data.take(5).toList();
    }
    return data.map((element) {
      return PurchaseEntry(
        purchase: element,
        selectedMemberId: context.read<UserState>().user!.id,
      );
    }).toList();
  }
}
