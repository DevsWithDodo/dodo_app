import 'package:flutter/material.dart';
import '../../helpers/currencies.dart';

class CurrencyPickerDropdown extends StatefulWidget {
  final String? defaultCurrencyValue;
  final ValueChanged<String> currencyChanged;
  final bool showSymbol;
  final Color? dropdownColor;
  final Color? textColor;
  final Color? backgroundColor;
  CurrencyPickerDropdown({
    required this.defaultCurrencyValue,
    required this.currencyChanged,
    this.showSymbol = true,
    this.textColor,
    this.dropdownColor,
    this.backgroundColor,
  });

  @override
  State<CurrencyPickerDropdown> createState() => _CurrencyPickerDropdownState();
}

class _CurrencyPickerDropdownState extends State<CurrencyPickerDropdown> {
  String? _defaultCurrencyValue;

  @override
  void initState() {
    super.initState();
    _defaultCurrencyValue = widget.defaultCurrencyValue;
  }

  @override
  Widget build(BuildContext context) {
    _defaultCurrencyValue = widget.defaultCurrencyValue;
    return Ink(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.only(right: 5),
      child: DropdownButton(
        isExpanded: true,
        iconEnabledColor:
            widget.textColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
        onChanged: (String? value) {
          if (value == null) {
            return;
          }
          widget.currencyChanged(value);
          setState(() {
            _defaultCurrencyValue = value;
          });
        },
        value: _defaultCurrencyValue,
        borderRadius: BorderRadius.circular(12),
        underline: Container(),
        dropdownColor:
            widget.dropdownColor ?? ElevationOverlay.applySurfaceTint(Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surfaceTint, 10),
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
            color: widget.textColor ??
                Theme.of(context).colorScheme.onSurfaceVariant),
        menuMaxHeight: 500,
        items: Currency.enumerateCurrencies()
            .map((currency) => DropdownMenuItem(
                  alignment: Alignment.center,
                  child: Text(
                    currency.split(';')[0].trim() +
                        (widget.showSymbol
                            ? (" (${currency.split(';')[1].trim()})")
                            : ""),
                  ),
                  value: currency.split(';')[0].trim(),
                  onTap: () {},
                ))
            .toList(),
      ),
    );
  }
}
