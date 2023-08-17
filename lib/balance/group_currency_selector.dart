import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/currency_picker_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GroupCurrencySelector extends StatefulWidget {
  final String selectedCurrency;
  final Function(String)? onCurrencyChange;
  const GroupCurrencySelector({required this.selectedCurrency, this.onCurrencyChange});

  @override
  State<GroupCurrencySelector> createState() => _GroupCurrencySelectorState();
}

class _GroupCurrencySelectorState extends State<GroupCurrencySelector> {
  late String _selectedCurrency;
  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.selectedCurrency;
    print('asdasd');
  }


  @override
  void didUpdateWidget(covariant GroupCurrencySelector oldWidget) {
    _selectedCurrency = widget.selectedCurrency;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppStateProvider, Group>(
      selector: (context, userProvider) => userProvider.currentGroup!,
      builder: (context, currentGroup, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.secondaryContainer
              ),
              width: 80,
              child: CurrencyPickerDropdown(
                currencyChanged: (newCurrency) {
                  widget.onCurrencyChange!(newCurrency);
                  setState(() => _selectedCurrency = newCurrency);
                },
                defaultCurrencyValue: _selectedCurrency,
                showSymbol: false,
                textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                dropdownColor: Theme.of(context).colorScheme.secondaryContainer,
              ),
            ),
          ],
        );
      }
    );
  }
}
