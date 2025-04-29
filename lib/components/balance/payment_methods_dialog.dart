import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/components/helpers/member_payment_methods.dart';
import 'package:csocsort_szamla/pages/app/payment_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PaymentMethodsDialog extends StatelessWidget {
  final Member taker;
  final int payerId;

  const PaymentMethodsDialog({super.key, required this.taker, required this.payerId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'payment-methods.dialog.title'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 5),
              Text(
                'payment-methods.dialog.subtitle'.tr(namedArgs: {
                  'name': taker.nickname
                }),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 25),
              Container(
                constraints: BoxConstraints(maxWidth: 350),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10)
                ),
                padding: EdgeInsets.all(5),
                child: MemberPaymentMethods(member: taker),
              ),
              SizedBox(height: 25),
              Text("Already paid?", style: context.textTheme.titleSmall),
              SizedBox(height: 5),
              GradientButton.icon(
                icon: Icon(Icons.payment),
                label: Text('Record payment'.tr()),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PaymentPage(payerId: payerId, takerId: taker.id))
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
