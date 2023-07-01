import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/providers/event_bus_provider.dart';
import 'package:csocsort_szamla/essentials/providers/user_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/payment/payment_entry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:event_bus_plus/event_bus_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaymentsNeededDialog extends StatefulWidget {
  final List<Payment> payments;

  const PaymentsNeededDialog({
    required this.payments,
    super.key,
  });

  @override
  State<PaymentsNeededDialog> createState() => _PaymentsNeededDialogState();
}

class _PaymentsNeededDialogState extends State<PaymentsNeededDialog> {
  Future<bool> _postPayment(double amount, String note, int? takerId) async {
    try {
      Map<String, dynamic> body = {
        'group': context.read<UserProvider>().user!.group!.id,
        'amount': amount,
        'note': note,
        'taker_id': takerId
      };

      await Http.post(uri: '/payments', body: body);
      return true;
    } catch (_) {
      throw _;
    }
  }

  Future<bool> _postPayments(List<Payment> payments) async {
    for (Payment payment in payments) {
      if (await _postPayment(
          payment.amount * 1.0, '\$\$auto_payment\$\$'.tr(), payment.takerId)) {
        continue;
      }
    }
    Future.delayed(delayTime()).then((value) => _onPostPayments());
    return true;
  }

  void _onPostPayments() {
    Navigator.pop(context);
    Navigator.pop(context);
    final bus = context.read<EventBus>();
    bus.fire(RefreshPayments(context));
    bus.fire(RefreshBalances(context));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'payments_needed'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(
              height: 10,
            ),
            ListView(
              shrinkWrap: true,
              children: widget.payments.map<Widget>((Payment payment) {
                return PaymentEntry(
                  payment: payment,
                  isTappable: false,
                );
              }).toList(),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: widget.payments.length > 0
                  ? MainAxisAlignment.spaceAround
                  : MainAxisAlignment.center,
              children: [
                GradientButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('back'.tr()),
                ),
                Visibility(
                  maintainSize: false,
                  maintainState: false,
                  maintainAnimation: false,
                  maintainSemantics: false,
                  replacement: SizedBox(
                    height: 0,
                  ),
                  visible: widget.payments.length > 0,
                  child: GradientButton(
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) {
                          return FutureSuccessDialog(
                            future: _postPayments(widget.payments),
                          );
                        },
                      );
                    },
                    child: Text(
                      'pay'.tr(),
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
