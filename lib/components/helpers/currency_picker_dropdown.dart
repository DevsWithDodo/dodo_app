import 'package:flutter/material.dart';
import '../../helpers/currencies.dart';

class CurrencyPickerDropdown extends StatelessWidget {
  final Currency? currency;
  final ValueChanged<Currency> currencyChanged;
  final bool showSymbol;
  final Color? dropdownColor;
  final Color? textColor;
  final Color? backgroundColor;
  CurrencyPickerDropdown({
    required this.currency,
    required this.currencyChanged,
    this.showSymbol = true,
    this.textColor,
    this.dropdownColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.only(right: 5),
      child: DropdownButton(
        isExpanded: true,
        iconEnabledColor: textColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
        onChanged: (String? value) {
          if (value == null) {
            return;
          }
          currencyChanged(Currency.fromCode(value));
        },
        value: currency?.code,
        borderRadius: BorderRadius.circular(12),
        underline: Container(),
        dropdownColor: dropdownColor ??
            ElevationOverlay.applySurfaceTint(
                Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surfaceTint, 10),
        style: Theme.of(context)
            .textTheme
            .labelLarge!
            .copyWith(color: textColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
        menuMaxHeight: 500,
        items: Currency.all()
            .map((currency) => DropdownMenuItem(
                  alignment: Alignment.center,
                  child: Text(
                    currency.code + (showSymbol ? (" (${currency.symbol})") : ""),
                  ),
                  value: currency.code,
                ))
            .toList(),
      ),
    );
  }
}
