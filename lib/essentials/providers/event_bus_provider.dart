import 'package:csocsort_szamla/essentials/http.dart';
import 'package:event_bus_plus/event_bus_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventBusProvider extends StatelessWidget {
  final EventBus _eventBus = EventBus();
  final Widget child;

  EventBusProvider({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: _eventBus,
      child: child,
    );
  }
}

class RefreshBalances extends EmptyEvent {
  RefreshBalances(BuildContext context) {
    deleteCache(uri: generateUri(GetUriKeys.userBalanceSum, context));
    deleteCache(uri: generateUri(GetUriKeys.groupCurrent, context));
  }
}

class RefreshPurchases extends EmptyEvent {
  RefreshPurchases(BuildContext context) {
    deleteCache(uri: generateUri(GetUriKeys.purchases, context), multipleArgs: true);
  }
}

class RefreshPayments extends EmptyEvent {
  RefreshPayments(BuildContext context) {
    deleteCache(uri: generateUri(GetUriKeys.payments, context), multipleArgs: true);
  }
}

class RefreshShopping extends EmptyEvent {
  RefreshShopping(BuildContext context) {
    deleteCache(uri: generateUri(GetUriKeys.requests, context), multipleArgs: true);
  }
}

class RefreshStatistics extends EmptyEvent {}

class RefreshGroups extends EmptyEvent {
  RefreshGroups(BuildContext context) {
    deleteCache(uri: generateUri(GetUriKeys.groups, context));
  }
}
