import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/payment/payment_entry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PaymentsNeededDialog extends StatefulWidget {
  final List<Payment> payments;
  final Function onPaymentsPosted;

  const PaymentsNeededDialog({
    required this.payments,
    required this.onPaymentsPosted,
    super.key,
  });

  @override
  State<PaymentsNeededDialog> createState() => _PaymentsNeededDialogState();
}

class _PaymentsNeededDialogState extends State<PaymentsNeededDialog> {
  Future<bool> _postPayment(double amount, String note, int? takerId) async {
    try {
      Map<String, dynamic> body = {
        'group': currentGroupId,
        'amount': amount,
        'note': note,
        'taker_id': takerId
      };

      await httpPost(uri: '/payments', body: body, context: context);
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
    widget.onPaymentsPosted();
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
                  child: Text(
                    'back'.tr(),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
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
                            dataTrueText: 'payment_scf',
                            onDataTrue: () {
                              _onPostPayments();
                            },
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
