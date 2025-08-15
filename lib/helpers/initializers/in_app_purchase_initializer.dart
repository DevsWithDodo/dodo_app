import 'dart:async';
import 'dart:convert';

import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/helpers/navigator_service.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/main.dart';
import 'package:csocsort_szamla/pages/app/main_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

class IAPInitializer extends StatefulWidget {
  const IAPInitializer({
    required BuildContext context,
    required this.builder,
    super.key,
  });

  final Widget Function(BuildContext context) builder;

  @override
  State<IAPInitializer> createState() => _IAPInitializerState();
}

class _IAPInitializerState extends State<IAPInitializer> {
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    init(context);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void init(BuildContext context) {
    if (context.read<AppConfig>().isIAPPlatformEnabled) {
      _subscription = InAppPurchase.instance.purchaseStream.listen((purchases) {
        print('ITT');
        print(purchases);
        UserNotifier userState = context.read<UserNotifier>();
        for (PurchaseDetails details in purchases) {
          if (details.status == PurchaseStatus.purchased) {
            String url = '${context.read<AppConfig>().appUrl}/user';
            Map<String, String> header = {
              "Content-Type": "application/json",
              "Authorization": "Bearer ${userState.user!.apiToken}",
            };
            Map<String, dynamic> body = {};
            switch (details.productID) {
              case 'remove_ads':
                userState.setShowAds(false);
                body['ad_free'] = 1;
                break;
              case 'gradients':
                userState.setUseGradients(true);
                body['gradients_enabled'] = 1;
                break;
              case 'ad_gradient_bundle':
                userState.setShowAds(false);
                body['ad_free'] = 1;
                userState.setUseGradients(true);
                body['gradients_enabled'] = 1;
                break;
              case 'group_boost':
                body['boosts'] = 2;
                break;
              case 'big_lender_bundle':
                userState.setShowAds(false);
                body['ad_free'] = 1;
                userState.setUseGradients(true);
                body['gradients_enabled'] = 1;
                body['boosts'] = 1;
                break;
            }
            Future<BoolFutureOutput> updateUser() async {
              try {
                final results = await Future.wait([
                  http.put(Uri.parse(url), headers: header, body: jsonEncode(body)),
                  Future.delayed(
                      const Duration(seconds: 1)), // Wait at least 1 second to make it look like something is happening
                ]);
                final response = results[0] as http.Response;
                if (response.statusCode >= 200 && response.statusCode < 300) {
                  return BoolFutureOutput.True;
                } else {
                  return BoolFutureOutput.False;
                }
              } catch (e) {
                return BoolFutureOutput.False;
              }
            }

            showFutureOutputDialog(
                context: getIt.get<NavigationService>().navigatorKey.currentContext!,
                future: updateUser(),
                outputTexts: {
                  BoolFutureOutput.False: 'in_app_purchase.error'.tr()
                },
                outputCallbacks: {
                  BoolFutureOutput.True: () {
                    getIt.get<NavigationService>().navigatorKey.currentState?.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => MainPage(),
                          ),
                          (route) => false,
                        );
                  },
                });
            InAppPurchase.instance.completePurchase(details);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
