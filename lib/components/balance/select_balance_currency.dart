import 'package:csocsort_szamla/components/helpers/currency_picker_dropdown.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectBalanceCurrency extends StatelessWidget {
  final Currency selectedCurrency;
  final ValueChanged<Currency> onCurrencyChanged;
  const SelectBalanceCurrency({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<UserNotifier, Group>(
        selector: (context, userProvider) => userProvider.currentGroup!,
        builder: (context, currentGroup, _) {
          return CurrencyPickerDropdown(
            isDense: true,
            currencyChanged: onCurrencyChanged,
            currency: selectedCurrency,
            showSymbol: false,
            textColor: selectedCurrency != currentGroup.currency ? Theme.of(context).colorScheme.onTertiaryContainer : null,
            dropdownColor: selectedCurrency != currentGroup.currency ? Theme.of(context).colorScheme.tertiaryContainer : null,
            backgroundColor: selectedCurrency != currentGroup.currency ? Theme.of(context).colorScheme.tertiaryContainer : null,
          );
        });
  }
}
