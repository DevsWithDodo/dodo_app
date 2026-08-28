import 'package:csocsort_szamla/components/helpers/currency_picker_sheet.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../helpers/currencies.dart';

class CurrencyPickerIconButton extends StatefulWidget {
  final Currency selectedCurrency;
  final Function(Currency?) onCurrencyChanged;

  const CurrencyPickerIconButton(
      {super.key,
      required this.selectedCurrency,
      required this.onCurrencyChanged});

  @override
  State<CurrencyPickerIconButton> createState() =>
      _CurrencyPickerIconButtonState();
}

class _CurrencyPickerIconButtonState extends State<CurrencyPickerIconButton> {
  @override
  Widget build(BuildContext context) {
    Currency groupCurrency =
        context.watch<UserNotifier>().currentGroup!.currency;
    return IconButton.filledTonal(
      isSelected: widget.selectedCurrency != groupCurrency,
      onPressed: () {
        showCurrencyPickerSheet(
          context,
          currency: widget.selectedCurrency,
          onCurrencySelected: widget.onCurrencyChanged,
          defaultCurrencyFrom: DefaultCurrencyFrom.group,
        );
      },
      icon: Container(
        constraints: BoxConstraints(maxWidth: 15),
        child: FittedBox(
          fit: BoxFit.fitWidth,
          child: Text(
            widget.selectedCurrency.symbol,
            style:
                Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
