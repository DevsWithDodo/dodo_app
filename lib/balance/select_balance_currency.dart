import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/currency_picker_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectBalanceCurrency extends StatelessWidget {
  final String selectedCurrency;
  final Function(String) onCurrencyChange;
  const SelectBalanceCurrency(
      {required this.selectedCurrency, required this.onCurrencyChange});

  @override
  Widget build(BuildContext context) {
    return Selector<AppStateProvider, Group>(
        selector: (context, userProvider) => userProvider.currentGroup!,
        builder: (context, currentGroup, _) {
          return CurrencyPickerDropdown(
            currencyChanged: (newCurrency) {
              onCurrencyChange(newCurrency);
            },
            defaultCurrencyValue: selectedCurrency,
            showSymbol: false,
            textColor: selectedCurrency != currentGroup.currency
                ? Theme.of(context).colorScheme.onTertiaryContainer
                : null,
            dropdownColor:
                selectedCurrency != currentGroup.currency
                    ? Theme.of(context).colorScheme.tertiaryContainer
                    : null,
            backgroundColor: selectedCurrency != currentGroup.currency
                ? Theme.of(context).colorScheme.tertiaryContainer
                : null,
          );
        });
  }
}
