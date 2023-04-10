import 'package:flutter/material.dart';
import '../currencies.dart';

class CurrencyPickerDropdown extends StatefulWidget {
  final String? defaultCurrencyValue;
  final ValueChanged<String> currencyChanged;
  final bool filled;
  final bool noContentPadding;
  final bool showSymbol;
  final Color? dropdownColor;
  final Color? textColor;
  CurrencyPickerDropdown({
    required this.defaultCurrencyValue,
    required this.currencyChanged,
    this.filled = true,
    this.noContentPadding = false,
    this.showSymbol = true,
    this.textColor,
    this.dropdownColor,
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
    return ButtonTheme(
      alignedDropdown: true,
      child: DropdownButtonFormField(
        decoration: InputDecoration(
            filled: widget.filled,
            contentPadding:
                widget.noContentPadding ? EdgeInsets.only(top: 0) : null),
        elevation: 0,
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
        dropdownColor: ElevationOverlay.applySurfaceTint(
            widget.dropdownColor ?? Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceTint,
            2),
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
            color: widget.textColor ??
                Theme.of(context).colorScheme.onSurfaceVariant),
        menuMaxHeight: 500,
        items: enumerateCurrencies()
            .map((currency) => DropdownMenuItem(
                  child: Center(
                    child: Text(
                      currency.split(';')[0].trim() +
                          (widget.showSymbol
                              ? (" (" + currency.split(';')[1].trim() + ")")
                              : ""),
                    ),
                  ),
                  value: currency.split(';')[0].trim(),
                  onTap: () {},
                ))
            .toList(),
      ),
    );
  }
}
