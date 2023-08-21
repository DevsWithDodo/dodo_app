import 'dart:convert';

import 'package:csocsort_szamla/essentials/event_bus.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/user_settings/components/payment_method_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaymentMethods extends StatelessWidget  {
  const PaymentMethods({super.key});

  Future<BoolFutureOutput> _updatePaymentMethods(List<PaymentMethod> paymentMethods, BuildContext context) async {
    try {
      Map<String, dynamic> body = {
        "payment_details":
            jsonEncode(paymentMethods.map((e) => e.toJson()).toList())
      };

      await Http.put(uri: '/user', body: body);
      context.read<AppStateProvider>().setPaymentMethods(paymentMethods);
      EventBus.instance.fire(EventBus.refreshBalances);
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Text(
                'payment-methods.title'.tr(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                'payment-methods.subtitle'.tr(),
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            PaymentMethodList(
              key: UniqueKey(),
              onSubmit: (paymentMethods) {
                showFutureOutputDialog(
                  context: context,
                  future: _updatePaymentMethods(paymentMethods, context),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
