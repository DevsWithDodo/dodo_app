import 'package:csocsort_szamla/pages/app/payment_page.dart';
import 'package:csocsort_szamla/pages/app/purchase_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class MainPageSpeedDial extends StatefulWidget {
  final Function? onReturn;
  const MainPageSpeedDial({super.key, this.onReturn});
  @override
  State<MainPageSpeedDial> createState() => _MainPageSpeedDialState();
}

class _MainPageSpeedDialState extends State<MainPageSpeedDial> {
  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      spacing: 10,
      label: Text('new-expense'.tr()),
      icon: Icons.add,
      curve: Curves.bounceIn,
      children: [
        MainSpeedDialChild(
          context,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PaymentPage()),
            );
            widget.onReturn?.call();
          },
          label: 'speed-dial.payment',
          icon: Icons.payments,
        ),
        MainSpeedDialChild(
          context,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PurchasePage(),
              ),
            );
            widget.onReturn?.call();
          },
          label: 'speed-dial.purchase',
          icon: Icons.shopping_cart,
        ),
      ],
    );
  }
}

class MainSpeedDialChild extends SpeedDialChild {
  MainSpeedDialChild(
    BuildContext context, {
    required VoidCallback onTap,
    required String label,
    required IconData icon,
  }) : super(
          foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          elevation: 2,
          child: Icon(icon),
          labelWidget: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label.tr(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '$label.description'.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              ],
            ),
          ),
          onTap: onTap,
        );
}
