import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:csocsort_szamla/helpers/navigator_service.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

double adHeight(BuildContext context) => (context.read<AppConfig>().isAdPlatformEnabled && (context.read<UserState>().user?.showAds ?? false)) ? 50 : 0;

/// The delay time in ms for the success dialog to pop.
int delayTime = 700;

void log(
  String message, {
  DateTime? time,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  Object? error,
  StackTrace? stackTrace,
}) {
  developer.log(
    message,
    time: time,
    sequenceNumber: sequenceNumber,
    level: level,
    name: name,
    zone: zone,
    error: error,
    stackTrace: stackTrace,
  );
  if (kDebugMode) {
    debugPrint(message);
  }
}

void showToast(
  String message, {
  bool error = false,
  bool useWidgetToast = false,
  Duration? toastDuration,
}) {
  BuildContext context = getIt.get<NavigationService>().navigatorKey.currentContext!;
  if (useWidgetToast || Platform.isLinux || Platform.isWindows) {
    FToast fluttertoast = FToast();
    Color background = error ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primaryContainer;
    Color textColor = error ? Theme.of(context).colorScheme.onError : Theme.of(context).colorScheme.onPrimaryContainer;
    fluttertoast.init(context);
    fluttertoast.showToast(
      toastDuration: toastDuration ?? Duration(seconds: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: background,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error ? Icons.clear : Icons.info_outline,
              color: textColor,
            ),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );

    return;
  }
  Fluttertoast.showToast(msg: message);
}

String getShopURL() {
  switch (Platform.operatingSystem) {
    case "android":
      return "market://details?id=csocsort.hu.machiato32.csocsort_szamla";
    case "windows":
      return "ms-windows-store://pdp/?productid=9NVB4CZJDSQ7";
    case "ios":
      return "itms-apps://itunes.apple.com/app/id1558223634?action=write-review";
    default:
      return "https://play.google.com/store/apps/details?id=csocsort.hu.machiato32.csocsort_szamla";
  }
}

DateTime maxDateTime(DateTime a, DateTime b) {
  if (a.isAfter(b)) {
    return a;
  }
  return b;
}

DateTime minDateTime(DateTime a, DateTime b) {
  if (a.isBefore(b)) {
    return a;
  }
  return b;
}

Future<String> getAssetPath(String asset) async {
  final path = await getLocalPath(asset);
  await Directory(dirname(path)).create(recursive: true);
  final file = File(path);
  if (!await file.exists()) {
    final byteData = await rootBundle.load(asset);
    await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }
  return file.path;
}

Future<String> getLocalPath(String path) async {
  return '${(await getApplicationSupportDirectory()).path}/$path';
}
