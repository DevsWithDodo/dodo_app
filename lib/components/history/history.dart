import 'dart:convert';

import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/components/helpers/background_paint.dart';
import 'package:csocsort_szamla/components/payment/payment_entry.dart';
import 'package:csocsort_szamla/components/purchase/purchase_entry.dart';
import 'package:csocsort_szamla/helpers/curves.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/history_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../helpers/models.dart';
import '../helpers/error_message.dart';
import '../helpers/gradient_button.dart';

class History extends StatefulHookWidget {
  final int? selectedIndex;
  const History({super.key, this.selectedIndex});

  @override
  State<History> createState() => _HistoryState();
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
            'group': context.read<UserNotifier>().currentGroup!.id.toString(),
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
      rethrow;
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
            'group': context.read<UserNotifier>().currentGroup!.id.toString(),
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
    final purchasesSnapshot = useFuture(_purchases);
    final paymentsSnapshot = useFuture(_payments);
    return CardWithBackground(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: <Widget>[
            Text(
              'history'.tr(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              'history_explanation'.tr(),
              style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                    label: Text('purchases'.tr()),
                    showCheckmark: false,
                    avatar: Icon(Icons.shopping_cart_outlined),
                    selected: _selectedIndex == 0,
                    selectedColor: context.colorScheme.tertiaryContainer,
                    iconTheme: IconThemeData(
                      color:
                          _selectedIndex == 0 ? context.colorScheme.onTertiaryContainer : context.colorScheme.onSurface,
                    ),
                    labelStyle: TextStyle(
                      color:
                          _selectedIndex == 0 ? context.colorScheme.onTertiaryContainer : context.colorScheme.onSurface,
                    ),
                    onSelected: (value) {
                      if (value) {
                        setState(() {
                          _selectedIndex = 0;
                        });
                      }
                    }),
                SizedBox(width: 8),
                ChoiceChip(
                    label: Text('payments'.tr()),
                    showCheckmark: false,
                    avatar: Icon(Icons.payment_outlined),
                    selected: _selectedIndex == 1,
                    selectedColor: context.colorScheme.tertiaryContainer,
                    iconTheme: IconThemeData(
                      color:
                          _selectedIndex == 1 ? context.colorScheme.onTertiaryContainer : context.colorScheme.onSurface,
                    ),
                    labelStyle: TextStyle(
                      color:
                          _selectedIndex == 1 ? context.colorScheme.onTertiaryContainer : context.colorScheme.onSurface,
                    ),
                    onSelected: (value) {
                      if (value) {
                        setState(() {
                          _selectedIndex = 1;
                        });
                      }
                    }),
              ],
            ),
            SizedBox(height: 10),
            AnimatedSize(
              alignment: Alignment.topCenter,
              duration: M3Curves.expressiveDefaultSpatial.duration,
              curve: M3Curves.expressiveDefaultSpatial.curve,
              child: AnimatedSwitcher(
                duration: M3Curves.expressiveDefaultSpatial.duration,
                switchOutCurve: M3Curves.expressiveDefaultSpatial.curve,
                switchInCurve: M3Curves.expressiveDefaultSpatial.curve.flipped,
                transitionBuilder: (child, animation) {
                  final leftToRight = _selectedIndex == 1;
                  // Slide old out to left, new in from right
                  final inOffset = Tween<Offset>(
                    begin: leftToRight ? Offset(1, 0) : Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  final outOffset = Tween<Offset>(
                    begin: leftToRight ? Offset(-1, 0) : Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation);

                  return ClipRect(
                    child: SlideTransition(
                      position: child.key == ValueKey(_selectedIndex) ? inOffset : outOffset,
                      child: child,
                    ),
                  );
                },
                layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                child: _selectedIndex == 0
                    ? Container(
                        key: ValueKey(_selectedIndex),
                        child: switch (purchasesSnapshot.connectionState) {
                          ConnectionState.done => switch (purchasesSnapshot.hasData) {
                              true => Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    SizedBox(height: 10),
                                    if (purchasesSnapshot.data!.isEmpty)
                                      Padding(
                                        padding: EdgeInsets.all(25),
                                        child: Text(
                                          'nothing_to_show'.tr(),
                                          style: Theme.of(context).textTheme.bodyLarge,
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    else
                                      ..._generatePurchases(purchasesSnapshot.data!),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Center(
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
                                      ),
                                    )
                                  ],
                                ),
                              false => ErrorMessage(
                                  error: purchasesSnapshot.error.toString(),
                                  errorLocation: 'purchase_history',
                                  onTap: () {
                                    setState(() {
                                      _purchases = null;
                                      _purchases = _getPurchases();
                                    });
                                  },
                                ),
                            },
                          _ => Padding(
                              padding: const EdgeInsets.all(80),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        },
                      )
                    : Container(
                        key: ValueKey(_selectedIndex),
                        child: switch (paymentsSnapshot.connectionState) {
                          ConnectionState.done => switch (paymentsSnapshot.hasData) {
                              true => Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    SizedBox(height: 10),
                                    if (paymentsSnapshot.data!.isEmpty)
                                      Padding(
                                        padding: EdgeInsets.all(25),
                                        child: Text(
                                          'nothing_to_show'.tr(),
                                          style: Theme.of(context).textTheme.bodyLarge,
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    else
                                      ..._generatePayments(paymentsSnapshot.data!),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Center(
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
                                      ),
                                    )
                                  ],
                                ),
                              false => ErrorMessage(
                                  error: paymentsSnapshot.error.toString(),
                                  errorLocation: 'payment_history',
                                  onTap: () {
                                    setState(() {
                                      _payments = null;
                                      _payments = _getPayments();
                                    });
                                  },
                                ),
                            },
                          _ => Padding(
                              padding: const EdgeInsets.all(80),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        },
                      ),
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
        selectedMemberId: context.read<UserNotifier>().user!.id,
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
        selectedMemberId: context.read<UserNotifier>().user!.id,
      );
    }).toList();
  }
}
