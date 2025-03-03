import 'dart:async';

import 'package:collection/collection.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/user_settings/components/payment_method_field.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaymentMethodFieldList extends StatefulWidget {
  final void Function(List<PaymentMethod>) onSubmit;

  const PaymentMethodFieldList({super.key, required this.onSubmit});

  @override
  State<PaymentMethodFieldList> createState() => _PaymentMethodFieldListState();
}

class _PaymentMethodFieldListState extends State<PaymentMethodFieldList> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late List<PaymentMethodFieldModel> paymentMethods;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    paymentMethods = context.read<UserState>().user!.paymentMethods.map((paymentMethod) => PaymentMethodFieldModel.fromPaymentMethod(paymentMethod)).sorted(compare).toList();
  }

  int compare(PaymentMethodFieldModel a, PaymentMethodFieldModel b) {
    if (a.saved && b.saved) {
      return a.priority
          ? -1
          : b.priority
              ? 1
              : 0;
    } else if (a.saved) {
      return -1;
    } else if (b.saved) {
      return 1;
    } else {
      return 0;
    }
  }

  void onTimerEnd() {
    final validPaymentMethods = paymentMethods
        .where(
          (paymentMethod) => paymentMethod.valueController.text.isNotEmpty && paymentMethod.nameController.text.isNotEmpty,
        )
        .toList();
    widget.onSubmit(validPaymentMethods
        .map((paymentMethod) => PaymentMethod(
              name: paymentMethod.nameController.text,
              value: paymentMethod.valueController.text,
              priority: paymentMethod.priority,
            ))
        .toList());
    setState(() {
      for (var paymentMethod in validPaymentMethods) {
        paymentMethod.saved = true;
      }
      paymentMethods.sort(compare);
    });
    timer = null;
  }

  void addPaymentMethod() => setState(() {
        paymentMethods.add(PaymentMethodFieldModel.empty());
      });

  void Function() removePaymentMethod(PaymentMethodFieldModel paymentMethod) => () {
        setTimer(true);
        setState(() {
          paymentMethods.remove(paymentMethod);
        });
      };

  void Function() setPriority(PaymentMethodFieldModel paymentMethod) => () {
        setTimer();
        setState(() {
          paymentMethod.priority = !paymentMethod.priority;
        });
      };

  void setTimer([bool fast = false]) {
    timer?.cancel();
    timer = Timer(fast ? Duration(milliseconds: 300) : Duration(seconds: 1), onTimerEnd);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          if (paymentMethods.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'payment-methods.no-payment-methods'.tr(),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          Column(
            children: paymentMethods
                .map((paymentMethod) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PaymentMethodField(
                        paymentMethod: paymentMethod,
                        onRemove: removePaymentMethod(paymentMethod),
                        onPriorityChange: setPriority(paymentMethod),
                        onTextChange: setTimer,
                      ),
                    ))
                .toList(),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: GradientButton.icon(
                label: Text('payment-methods.add-new'.tr()),
                icon: Icon(Icons.add),
                onPressed: addPaymentMethod,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentMethodFieldModel {
  TextEditingController nameController = TextEditingController();
  TextEditingController valueController = TextEditingController();
  bool hasError;
  bool priority;
  bool saved;

  PaymentMethodFieldModel({
    required this.nameController,
    required this.valueController,
    required this.priority,
    required this.saved,
    this.hasError = false,
  });

  factory PaymentMethodFieldModel.empty() => PaymentMethodFieldModel(
        nameController: TextEditingController(),
        valueController: TextEditingController(),
        priority: false,
        saved: false,
      );

  factory PaymentMethodFieldModel.fromPaymentMethod(PaymentMethod paymentMethod) => PaymentMethodFieldModel(
        nameController: TextEditingController(text: paymentMethod.name),
        valueController: TextEditingController(text: paymentMethod.value),
        priority: paymentMethod.priority,
        saved: true,
      );
}
