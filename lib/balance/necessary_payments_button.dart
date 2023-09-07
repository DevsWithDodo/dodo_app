import 'package:csocsort_szamla/balance/necessary_payments_dialog.dart';
import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/payments_needed.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NecessaryPaymentsButton extends StatefulWidget {
  const NecessaryPaymentsButton({super.key, required this.members});

  final List<Member> members;

  @override
  State<NecessaryPaymentsButton> createState() => _NecessaryPaymentsButtonState();
}

class _NecessaryPaymentsButtonState extends State<NecessaryPaymentsButton> {
  late List<Payment> _necessaryPayments;

  @override
  void initState() {
    super.initState();
    _necessaryPayments = necessaryPayments(widget.members, context)
        .where((payment) => payment.amount > Currency.threshold(payment.originalCurrency))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _necessaryPayments.isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: TextButton(
          onPressed: () => showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => NecessaryPaymentsDialog(
              necessaryPayments: _necessaryPayments,
              members: widget.members,
            ),
          ),
          child: Text('payments_needed'.tr()),
        ),
      ),
    );
  }
}
