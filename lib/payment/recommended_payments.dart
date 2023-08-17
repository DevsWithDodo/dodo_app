import 'package:collection/collection.dart';
import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/payments_needed.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class RecommendedPayments extends StatefulWidget {
  final List<Member> members;
  final void Function(Payment selectedPayment, bool selected) onChange;
  const RecommendedPayments(
      {super.key, required this.members, required this.onChange});

  @override
  State<RecommendedPayments> createState() => _RecommendedPaymentsState();
}

class _RecommendedPaymentsState extends State<RecommendedPayments> {
  int? _selectedPayment = null;
  late final List<Payment> _necessaryPayments;

  @override
  void initState() {
    super.initState();
    _necessaryPayments = necessaryPayments(widget.members, context);
  }

  @override
  Widget build(BuildContext context) {
        necessaryPayments(widget.members, context);
    return Container(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'payments.recommended-payments'.tr(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            ..._necessaryPayments.mapIndexed(
              (index, payment) {
                bool selected = _selectedPayment == index;
                ThemeData themeData = Theme.of(context);
                TextStyle textStyle = themeData.textTheme.bodyLarge!.copyWith(
                    color: selected
                        ? themeData.colorScheme.onPrimaryContainer
                        : themeData.colorScheme.onSecondaryContainer);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ChoiceChip(
                    side: BorderSide.none,
                    labelStyle: textStyle,
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    selected: selected,
                    onSelected: (value) {
                      widget.onChange(payment, value);
                      setState(() {
                        _selectedPayment = value ? index : null;
                      });
                    },
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(payment.takerNickname),
                        SizedBox(width: 5),
                        Text(
                          payment.amount.toMoneyString(payment.originalCurrency,
                              withSymbol: true),
                        )
                      ],
                    ),
                  ),
                );
              },
            ).toList()
          ],
        ),
      ),
    );
  }
}
