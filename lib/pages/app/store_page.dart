import 'dart:io';

import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/main/dialogs/trial_version_dialog.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/customize_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});
  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  @override
  void initState() {
    super.initState();
    isAvailable = _isAvailable();
    productDetailsResponse = getProductDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This hopefully isn't needed, but just in case
      if (!context.read<AppConfig>().isIAPPlatformEnabled) {
        Navigator.of(context).pop();
      }
    });
  }

  late Future<bool> isAvailable;
  late Future<ProductDetailsResponse> productDetailsResponse;
  Future<bool> _isAvailable() async {
    return await InAppPurchase.instance.isAvailable();
  }

  Future<ProductDetailsResponse> getProductDetails() async {
    return await InAppPurchase.instance.queryProductDetails(ProductOption.ids);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('store-page'.tr()),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              'store-page.general-information'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          FutureBuilder(
            future: isAvailable,
            builder: (context, AsyncSnapshot<bool> isAvailableSnapshot) {
              if (isAvailableSnapshot.connectionState != ConnectionState.done) {
                return LinearProgressIndicator(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                );
              }
              if (!isAvailableSnapshot.hasData) {
                return ErrorMessage(
                  error: isAvailableSnapshot.error as String?,
                  onTap: () => setState(() => isAvailable = _isAvailable()),
                  errorLocation: 'in_app_purchase',
                );
              }
              if (!isAvailableSnapshot.data!) {
                return ErrorMessage(
                  error: 'error',
                  onTap: () => setState(() => isAvailable = _isAvailable()),
                  errorLocation: 'in_app_purchase',
                );
              }
              return FutureBuilder(
                future: productDetailsResponse,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return LinearProgressIndicator();
                  }
                  if (!snapshot.hasData) {
                    return ErrorMessage(
                      error: snapshot.error as String?,
                      onTap: () => setState(() => productDetailsResponse = getProductDetails()),
                      errorLocation: 'in_app_purchase',
                    );
                  }
                  final user = context.read<UserState>().user!;
                  final wrappedDetails = snapshot.data!.productDetails
                      .map(
                        (e) => ProductDetailsWrapper.fromProductDetails(e, user),
                      )
                      .where((e) => e.isAvailableForPurchase)
                      .toList()
                    ..sort();
                  return Column(
                    children: wrappedDetails
                        .map(
                          (productDetail) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "store-page.${productDetail.name}".tr(),
                                    style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  if (productDetail.productOption == ProductOption.gradients)
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'store-page.${productDetail.name}.details.1'.tr(),
                                            style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                          ),
                                          TextSpan(
                                            text: 'store-page.${productDetail.name}.details.2'.tr(),
                                            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                  decoration: TextDecoration.underline,
                                                ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => CustomizePage(),
                                                    ),
                                                  ),
                                          ),
                                          TextSpan(
                                            text: 'store-page.${productDetail.name}.details.3'.tr(),
                                            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  else
                                    Text(
                                      'store-page.${productDetail.name}.details'.tr(),
                                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    'store-page.price'.tr(args: [productDetail.price]),
                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GradientButton(
                                          child: Text('store-page.buy'.tr()),
                                          onPressed: () {
                                            if (user.trialVersion) {
                                              showDialog(
                                                context: context,
                                                builder: (context) => TrialVersionDialog(),
                                              );
                                              return;
                                            }
                                            final purchaseParam = PurchaseParam(productDetails: productDetail.productDetails);
                                            if (productDetail.isConsumable) {
                                              InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
                                            } else {
                                              InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
                                            }
                                          },
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

enum ProductOption {
  removeAds(
    isConsumable: false,
    names: ['remove_ads'],
  ),
  gradients(
    isConsumable: false,
    names: ['gradients'],
  ),
  adGradientBundle(
    isConsumable: false,
    names: ['ad_gradient_bundle', 'ad_gradient_bundle_2'],
  ),
  groupBoost(
    isConsumable: true,
    names: ['group_boost'],
  ),
  bigLenderBundle(
    isConsumable: false,
    names: ['big_lender_bundle'],
  );

  const ProductOption({
    required this.isConsumable,
    required this.names,
  });

  final bool isConsumable;
  final List<String> names;

  static ProductOption fromString(String id) {
    return ProductOption.values.firstWhere(
      (e) => e.names.contains(id),
    );
  }

  bool isAvailableForPurchase(User user) {
    switch (this) {
      case ProductOption.removeAds:
        return user.showAds;
      case ProductOption.gradients:
        return !user.useGradients;
      case ProductOption.adGradientBundle:
        return !user.useGradients && user.showAds;
      case ProductOption.groupBoost:
        return true;
      case ProductOption.bigLenderBundle:
        return !user.useGradients && user.showAds;
    }
  }

  static Set<String> get ids {
    return ProductOption.values
        .expand(
          (e) => e == ProductOption.adGradientBundle ? [Platform.isIOS ? e.names[1] : e.names[0]] : e.names,
        )
        .toSet();
  }
}

class ProductDetailsWrapper implements Comparable<ProductDetailsWrapper> {
  final ProductDetails productDetails;
  final bool isAvailableForPurchase;
  final ProductOption productOption;

  ProductDetailsWrapper({
    required this.productDetails,
    required this.isAvailableForPurchase,
    required this.productOption,
  });

  factory ProductDetailsWrapper.fromProductDetails(
    ProductDetails productDetails,
    User user,
  ) {
    final option = ProductOption.fromString(productDetails.id);
    return ProductDetailsWrapper(
      productDetails: productDetails,
      isAvailableForPurchase: option.isAvailableForPurchase(user),
      productOption: option,
    );
  }

  String get id => productDetails.id;
  String get price => productDetails.price;
  bool get isConsumable => productOption.isConsumable;
  String get name => productOption.name;

  @override
  int compareTo(other) {
    return productOption.index.compareTo(other.productOption.index);
  }
}
