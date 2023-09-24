import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/components/helpers/member_payment_methods.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PaymentMethodsDialog extends StatelessWidget {
  final Member member;
  const PaymentMethodsDialog({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                'payment-methods.dialog.subtitle'.tr(),
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 25),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 350),
                child: MemberPaymentMethods(member: member),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
