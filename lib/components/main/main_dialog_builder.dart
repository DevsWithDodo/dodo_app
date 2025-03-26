import 'dart:math';

import 'package:csocsort_szamla/components/main/dialogs/iapp_not_supported_dialog.dart';
import 'package:csocsort_szamla/components/main/dialogs/personalised_ads_dialog.dart';
import 'package:csocsort_szamla/components/main/main_dialogs/main_dialog.dart';
import 'package:csocsort_szamla/components/main/main_dialogs/payment_method.dart';
import 'package:csocsort_szamla/components/main/main_dialogs/pin_verification.dart';
import 'package:csocsort_szamla/components/main/main_dialogs/rate_app.dart';
import 'package:csocsort_szamla/components/main/main_dialogs/themes.dart';
import 'package:csocsort_szamla/components/main/main_dialogs/trial_ended_dialog.dart';
import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/navigator_service.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/helpers/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_usage_provider.dart';
import 'package:csocsort_szamla/main.dart';
import 'package:csocsort_szamla/pages/app/store_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainDialogBuilder extends StatefulWidget {
  late final List<MainDialog> dialogs;
  late final MainDialog? chosenDialog;
  final BuildContext context;

  MainDialogBuilder({required this.context, super.key}) {
    dialogs = [
      TrialEndedDialog(
        canShow: (context) => context.read<UserNotifier>().user!.userStatus.trialStatus == TrialStatus.expired,
        type: DialogType.modal,
        showTime: DialogShowTime.both,
        onDismiss: (context, {payload}) async {
          Http.put(
            uri: '/user',
            body: {
              'trial_status': "seen",
            },
          );
          UserNotifier provider = context.read<UserNotifier>();
          AppThemeState appTheme = context.read<AppThemeState>();
          provider.setUserStatus(provider.user!.userStatus.copyWith(
            trialStatus: TrialStatus.seen,
          ));
          EventBus.instance.fire(EventBus.hideMainDialog);
          ThemeName currentTheme = appTheme.themeName;
          if (currentTheme.type == ThemeType.dualColor || currentTheme.type == ThemeType.gradient || currentTheme.type == ThemeType.dynamic) {
            appTheme.themeName = currentTheme.brightness == Brightness.light ? ThemeName.greenLight : ThemeName.greenDark;
          }
          if (payload == 'shop') {
            if (context.read<AppConfig>().isIAPPlatformEnabled) {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const StorePage(),
              ));
            } else {
              await showDialog(
                context: context,
                builder: (context) => IAPNotSupportedDialog(),
              );
            }
          }
          showDialog(
            context: getIt.get<NavigationService>().navigatorKey.currentContext!,
            builder: (context) => PersonalisedAdsDialog(),
          );
        },
      ),
      PinVerificationMainDialog(
        showTime: DialogShowTime.both,
        type: DialogType.bottom,
        canShow: (context) {
          User user = context.read<UserNotifier>().user!;
          if (user.googleConnected || user.appleConnected) return false; // No username means social login, no need for pin verification
          UserStatus status = user.userStatus;
          int verificationCount = status.pinVerificationCount;
          Duration difference = DateTime.now().difference(status.pinVerifiedAt);
          if (verificationCount <= 1 && difference.inDays >= 1) {
            return true;
          }
          if (verificationCount == 2 && difference.inDays >= 3) {
            return true;
          }
          if (verificationCount <= 5 && difference.inDays >= 7) {
            return true;
          }
          if (difference.inDays >= 30) {
            return true;
          }
          return false;
        },
        onDismiss: (context, {payload}) {
          UserNotifier provider = context.read<UserNotifier>();
          UserStatus status = provider.user!.userStatus;
          provider.setUserStatus(status.copyWith(
            pinVerifiedAt: DateTime.now(), // Only show once per session
          ));
        },
      ),
      RateAppMainDialog(
        canShow: (context) {
          final usage = context.read<UserUsageNotifier>();

          // Check if the user has rated the app or if they are a new user
          if (usage.ratedApp || usage.appOpenCount < 5) return false;

          const int minDaysSinceLastPrompt = 30; // Cooldown period
          // Prevent spamming: Check last prompt or dismissal cooldown
          if (DateTime.now().difference(usage.lastRateAppDialogDate).inDays < minDaysSinceLastPrompt) {
            return false;
          }

          // If any major milestone flag is true, show the prompt
          if (usage.anyFlagTrue()) {
            usage.setFlagsFalse(); // Reset flags after showing the dialog
            usage.setLastRateAppDialogDate(DateTime.now()); // Update the last prompt date
            return true;
          }

          const int minExpenseCount = 5;
          const int minReceiptScans = 2;
          const int minAppOpens = 10;
          const int minGroupsCreated = 2;
          // Calculate engagement probability based on usage metrics
          double engagementProbability = min(0.8, 0.2 + (usage.appOpenCount / 50) * 0.6);
          // **PROBABILITY-BASED TRIGGER**: If engagement conditions are met, show with some probability
          bool meetsEngagementCriteria = usage.expenseCount >= minExpenseCount || usage.receiptScannerCount >= minReceiptScans || usage.appOpenCount >= minAppOpens || usage.groupsUsedCount >= minGroupsCreated;

          if (meetsEngagementCriteria) {
            bool show = Random().nextDouble() < engagementProbability;
            if (show) {
              usage.setLastRateAppDialogDate(DateTime.now());
              return true;
            }
          }

          return false;
        },
        type: DialogType.modal,
        showTime: DialogShowTime.onBuild,
        onDismiss: (context, {payload}) {
          context.read<UserNotifier>().user!.ratedApp = true;
          EventBus.instance.fire(EventBus.hideMainDialog);
        },
      ),
      PaymentMethodMainDialog(
        canShow: (context) {
          User? user = context.read<UserNotifier>().user;
          return user != null && user.paymentMethods.isEmpty && Random().nextDouble() <= 0.15;
        },
        type: DialogType.bottom,
        showTime: DialogShowTime.onBuild,
      ),
      ThemesMainDialog(
        canShow: (context) {
          UserNotifier provider = context.read<UserNotifier>();
          User? user = provider.user;
          ThemeName currentTheme = context.read<AppThemeState>().themeName;
          if (user == null) return false;
          late double chance;
          if (user.userStatus.trialStatus == TrialStatus.trial) {
            chance = currentTheme.isDodo() ? 0.2 : 0.05;
          } else {
            chance = currentTheme == ThemeName.greenLight || currentTheme == ThemeName.greenDark ? 0.1 : 0.05;
          }
          return Random().nextDouble() <= chance;
        },
        type: DialogType.bottom,
        showTime: DialogShowTime.onBuild,
      ),
    ];
    chosenDialog = chooseWidget(DialogShowTime.onInit, context);
  }

  MainDialog? chooseWidget(DialogShowTime showTime, BuildContext context) {
    return dialogs.where((dialog) => (dialog.showTime == showTime || dialog.showTime == DialogShowTime.both) && dialog.canShow(context)).firstOrNull;
  }

  @override
  State<MainDialogBuilder> createState() => _MainDialogBuilderState();
}

