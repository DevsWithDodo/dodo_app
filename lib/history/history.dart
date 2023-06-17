import 'dart:convert';

import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/providers/EventBusProvider.dart';
import 'package:csocsort_szamla/history/all_history_page.dart';
import 'package:csocsort_szamla/payment/payment_entry.dart';
import 'package:csocsort_szamla/purchase/purchase_entry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:event_bus_plus/event_bus_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../essentials/app_theme.dart';
import '../essentials/models.dart';
import '../essentials/widgets/error_message.dart';
import '../essentials/widgets/gradient_button.dart';

class History extends StatefulWidget {
  final int? selectedIndex;
  History({this.selectedIndex});

  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  Future<List<Payment>>? _payments;
  Future<List<Purchase>>? _purchases;
  int? _selectedIndex;
  Future<List<Purchase>> _getPurchases({bool overwriteCache = false}) async {
    try {
      http.Response response = await httpGet(
        uri: generateUri(
          GetUriKeys.purchases,
          queryParams: {
            'limit': '6',
            'group': currentGroupId.toString(),
          },
        ),
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
      http.Response response = await httpGet(
        uri: generateUri(
          GetUriKeys.payments,
          queryParams: {
            'limit': '6',
            'group': currentGroupId.toString(),
          },
        ),
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

  @override
  void initState() {
    _selectedIndex = widget.selectedIndex;
    _payments = null;
    _payments = _getPayments();
    _purchases = null;
    _purchases = _getPurchases();

    final eventBus = context.read<EventBus>();
    eventBus.on<RefreshPurchases>().listen((_) {
      if (mounted) {
        _purchases = null;
        _purchases = _getPurchases(overwriteCache: true);
        setState(() {});
      }
    });
    eventBus.on<RefreshPayments>().listen((_) {
      if (mounted) {
        _payments = null;
        _payments = _getPayments(overwriteCache: true);
        setState(() {});
      }
    });

    super.initState();
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
            Row(
              children: <Widget>[
                Flexible(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _selectedIndex = 0;
                      setState(() {});
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: _selectedIndex == 0
                            ? AppTheme.gradientFromTheme(currentThemeName)
                            : LinearGradient(colors: [
                                ElevationOverlay.applyOverlay(context,
                                    Theme.of(context).colorScheme.surface, 10),
                                ElevationOverlay.applyOverlay(context,
                                    Theme.of(context).colorScheme.surface, 10)
                              ]),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart,
                              color: _selectedIndex == 0
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                          SizedBox(
                            width: 3,
                          ),
                          Flexible(
                            child: Text(
                              'purchases'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge!
                                  .copyWith(
                                      color: _selectedIndex == 0
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Flexible(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _selectedIndex = 1;
                      setState(() {});
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: _selectedIndex == 1
                            ? AppTheme.gradientFromTheme(currentThemeName)
                            : LinearGradient(colors: [
                                ElevationOverlay.applyOverlay(context,
                                    Theme.of(context).colorScheme.surface, 10),
                                ElevationOverlay.applyOverlay(context,
                                    Theme.of(context).colorScheme.surface, 10)
                              ]),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.attach_money,
                              color: _selectedIndex == 1
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                          SizedBox(
                            width: 3,
                          ),
                          Flexible(
                            child: Text(
                              'payments'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge!
                                  .copyWith(
                                      color: _selectedIndex == 1
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
                      if (snapshot.data!.length == 0) {
                        return Padding(
                          padding: EdgeInsets.all(25),
                          child: Text(
                            'nothing_to_show'.tr(),
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Column(
                        children: <Widget>[
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            // height: 490,
                            child: Column(
                              children: _generatePurchases(snapshot.data!),
                            ),
                          ),
                          Visibility(
                            visible: snapshot.data!.length > 5,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: GradientButton.icon(
                                useSecondary: true,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AllHistoryRoute(
                                          startingIndex: _selectedIndex),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.more_horiz),
                                label: Text('more'.tr()),
                              ),
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
                      if (snapshot.data!.length == 0) {
                        return Padding(
                          padding: EdgeInsets.all(25),
                          child: Text(
                            'nothing_to_show'.tr(),
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Column(
                        children: <Widget>[
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            // height: 490,
                            child: Column(
                                children: _generatePayments(snapshot.data!)),
                          ),
                          Visibility(
                            visible: (snapshot.data as List).length > 5,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: GradientButton.icon(
                                useSecondary: true,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AllHistoryRoute(
                                        startingIndex: _selectedIndex,
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.more_horiz),
                                label: Text('more'.tr()),
                              ),
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
        selectedMemberId: currentUserId!,
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
        selectedMemberId: currentUserId!,
      );
    }).toList();
  }
}
