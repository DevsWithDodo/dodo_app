import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();
  Future<dynamic>? navigateToAndRemove(MaterialPageRoute route) {
    if (navigatorKey.currentState == null) return null;
    return navigatorKey.currentState!.pushAndRemoveUntil(route, (r) => false);
  }

  Future<dynamic>? navigateTo(MaterialPageRoute route) {
    if (navigatorKey.currentState == null) return null;
    return navigatorKey.currentState!.push(route);
  }
}
