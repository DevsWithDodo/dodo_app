import 'dart:convert';

import 'package:csocsort_szamla/components/user_settings/components/payment_method_field_list.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/payment_method_list_extension.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum LoadingState {
  loading,
  ready,
  done,
}

class PaymentMethods extends StatefulWidget {
  const PaymentMethods({super.key});

  @override
  State<PaymentMethods> createState() => _PaymentMethodsState();
}

class _PaymentMethodsState extends State<PaymentMethods> {
  LoadingState loading = LoadingState.done;

  Future _updatePaymentMethods(List<PaymentMethod> paymentMethods) async {
    if (paymentMethods.hasSameElementsInOrder(context.read<UserState>().user!.paymentMethods)) {
      return;
    }
    try {
      setState(() => loading = LoadingState.loading);
      Map<String, dynamic> body = {"payment_details": jsonEncode(paymentMethods.map((e) => e.toJson()).toList())};

      await Http.put(uri: '/user', body: body);
      if (mounted) {
        context.read<UserState>().setPaymentMethods(paymentMethods);
        EventBus.instance.fire(EventBus.refreshBalances);
        EventBus.instance.fire(EventBus.refreshGroupMembers);
        await Future.delayed(Duration(milliseconds: 500));
        setState(() => loading = LoadingState.ready);
        await Future.delayed(Duration(milliseconds: 500));
      }
    } catch (_) {
      rethrow;
    } finally {
      setState(() => loading = LoadingState.done);
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
                style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                'payment-methods.subtitle'.tr(),
                style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            Visibility(
              visible: loading != LoadingState.done,
              maintainAnimation: true,
              maintainState: true,
              maintainSize: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    loading == LoadingState.loading
                        ? SizedBox.fromSize(
                            size: Size.square(18),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 10),
                    Text('payment-methods.save.${loading.name}'.tr(), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            // SizedBox(height: 10),
            PaymentMethodFieldList(onSubmit: _updatePaymentMethods),
          ],
        ),
      ),
    );
  }
}
