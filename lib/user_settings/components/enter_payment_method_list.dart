import 'package:collection/collection.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/user_settings/components/enter_payment_method_list_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EnterPaymentMethodList extends StatelessWidget {
  final void Function(List<PaymentMethod>) onSubmit;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  EnterPaymentMethodList({super.key, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ChangeNotifierProvider(
        create: (context) => PaymentMethodProvider(
          paymentMethods: context
              .read<AppStateProvider>()
              .user!
              .paymentMethods
              .map((paymentMethod) => paymentMethod.clone())
              .toList(),
        ),
        builder: (context, _) {
          return Consumer<PaymentMethodProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  Column(
                    children: provider.paymentMethods
                        .sorted((a, b) => a.priority ? -1 : 1)
                        .map((paymentMethod) => Padding(
                              key: UniqueKey(),
                              padding: const EdgeInsets.only(bottom: 10),
                              child: EnterPaymentMethodListItem(
                                paymentMethod: paymentMethod,
                              ),
                            ))
                        .toList(),
                  ),
                  EnterPaymentMethodListItem(
                    key: UniqueKey(),
                  ),
                  Visibility(
                    visible: provider.paymentMethods.isNotEmpty ||
                        context.watch<AppStateProvider>().user!.paymentMethods.isNotEmpty,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: GradientButton(
                        child: Icon(Icons.save),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            onSubmit(provider.paymentMethods);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class PaymentMethodProvider extends ChangeNotifier {
  List<PaymentMethod> paymentMethods;
  PaymentMethodProvider({required this.paymentMethods});

  void addPaymentMethod(String name, String value, bool priority) {
    paymentMethods.add(PaymentMethod(
      name: name,
      value: value,
      priority: priority,
    ));
    notifyListeners();
  }

  void setName(PaymentMethod paymentMethod, String name) {
    paymentMethod.name = name;
  }

  void setValue(PaymentMethod paymentMethod, String value) {
    paymentMethod.value = value;
  }

  void setPriority(PaymentMethod paymentMethod, bool priority) {
    paymentMethod.priority = priority;
    notifyListeners();
  }

  void removePaymentMethod(PaymentMethod paymentMethod) {
    paymentMethods.remove(paymentMethod);
    notifyListeners();
  }
}
