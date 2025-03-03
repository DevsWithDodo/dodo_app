import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/navigator_service.dart';
import 'package:csocsort_szamla/main.dart';

class EventBus {
  static final refreshGroupMembers = _RefreshGroupMembers();
  static final refreshBalances = _RefreshBalances();
  static final refreshPurchases = _RefreshPurchases();
  static final refreshPayments = _RefreshPayments();
  static final refreshShopping = _RefreshShopping();
  static final refreshStatistics = _RefreshStatistics();
  static final refreshGroups = _RefreshGroups();
  static final refreshMainDialog = _RefreshMainDialog();
  static final hideMainDialog = _HideMainDialog();
  static final refreshGroupInfo = _RefreshGroupInfo();

  static final EventBus _instance = EventBus();

  static EventBus get instance => _instance;

  List<BaseEvent> events = [];
  Map<BaseEvent, List<Function>> listeners = {};

  void fire(BaseEvent event) {
    if (!events.contains(event)) {
      events.add(event);
    }
    if (listeners[event] == null) {
      listeners[event] = [];
    }
    if (event is _AppEvent) {
      event.onEvent();
    }
    for (var element in listeners[event]!) {
      element();
    }
  }

  void register(BaseEvent event, Function listener) {
    if (!events.contains(event)) {
      events.add(event);
    }
    if (listeners[event] == null) {
      listeners[event] = [];
    }
    listeners[event]!.add(listener);
  }

  void unregister(BaseEvent event, Function listener) {
    if (listeners[event] != null) {
      listeners[event]!.remove(listener);
    }
  }

  void unregisterAll(BaseEvent event) {
    if (listeners[event] != null) {
      listeners[event]!.clear();
    }
  }

  void unregisterAllEvents() {
    events.clear();
    listeners.clear();
  }
}

abstract class BaseEvent {}

abstract class _EmptyEvent extends BaseEvent {}

abstract class _AppEvent extends BaseEvent {
  void onEvent();
}

class _HideMainDialog extends _EmptyEvent {}

class _RefreshMainDialog extends _EmptyEvent {}

class _RefreshGroupMembers extends _AppEvent {
  @override
  void onEvent() {
    deleteCache(
      uri: generateUri(GetUriKeys.groupCurrent, getIt.get<NavigationService>().navigatorKey.currentContext!),
    );
  }
}

class _RefreshBalances extends _AppEvent {
  @override
  void onEvent() {
    deleteCache(uri: generateUri(GetUriKeys.userBalanceSum, getIt.get<NavigationService>().navigatorKey.currentContext!));
    deleteCache(uri: generateUri(GetUriKeys.groupCurrent, getIt.get<NavigationService>().navigatorKey.currentContext!));
  }
}

class _RefreshPurchases extends _AppEvent {
  @override
  void onEvent() {
    deleteCache(uri: generateUri(GetUriKeys.purchases, getIt.get<NavigationService>().navigatorKey.currentContext!), multipleArgs: true);
  }
}

class _RefreshPayments extends _AppEvent {
  @override
  void onEvent() {
    deleteCache(uri: generateUri(GetUriKeys.payments, getIt.get<NavigationService>().navigatorKey.currentContext!), multipleArgs: true);
  }
}

class _RefreshShopping extends _AppEvent {
  @override
  void onEvent() {
    deleteCache(uri: generateUri(GetUriKeys.requests, getIt.get<NavigationService>().navigatorKey.currentContext!), multipleArgs: true);
  }
}

class _RefreshStatistics extends _EmptyEvent {}

class _RefreshGroups extends _AppEvent {
  @override
  void onEvent() {
    deleteCache(
      uri: generateUri(GetUriKeys.groups, getIt.get<NavigationService>().navigatorKey.currentContext!),
    );
  }
}

class _RefreshGroupInfo extends _AppEvent {
  @override
  void onEvent() {
    deleteCache(
      uri: generateUri(GetUriKeys.groupCurrent, getIt.get<NavigationService>().navigatorKey.currentContext!),
    );
    deleteCache(
      uri: generateUri(GetUriKeys.groupMember, getIt.get<NavigationService>().navigatorKey.currentContext!),
    );
  }
}