class _MainDialogBuilderState extends State<MainDialogBuilder> {
  late MainDialog? _dialog;
  late bool visible;

  void onRefreshMainDialog() {
    if (!visible) {
      setState(() {
        _dialog = widget.chooseWidget(DialogShowTime.onBuild, getIt.get<NavigationService>().navigatorKey.currentContext!);
        visible = _dialog != null;
      });
    }
  }

  void onHideMainDialog() {
    setState(() {
      visible = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _dialog = widget.chosenDialog;
    visible = _dialog != null;

    EventBus.instance.register(EventBus.refreshMainDialog, onRefreshMainDialog);
    EventBus.instance.register(EventBus.hideMainDialog, onHideMainDialog);
  }

  @override
  void dispose() {
    EventBus.instance.unregister(EventBus.refreshMainDialog, onRefreshMainDialog);
    EventBus.instance.unregister(EventBus.hideMainDialog, onHideMainDialog);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: Stack(
        children: [
          Positioned.fill(
            child: Visibility(
              visible: _dialog?.type == DialogType.modal,
              child: GestureDetector(
                onTap: () => _dialog!.onDismiss != null ? _dialog!.onDismiss!(context) : setState(() => visible = false),
                child: Container(
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: _dialog?.type == DialogType.modal ? Alignment.center : Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: _dialog?.type == DialogType.bottom ? (context.select<ScreenSize, bool>((provider) => provider.isMobile) ? 95 : 15) : 0),
                child: Provider.value(
                  value: () => setState(() {
                    visible = false;
                    _dialog?.onDismiss?.call(context);
                  }),
                  builder: (context, _) {
                    return _dialog!;
                  },
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
