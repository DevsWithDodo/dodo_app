import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/components/helpers/currency_picker_sheet.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class CurrencyPickerButton extends HookWidget {
  const CurrencyPickerButton(
      {super.key,
      required this.selectedCurrency,
      required this.onCurrencyChanged,
      required this.defaultCurrencyFrom});
  final Currency selectedCurrency;
  final void Function(Currency currency) onCurrencyChanged;
  final DefaultCurrencyFrom defaultCurrencyFrom;
  @override
  Widget build(BuildContext context) {
    final userNotifier = context.watch<UserNotifier>();
    final groupCurrency = useMemoized(() => userNotifier.currentGroup?.currency, [userNotifier.currentGroup]);
    final userCurrency = useMemoized(() => userNotifier.user?.currency, [userNotifier.user]);
    final defaultCurrency = useMemoized(() => switch (defaultCurrencyFrom) {
      DefaultCurrencyFrom.group => groupCurrency,
      DefaultCurrencyFrom.user => userCurrency,
      DefaultCurrencyFrom.none => null,
    }, [defaultCurrencyFrom, groupCurrency, userCurrency]);
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: selectedCurrency != defaultCurrency
            ? context.colorScheme.tertiaryContainer
            : context.colorScheme.surfaceContainerHighest,
        foregroundColor: selectedCurrency != defaultCurrency
            ? context.colorScheme.onTertiaryContainer
            : context.colorScheme.onSurface,
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => showCurrencyPickerSheet(context,
          currency: selectedCurrency,
          onCurrencySelected: onCurrencyChanged,
          defaultCurrencyFrom: defaultCurrencyFrom,
        ),
      child: Text("${selectedCurrency.flag ?? ""} ${selectedCurrency.code}"),
    );
  }
}
