import 'package:flutter/material.dart';

import '../../helpers/currencies.dart';

class CurrencyPickerDropdown extends StatelessWidget {
  final Currency? currency;
  final ValueChanged<Currency> currencyChanged;
  final bool showSymbol;
  final Color? dropdownColor;
  final Color? textColor;
  final Color? backgroundColor;
  final bool isDense;
  const CurrencyPickerDropdown({
    super.key,
    required this.currency,
    required this.currencyChanged,
    this.showSymbol = true,
    this.textColor,
    this.dropdownColor,
    this.backgroundColor,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
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
          isDense: isDense,
          padding: isDense ? EdgeInsets.symmetric(vertical: 5) : null,
          items: Currency.all()
              .map((currency) => DropdownMenuItem(
                    alignment: Alignment.center,
                    value: currency.code,
                    child: Text(
                      currency.code + (showSymbol ? (" (${currency.symbol})") : ""),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
