import 'package:csocsort_szamla/components/helpers/currency_picker_button.dart';
import 'package:csocsort_szamla/components/helpers/currency_picker_sheet.dart';
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
          return SizedBox(
            width: 70,
            child: CurrencyPickerButton(
              selectedCurrency: selectedCurrency,
              onCurrencyChanged: onCurrencyChanged,
              defaultCurrencyFrom: DefaultCurrencyFrom.group,
            ),
          );
        });
  }
}
