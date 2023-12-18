import 'dart:async';
import 'dart:convert';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class IAPInitializer extends StatefulWidget {
  IAPInitializer({
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
        UserState userState = context.read<UserState>();
        for (PurchaseDetails details in purchases) {
          if (details.status == PurchaseStatus.purchased) {
            String url = context.read<AppConfig>().appUrl + '/user';
            Map<String, String> header = {
              "Content-Type": "application/json",
              "Authorization": "Bearer " + userState.user!.apiToken,
            };
            Map<String, dynamic> body = {};
            switch (details.productID) {
              case 'remove_ads':
                userState.setShownAds(false);
                body['ad_free'] = 1;
                break;
              case 'gradients':
                userState.setUseGradients(true);
                body['gradients_enabled'] = 1;
                break;
              case 'ad_gradient_bundle':
                userState.setShownAds(false);
                body['ad_free'] = 1;
                userState.setUseGradients(true);
                body['gradients_enabled'] = 1;
                break;
              case 'group_boost':
                body['boosts'] = 2;
                break;
              case 'big_lender_bundle':
                userState.setShownAds(false);
                body['ad_free'] = 1;
                userState.setUseGradients(true);
                body['gradients_enabled'] = 1;
                body['boosts'] = 1;
                break;
            }
            try {
              http.put(Uri.parse(url), headers: header, body: jsonEncode(body));
            } catch (_) {
              throw _;
            }
            InAppPurchase.instance.completePurchase(details);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => this.widget.builder(context);
}