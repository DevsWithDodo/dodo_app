import 'dart:io';

import 'package:csocsort_szamla/bootstrap.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'helpers/navigator_service.dart';

final getIt = GetIt.instance;

// Needed for HTTPSp
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  getIt.registerSingleton<NavigationService>(NavigationService());
  HttpOverrides.global = MyHttpOverrides();
  runApp(Bootstrap());
}