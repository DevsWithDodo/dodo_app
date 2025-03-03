import 'dart:math';

import 'package:csocsort_szamla/components/auth/pin_pad_number.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PinPad extends StatefulWidget {
  final String pin;
  final String? pinConfirm;
  final bool isPinInput;
  final ValueChanged<String> onPinChanged;
  final ValueChanged<String>? onPinConfirmChanged;
  final String? validationText;
  final ValueChanged<String?>? onValidationTextChanged;
  final double? maxWidth;
  final String? pinLabel;
  final String? pinConfirmLabel;

  const PinPad({
    super.key,
    required this.pin,
    this.pinConfirm,
    this.isPinInput = true,
    required this.onPinChanged,
    this.onPinConfirmChanged,
    this.validationText,
    this.onValidationTextChanged,
    this.maxWidth,
    this.pinLabel,
    this.pinConfirmLabel,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  bool isPinFieldEmpty() {
    return !((widget.isPinInput && widget.pin != '') || (!widget.isPinInput && widget.pinConfirm != ''));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Ink(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(
                bottom: BorderSide(
                  color: isPinFieldEmpty() ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            height: 56,
            child: Stack(
              children: [
                Center(
                  child: Builder(builder: (context) {
                    String? textToShow = '•' * (widget.isPinInput ? widget.pin.length : widget.pinConfirm!.length);
                    return Text(
                      textToShow,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: isPinFieldEmpty() ? null : 30),
                    );
                  }),
                ),
                Builder(builder: (context) {
                  final duration = Duration(milliseconds: 200);
                  final theme = Theme.of(context);
                  return AnimatedAlign(
                    duration: duration,
                    alignment: isPinFieldEmpty() ? Alignment.center : Alignment.topLeft,
                    child: AnimatedDefaultTextStyle(
                      duration: duration,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: isPinFieldEmpty() ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
                        fontSize: isPinFieldEmpty() ? 18 : 12,
                      ),
                      child: AnimatedPadding(
                        duration: duration,
                        padding: EdgeInsets.only(left: isPinFieldEmpty() ? 0 : 10, top: isPinFieldEmpty() ? 0 : 5),
                        child: Text(
                          widget.isPinInput ? widget.pinLabel ?? 'pin'.tr() : widget.pinConfirmLabel ?? 'confirm_pin'.tr(),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Visibility(
          visible: widget.validationText != null,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              widget.validationText?.tr() ?? '',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ),
        SizedBox(height: 5),
        Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: widget.maxWidth ?? min(300, MediaQuery.of(context).size.height / 7 * 3),
            ),
            child: Table(
              columnWidths: {
                0: FractionColumnWidth(1 / 3),
                1: FractionColumnWidth(1 / 3),
                2: FractionColumnWidth(1 / 3),
              },
              children: [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
                ['C', '0', '']
              ]
                  .map((row) => TableRow(
                        children: row
                            .map(
                              (number) => (number == 'C' && isPinFieldEmpty() || number == '')
                                  ? Container()
                                  : PinPadNumber(
                                      number: number,
                                      pin: widget.pin,
                                      pinConfirm: widget.pinConfirm,
                                      onValidationTextChanged: widget.onValidationTextChanged,
                                      onPinChanged: widget.onPinChanged,
                                      onPinConfirmChanged: widget.onPinConfirmChanged,
                                      isPinInput: widget.isPinInput,
                                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                      textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                                    ),
                            )
                            .toList(),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
