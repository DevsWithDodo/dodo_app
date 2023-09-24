import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();
  Future<dynamic>? pushAndRemoveUntil(MaterialPageRoute route) {
    if (navigatorKey.currentState == null) return null;
    return navigatorKey.currentState!.pushAndRemoveUntil(route, (r) => false);
  }

  Future<dynamic>? push(MaterialPageRoute route) {
    if (navigatorKey.currentState == null) return null;
    return navigatorKey.currentState!.push(route);
  }
}
