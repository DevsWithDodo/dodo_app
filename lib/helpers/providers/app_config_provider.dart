import 'dart:io';

import 'package:csocsort_szamla/config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

class AppConfigProvider extends StatelessWidget {
  AppConfigProvider({required this.builder, super.key}) {
    _appConfig = AppConfig(
      useTest: false,
      isIAPPlatformEnabled: !kIsWeb && (Platform.isAndroid || Platform.isIOS),
      isAdPlatformEnabled: !kIsWeb && (Platform.isAndroid || Platform.isIOS),
      isFirebasePlatformEnabled: !kIsWeb && (Platform.isAndroid || Platform.isIOS),
      googleOAuthServerClientId: googleOAuthServerClientId,
    );

    if (_appConfig.isAdPlatformEnabled) {
      MobileAds.instance.initialize();
    }
  }

  final Widget Function(BuildContext context) builder;
  late final AppConfig _appConfig;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppConfig>(
      create: (context) => _appConfig,
      builder: (context, child) {
        return builder(context);
      },
    );
  }
}

class AppConfig extends ChangeNotifier {
  AppConfig({
    required bool useTest,
    required this.isIAPPlatformEnabled,
    required this.isAdPlatformEnabled,
    required this.isFirebasePlatformEnabled,
    required this.googleOAuthServerClientId,
  }) : _useTest = useTest;

  bool _useTest;
  final bool isIAPPlatformEnabled;
  final bool isAdPlatformEnabled;
  final bool isFirebasePlatformEnabled;
  final String googleOAuthServerClientId; 

  bool get useTest => _useTest;

  String get appUrl => _useTest ? TEST_URL : APP_URL;

  set useTest(bool value) {
    _useTest = value;
    notifyListeners();
  }
}
