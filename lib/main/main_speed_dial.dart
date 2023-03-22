import 'package:csocsort_szamla/payment/add_payment_page.dart';
import 'package:csocsort_szamla/purchase/add_purchase_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'package:csocsort_szamla/purchase/add_modify_purchase.dart';

class MainPageSpeedDial extends StatefulWidget {
  final Function onReturn;
  MainPageSpeedDial({this.onReturn});
  @override
  _MainPageSpeedDialState createState() => _MainPageSpeedDialState();
}

class _MainPageSpeedDialState extends State<MainPageSpeedDial> {
  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      foregroundColor: Theme.of(context).colorScheme.onTertiary,
      child: Icon(Icons.add),
      overlayColor: (Theme.of(context).brightness == Brightness.dark) ? Colors.black : Colors.white,
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          elevation: 0,
          foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          labelWidget: Padding(
            padding: EdgeInsets.only(right: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  height: 20,
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 3.0, horizontal: 5.0),
                  //                  margin: EdgeInsets.only(right: 18.0),
                  decoration: BoxDecoration(
                    // gradient: AppTheme.gradientFromTheme(Theme.of(context)),
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.all(Radius.circular(6.0)),
                  ),
                  child: Text('payment'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onTertiaryContainer, fontSize: 18)),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  'payment_explanation'.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          child: Icon(Icons.payments),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AddPaymentRoute()))
                .then((value) => widget.onReturn());
          },
        ),
        SpeedDialChild(
            elevation: 0,
            foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            labelWidget: Padding(
              padding: EdgeInsets.only(right: 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 3.0, horizontal: 5.0),
                    decoration: BoxDecoration(
                      // gradient: AppTheme.gradientFromTheme(Theme.of(context)),
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.all(Radius.circular(6.0)),
                    ),
                    child: Text('purchase'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                            fontSize: 18)),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    'purchase_explanation'.tr(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            child: Icon(
              Icons.shopping_cart,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPurchaseRoute(
                    type: PurchaseType.newPurchase,
                  ),
                ),
              ).then((value) {
                widget.onReturn();
              });
            }),
      ],
    );
  }
}
