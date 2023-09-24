import 'package:csocsort_szamla/helpers/providers/app_state_provider.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:provider/provider.dart';

class CustomAmountDialog extends StatefulWidget {
  final double? initialValue;
  final double? maxValue;
  final double? maxMoney;
  final double minValue;
  final bool? alreadyCustom;
  final String? currency;

  const CustomAmountDialog(
      {this.initialValue, this.maxValue, this.maxMoney, this.alreadyCustom, this.currency, this.minValue = 0});

  @override
  State<CustomAmountDialog> createState() => _CustomAmountDialogState();
}

class _CustomAmountDialogState extends State<CustomAmountDialog> {
  double? sliderValue;
  String? currency;
  TextEditingController customAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    sliderValue = widget.initialValue;
    currency = widget.currency ?? context.read<AppStateProvider>().currentGroup!.currency;
    customAmountController.text = sliderValue.toMoneyString(currency!);
  }

  void setSliderValue(newValue, {bool setController = true}) {
    setState(() {
      sliderValue = newValue;
      if (setController) {
        customAmountController.text = sliderValue.toMoneyString(currency!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'custom_amount'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            Text(
              'custom-amount.dialog.subtitle'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              'custom-amount.dialog.hint'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 5),
            TextFormField(
              controller: customAmountController,
              decoration: InputDecoration(
                helperText: (customAmountController.text.length > 0
                    ? 'chosen_amount'.tr() + ' (${currencies[currency]!['symbol']}) '
                    : null),
                hintText: 'custom_amount'.tr() + ' (${currencies[currency]!['symbol']}) ',
                suffixText: '${(sliderValue! / widget.maxMoney! * 100).roundToDouble().toStringAsFixed(0)}%',
              ),
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              onChanged: (value) {
                double? newValue = double.tryParse(value);
                if (newValue != null) {
                  if (newValue > widget.maxValue!) {
                    newValue = widget.maxValue;
                  }
                  if (newValue! < widget.minValue) {
                    newValue = widget.minValue;
                  }
                  setSliderValue(newValue, setController: false);
                } else {
                  setState(() {});
                }
              },
            ),
            SizedBox(
              height: 10,
            ),
            Slider(
              value: sliderValue!,
              divisions: 20,
              max: widget.maxValue!,
              min: widget.minValue,
              thumbColor: Theme.of(context).colorScheme.secondary,
              activeColor: Theme.of(context).colorScheme.secondary,
              onChanged: (value) {
                setSliderValue(value);
              },
            ),
            Visibility(
              visible: widget.alreadyCustom!,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context, -1);
                },
                child: Text('reset'.tr()),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GradientButton(
                  child: Icon(Icons.check),
                  onPressed: () {
                    Navigator.pop(context, sliderValue);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
