import 'package:csocsort_szamla/helpers/amount_division.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAmountField extends StatelessWidget {
  final PurchaseReceiver amount;
  final Currency currency;
  final FocusNode percentageNode = FocusNode();
  final FocusNode customAmountNode = FocusNode();
  CustomAmountField({
    super.key,
    required this.amount,
    required this.currency,
  }) {
    percentageNode.addListener(() {
      if (!percentageNode.hasFocus) {
        amount.handleSetPercentage();
      }
    });
    customAmountNode.addListener(() {
      if (!customAmountNode.hasFocus) {
        amount.handleSetAmount();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 80,
            child: Text(
              amount.memberNickname,
              style: Theme.of(context).textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 10),
          Container(
            width: 70,
            child: TextField(
              focusNode: percentageNode,
              controller: amount.percentageController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                suffixText: '%',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9]'))
              ],
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              focusNode: customAmountNode,
              controller: amount.customAmountController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                suffixText: currency.symbol,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9\\.\\,]'))
              ],
            ),
          ),
          if (amount.isCustomAmount)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                onPressed: amount.resetCustom,
                icon: Icon(Icons.restart_alt),
              ),
            ),
        ],
      ),
    );
  }
}