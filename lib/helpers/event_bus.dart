import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/navigator_service.dart';
import 'package:csocsort_szamla/main.dart';

class EventBus {
  static _RefreshGroupMembers refreshGroupMembers = _RefreshGroupMembers();
  static _RefreshBalances refreshBalances = _RefreshBalances();
  static _RefreshPurchases refreshPurchases = _RefreshPurchases();
  static _RefreshPayments refreshPayments = _RefreshPayments();
  static _RefreshShopping refreshShopping = _RefreshShopping();
  static _RefreshStatistics refreshStatistics = _RefreshStatistics();
  static _RefreshGroups refreshGroups = _RefreshGroups();
  static _RefreshMainDialog refreshMainDialog = _RefreshMainDialog();
  static _HideMainDialog hideMainDialog = _HideMainDialog();
  static _RefreshGroupInfo refreshGroupInfo = _RefreshGroupInfo();

  static final EventBus _instance = EventBus();

  static EventBus get instance => _instance;

  List<_Event> events = [];
  Map<_Event, List<Function>> listeners = {};

  void fire(_Event event) {
    if (!events.contains(event)) {
      events.add(event);
    }
    if (listeners[event] == null) {
      listeners[event] = [];
    }
    if (event is _AppEvent) {
      event.onEvent();
    }
    listeners[event]!.forEach((Function element) {
      element();
    });
  }

  void register(_Event event, Function listener) {
    if (!events.contains(event)) {
      events.add(event);
    }
    if (listeners[event] == null) {
      listeners[event] = [];
    }
    listeners[event]!.add(listener);
  }

  void unregister(_Event event, Function listener) {
    if (listeners[event] != null) {
      listeners[event]!.remove(listener);
    }
  }

  void unregisterAll(_Event event) {
    if (listeners[event] != null) {
      listeners[event]!.clear();
    }
  }

  void unregisterAllEvents() {
    events.clear();
    listeners.clear();
  }
}

abstract class _Event {}

abstract class _EmptyEvent extends _Event {}

abstract class _AppEvent extends _Event {
  void onEvent();
}

class _HideMainDialog extends _EmptyEvent {}

class _RefreshMainDialog extends _EmptyEvent {}

class _RefreshGroupMembers extends _AppEvent {
  @override
  void onEvent() {
    deleteCache(
      uri: generateUri(GetUriKeys.groupCurrent,
          getIt.get<NavigationService>().navigatorKey.currentContext!),
    );
  }
}

class _RefreshBalances extends _AppEvent {
  @override
  void onEvent() {
    deleteCache(
        uri: generateUri(GetUriKeys.userBalanceSum,
            getIt.get<NavigationService>().navigatorKey.currentContext!));
    deleteCache(
        uri: generateUri(GetUriKeys.groupCurrent,
            getIt.get<NavigationService>().navigatorKey.currentContext!));
  }
}

class _RefreshPurchases extends _AppEvent {
  @override
  void onEvent() {
    deleteCache(
        uri: generateUri(GetUriKeys.purchases,
            getIt.get<NavigationService>().navigatorKey.currentContext!),
        multipleArgs: true);
  }
}

class _RefreshPayments extends _AppEvent {
  @override
  void onEvent() {
    deleteCache(
        uri: generateUri(GetUriKeys.payments,
            getIt.get<NavigationService>().navigatorKey.currentContext!),
        multipleArgs: true);
  }
}

class _RefreshShopping extends _AppEvent {
  @override
  void onEvent() {
    deleteCache(
        uri: generateUri(GetUriKeys.requests,
            getIt.get<NavigationService>().navigatorKey.currentContext!),
        multipleArgs: true);
  }
}

class _RefreshStatistics extends _EmptyEvent {}

class _RefreshGroups extends _AppEvent {
  @override
  void onEvent() {
    deleteCache(
      uri: generateUri(GetUriKeys.groups,
          getIt.get<NavigationService>().navigatorKey.currentContext!),
    );
  }
}

class _RefreshGroupInfo extends _AppEvent {
  @override
  void onEvent() {
    deleteCache(
      uri: generateUri(GetUriKeys.groupCurrent,
          getIt.get<NavigationService>().navigatorKey.currentContext!),
    );
    deleteCache(
      uri: generateUri(GetUriKeys.groupMember,
          getIt.get<NavigationService>().navigatorKey.currentContext!),
    );
  }
}