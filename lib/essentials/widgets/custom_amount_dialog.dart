import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/essentials/widgets/tap_or_hold_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/config.dart';

class CustomAmountDialog extends StatefulWidget {
  final double initialValue;
  final double maxValue;
  final double maxMoney;
  final double minValue;
  final bool alreadyCustom;
  final String currency;

  const CustomAmountDialog(
      {this.initialValue,
      this.maxValue,
      this.maxMoney,
      this.alreadyCustom,
      this.currency,
      this.minValue = 0});

  @override
  State<CustomAmountDialog> createState() => _CustomAmountDialogState();
}

class _CustomAmountDialogState extends State<CustomAmountDialog> {
  double sliderValue;
  double magnet;
  String currency;
  TextEditingController customAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    sliderValue = widget.initialValue;
    magnet = 0.5;
    currency = widget.currency ?? currentGroupCurrency;
    customAmountController.text = sliderValue.toMoneyString(currency);
  }

  void setSliderValue(newValue, {bool setController = true}) {
    setState(() {
      sliderValue = newValue;
      if (setController) {
        customAmountController.text = sliderValue.toMoneyString(currency);
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
                  .titleLarge
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            Text(
              'custom_amount_explanation'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            SizedBox(
              height: 10,
            ),
            TextFormField(
                controller: customAmountController,
                decoration: InputDecoration(
                  helperText: (customAmountController.text.length > 0 ? 'chosen_amount'.tr() + ' (${currencies[currency]['symbol']}) ' : null),
                  hintText: 'custom_amount'.tr() + ' (${currencies[currency]['symbol']}) ',
                  suffixText: '${(sliderValue / widget.maxMoney * 100).roundToDouble().toStringAsFixed(0)}%',
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              onChanged: (value) {
                double newValue = double.tryParse(value);
                if (newValue != null) {
                  if (newValue > widget.maxValue) {
                    newValue = widget.maxValue;
                  }
                  if (newValue < widget.minValue) {
                    newValue = widget.minValue;
                  }
                  setSliderValue(newValue, setController: false);
                } else {
                  setState(() {});
                }
              },
            ),
            SizedBox(height: 10,),
            Row(
              children: [
                TapOrHoldButton(
                  onUpdate: () {
                    double value = hasSubunit(currency) ? 0.01 : 1;
                    if (sliderValue - value >= widget.minValue) {
                      setSliderValue(sliderValue - value);
                    }
                  },
                  icon: Icons.remove,
                ),
                Expanded(
                  child: Slider(
                    value: sliderValue,
                    divisions: 20,
                    max: widget.maxValue,
                    min: widget.minValue,
                    thumbColor: Theme.of(context).colorScheme.secondary,
                    activeColor: Theme.of(context).colorScheme.secondary,
                    onChanged: (value) {
                      setSliderValue(value);
                    },
                  ),
                ),
                TapOrHoldButton(
                  onUpdate: () {
                    double value = hasSubunit(currency) ? 0.01 : 1;
                    if (sliderValue + value <= widget.maxValue) {
                      setSliderValue(sliderValue + value);
                    }
                  },
                  icon: Icons.add,
                ),
              ],
            ),
            Visibility(
              visible: widget.alreadyCustom,
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
                  child: Icon(Icons.check, color: Theme.of(context).colorScheme.onPrimary),
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
