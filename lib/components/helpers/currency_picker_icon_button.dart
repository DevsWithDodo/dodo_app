import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/components/helpers/currency_picker_dropdown.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../helpers/currencies.dart';

class CurrencyPickerIconButton extends StatefulWidget {
  final Currency selectedCurrency;
  final Function(Currency?) onCurrencyChanged;

  const CurrencyPickerIconButton(
      {required this.selectedCurrency, required this.onCurrencyChanged});

  @override
  State<CurrencyPickerIconButton> createState() =>
      _CurrencyPickerIconButtonState();
}

class _CurrencyPickerIconButtonState extends State<CurrencyPickerIconButton> {
  @override
  Widget build(BuildContext context) {
    Currency groupCurrency = context.watch<UserState>().currentGroup!.currency;
    return IconButton.filledTonal(
      isSelected: widget.selectedCurrency != groupCurrency,
      onPressed: () {
        showDialog<Currency>(
            context: context,
            builder: (context) {
              return Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CurrencyPickerDropdown(
                        currency: widget.selectedCurrency,
                        currencyChanged: (newCurrency) {
                          Navigator.pop(context, newCurrency);
                        },
                      ),
                      Visibility(
                        visible: widget.selectedCurrency != groupCurrency,
                        child: Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: TextButton.icon(onPressed: () {
                            Navigator.pop(context, groupCurrency);
                          }, icon: Icon(Icons.undo), label: Text('reset'.tr()),),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }).then((newCurrency) => widget.onCurrencyChanged(newCurrency));
      },
      icon: Container(
        constraints: BoxConstraints(maxWidth: 15),
        child: FittedBox(
          fit: BoxFit.fitWidth,
          child: Text(
            widget.selectedCurrency.symbol,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                fontSize: 18),
          ),
        ),
      ),
    );
  }
}
