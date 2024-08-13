import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/necessary_payments.dart';
import 'package:csocsort_szamla/pages/app/necessary_payments_page.dart';
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
        .where((payment) => payment.amount > payment.originalCurrency.threshold())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _necessaryPayments.isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NecessaryPaymentsPage(
                necessaryPayments: _necessaryPayments,
                members: widget.members,
              ),
            ),
          ),
          label: Text('payments_needed'.tr()),
          icon: Icon(Icons.paid_outlined),
        ),
      ),
    );
  }
}
