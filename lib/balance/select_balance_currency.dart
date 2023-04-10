import 'package:csocsort_szamla/essentials/widgets/currency_picker_dropdown.dart';
import 'package:flutter/material.dart';

import '../config.dart';

class SelectBalanceCurrency extends StatefulWidget {
  final String? selectedCurrency;
  final Function(String?)? onCurrencyChange;
  const SelectBalanceCurrency({this.selectedCurrency, this.onCurrencyChange});

  @override
  State<SelectBalanceCurrency> createState() => _SelectBalanceCurrencyState();
}

class _SelectBalanceCurrencyState extends State<SelectBalanceCurrency> {
  String? _selectedCurrency;
  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.selectedCurrency;
  }

  @override
  void didUpdateWidget(covariant SelectBalanceCurrency oldWidget) {
    _selectedCurrency = widget.selectedCurrency;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onDoubleTap: () {
            _selectedCurrency = currentGroupCurrency;
            widget.onCurrencyChange!(_selectedCurrency);
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _selectedCurrency != currentGroupCurrency
                  ? Theme.of(context).colorScheme.tertiaryContainer
                  : ElevationOverlay.applyOverlay(
                      context, Theme.of(context).colorScheme.surface, 10),
            ),
            width: 80,
            child: CurrencyPickerDropdown(
              currencyChanged: (newCurrency) {
                _selectedCurrency = newCurrency;
                widget.onCurrencyChange!(newCurrency);
              },
              defaultCurrencyValue: _selectedCurrency,
              filled: false,
              noContentPadding: true,
              showSymbol: false,
              textColor: widget.selectedCurrency != currentGroupCurrency
                  ? Theme.of(context).colorScheme.onTertiaryContainer
                  : null,
              dropdownColor: widget.selectedCurrency != currentGroupCurrency
                  ? Theme.of(context).colorScheme.tertiaryContainer
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
