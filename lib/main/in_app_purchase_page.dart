import 'dart:io';
import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/widgets/error_message.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class InAppPurchasePage extends StatefulWidget {
  @override
  _InAppPurchasePageState createState() => _InAppPurchasePageState();
}

class _InAppPurchasePageState extends State<InAppPurchasePage> {
  Set<String> _ids = {
    'gradients',
    'remove_ads',
    Platform.isAndroid ? 'ad_gradient_bundle' : 'ad_gradient_bundle_2',
    'group_boost',
    'big_lender_bundle'
  };
  Map<String, int> sortBasic = {
    'remove_ads': 1,
    'gradients': 2,
    Platform.isAndroid ? 'ad_gradient_bundle' : 'ad_gradient_bundle_2': 3,
    'group_boost': 4,
    'big_lender_bundle': 5
  };
  var iap = InAppPurchase.instance;

  bool _isConsumable(String id) {
    switch (id) {
      case 'gradients':
        return false;
        break;
      case 'remove_ads':
        return false;
        break;
      case 'ad_gradient_bundle':
        return false;
        break;
      case 'group_boost':
        return true;
        break;
      case 'big_lender_bundle':
        return false;
        break;
    }
  }

  List<Widget> _buildItems(List<ProductDetails> details) {
    details.sort((a, b) => sortBasic[a.id].compareTo(sortBasic[b.id]));
    return details.map((e) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                e.id.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 10,
              ),
              Text((e.id + '_explanation').tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
              SizedBox(
                height: 10,
              ),
              Text('price'.tr() + e.price,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GradientButton(
                    child: Text(
                      'buy'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          .copyWith(color: Theme.of(context).colorScheme.onPrimary),
                    ),
                    onPressed: () {
                      PurchaseParam purchaseParam = PurchaseParam(productDetails: e);
                      if (_isConsumable(e.id)) {
                        InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
                      } else {
                        InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
                      }
                    },
                  )
                ],
              )
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'in_app_purchase'.tr(),
          // style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
        // flexibleSpace: Container(
        //   decoration: BoxDecoration(
        //       gradient: AppTheme.gradientFromTheme(Theme.of(context))),
        // ),
      ),
      body: !isIAPPlatformEnabled
          ? Container()
          : FutureBuilder(
              future: iap.isAvailable(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    if (snapshot.data) {
                      return FutureBuilder(
                        future: InAppPurchase.instance.queryProductDetails(_ids),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done) {
                            if (snapshot.hasData) {
                              return ListView(
                                children: _buildItems(snapshot.data.productDetails),
                              );
                            } else {
                              return ErrorMessage(
                                error: snapshot.error,
                                callback: () {
                                  setState(() {});
                                },
                                locationOfError: 'in_app_purchase',
                              );
                            }
                          }

                          return LinearProgressIndicator(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          );
                        },
                      );
                    } else {
                      return ErrorMessage(
                        error: 'error',
                        callback: () {
                          setState(() {});
                        },
                        locationOfError: 'in_app_purchase',
                      );
                    }
                  } else {
                    return ErrorMessage(
                      error: snapshot.error,
                      callback: () {
                        setState(() {});
                      },
                      locationOfError: 'in_app_purchase',
                    );
                  }
                }
                return LinearProgressIndicator(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                );
              },
            ),
    );
  }
}
