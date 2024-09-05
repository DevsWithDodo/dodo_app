import 'package:csocsort_szamla/helpers/amount_division.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAmountField extends StatefulWidget {
  final PurchaseReceiver amount;
  final Currency currency;

  CustomAmountField({
    super.key,
    required this.amount,
    required this.currency,
  });

  @override
  State<CustomAmountField> createState() => _CustomAmountFieldState();
}

class _CustomAmountFieldState extends State<CustomAmountField> {
  final FocusNode percentageNode = FocusNode();

  final FocusNode customAmountNode = FocusNode();

  @override
  void initState() {
    super.initState();
    percentageNode.addListener(() {
      if (!percentageNode.hasFocus) {
        widget.amount.handleSetPercentage();
      }
    });
    customAmountNode.addListener(() {
      if (!customAmountNode.hasFocus) {
        widget.amount.handleSetAmount();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    percentageNode.dispose();
    customAmountNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                child: Text(
                  widget.amount.memberNickname,
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 10),
              Container(
                width: 70,
                child: TextField(
                  focusNode: percentageNode,
                  controller: widget.amount.percentageController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    suffixText: '%',
                    error: widget.amount.error ? Container() : null,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isNotEmpty && double.parse(newValue.text) > 100) {
                        return TextEditingValue(
                          text: '100',
                          selection: TextSelection.collapsed(offset: 3),
                        );
                      }
                      return newValue;
                    }),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  focusNode: customAmountNode,
                  controller: widget.amount.customAmountController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    suffixText: widget.currency.symbol,
                    error: widget.amount.error ? Container() : null,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9\\.\\,]'))],
                ),
              ),
              if (widget.amount.isCustomAmount)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    onPressed: widget.amount.resetCustom,
                    icon: Icon(Icons.restart_alt),
                  ),
                ),
            ],
          ),
          if (widget.amount.error)
            Padding(
              padding: const EdgeInsets.only(left: 93, top: 3.0),
              child: Text(
                'custom-amount-field.error'.tr(),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
