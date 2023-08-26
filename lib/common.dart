import 'dart:io';

import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/navigator_service.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/main.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

double adHeight(BuildContext context) => (isAdPlatformEnabled &&
        (context.read<AppStateProvider>().user?.showAds ?? false))
    ? 50
    : 0;

/// The delay time in ms for the success dialog to pop.
int delayTime = 700;

void showToast(
  String message, {
  bool error = false,
  bool useWidgetToast = false,
  Duration? toastDuration,
}) {
  BuildContext context =
      getIt.get<NavigationService>().navigatorKey.currentContext!;
  if (useWidgetToast || Platform.isLinux || Platform.isWindows) {
    FToast fluttertoast = FToast();
    Color background = error
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primaryContainer;
    Color textColor = error
        ? Theme.of(context).colorScheme.onError
        : Theme.of(context).colorScheme.onPrimaryContainer;
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
            SizedBox(
              width: 12.0,
            ),
            Flexible(
                child: Text(message,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: textColor))),
          ],
        ),
      ),
    );

    return;
  }
  Fluttertoast.showToast(msg: message);
}
