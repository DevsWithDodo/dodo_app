import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:event_bus_plus/event_bus_plus.dart';
import 'package:flutter/material.dart';

class EventBusProvider extends ChangeNotifier {
  final EventBus _eventBus = EventBus();

  EventBus get eventBus => _eventBus;
}

class RefreshBalances extends EmptyEvent {
  RefreshBalances() {
    deleteCache(uri: generateUri(GetUriKeys.userBalanceSum));
    deleteCache(uri: generateUri(GetUriKeys.groupCurrent));
  }
}

class RefreshPurchases extends EmptyEvent {
  RefreshPurchases() {
    deleteCache(uri: generateUri(GetUriKeys.purchases), multipleArgs: true);
  }
}

class RefreshPayments extends EmptyEvent {
  RefreshPayments() {
    deleteCache(uri: generateUri(GetUriKeys.payments), multipleArgs: true);
  }
}

class RefreshShopping extends EmptyEvent {
  RefreshShopping() {
    deleteCache(uri: generateUri(GetUriKeys.requests), multipleArgs: true);
  }
}

class RefreshStatistics extends EmptyEvent {}

class RefreshGroups extends EmptyEvent {
  RefreshGroups() {
    deleteCache(uri: generateUri(GetUriKeys.groups));
  }
}
