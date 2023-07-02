import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/currency_picker_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../currencies.dart';

class CurrencyPickerIconButton extends StatefulWidget {
  final String? selectedCurrency;
  final Function(String?)? onCurrencyChanged;

  const CurrencyPickerIconButton(
      {this.selectedCurrency, this.onCurrencyChanged});

  @override
  State<CurrencyPickerIconButton> createState() =>
      _CurrencyPickerIconButtonState();
}

class _CurrencyPickerIconButtonState extends State<CurrencyPickerIconButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: CurrencyPickerDropdown(
                    defaultCurrencyValue: widget.selectedCurrency,
                    currencyChanged: (newCurrency) {
                      Navigator.pop(context, newCurrency);
                    },
                  ),
                ),
              );
            }).then((newCurrency) => widget.onCurrencyChanged!(newCurrency));
      },
      icon: Container(
        constraints: BoxConstraints(maxWidth: 15),
        child: FittedBox(
          fit: BoxFit.fitWidth,
          child: Text(
            getSymbol(widget.selectedCurrency!)!,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: widget.selectedCurrency == context.watch<AppStateProvider>().currentGroup!.currency
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.tertiary,
                fontSize: 18),
          ),
        ),
      ),
    );
  }
}
