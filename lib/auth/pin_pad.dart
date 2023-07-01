import 'dart:math';
import 'package:csocsort_szamla/auth/pin_number_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PinPad extends StatefulWidget {
  final String pin;
  final String? pinConfirm;
  final bool isPinInput;
  final ValueChanged<String> onPinChanged;
  final ValueChanged<String>? onPinConfirmChanged;
  final bool showConfirm;
  final String? validationText;
  final ValueChanged<String?> onValidationTextChanged;
  final double? maxWidth;
  PinPad({
    required String this.pin,
    this.pinConfirm,
    this.isPinInput = true,
    required this.onPinChanged,
    this.onPinConfirmChanged,
    this.validationText,
    required this.onValidationTextChanged,
    this.showConfirm = true,
    this.maxWidth,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  bool isPinFieldNotEmpty() {
    return (widget.isPinInput && widget.pin != '') ||
        (!widget.isPinInput && widget.pinConfirm != '');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Ink(
            decoration: BoxDecoration(
              color: ElevationOverlay.applyOverlay(
                  context, Theme.of(context).colorScheme.surface, 8),
              borderRadius: BorderRadius.circular(12),
            ),
            height: 56,
            child: Stack(
              children: [
                Center(
                  child: Builder(builder: (context) {
                    String? textToShow = widget.pin;
                    if (textToShow == '') {
                      textToShow = 'pin'.tr();
                    } else {
                      textToShow = '•' * textToShow.length;
                    }
                    if (!widget.isPinInput) {
                      textToShow = widget.pinConfirm;
                      if (widget.pinConfirm == '') {
                        textToShow = 'confirm_pin'.tr();
                      } else {
                        textToShow = '•' * textToShow!.length;
                      }
                    }
                    return Text(
                      textToShow,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: isPinFieldNotEmpty() ? 30 : null),
                    );
                  }),
                ),
                AnimatedCrossFade(
                  duration: Duration(milliseconds: 100),
                  crossFadeState: (widget.isPinInput && widget.pin != '') ||
                          (!widget.isPinInput && widget.pinConfirm != '')
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Container(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: Text(
                      widget.isPinInput ? 'pin'.tr() : 'confirm_pin'.tr(),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ),
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
              maxWidth: widget.maxWidth ??
                  min(300, MediaQuery.of(context).size.height / 7 * 3),
            ),
            child: Table(
              columnWidths: {
                0: FractionColumnWidth(1 / 3),
                1: FractionColumnWidth(1 / 3),
                2: FractionColumnWidth(1 / 3),
              },
              children: [
                TableRow(
                  children: ['1', '2', '3'].map((number) {
                    return PinNumberButton(
                      number: number,
                      pin: widget.pin,
                      pinConfirm: widget.pinConfirm,
                      onValidationTextChanged: widget.onValidationTextChanged,
                      onPinChanged: widget.onPinChanged,
                      onPinConfirmChanged: widget.onPinConfirmChanged,
                      isPinInput: widget.isPinInput,
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      textColor:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                    );
                  }).toList(),
                ),
                TableRow(
                  children: ['4', '5', '6'].map((number) {
                    return PinNumberButton(
                      number: number,
                      pin: widget.pin,
                      pinConfirm: widget.pinConfirm,
                      onValidationTextChanged: widget.onValidationTextChanged,
                      onPinChanged: widget.onPinChanged,
                      onPinConfirmChanged: widget.onPinConfirmChanged,
                      isPinInput: widget.isPinInput,
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      textColor:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                    );
                  }).toList(),
                ),
                TableRow(
                  children: ['7', '8', '9'].map((number) {
                    return PinNumberButton(
                      number: number,
                      pin: widget.pin,
                      pinConfirm: widget.pinConfirm,
                      onValidationTextChanged: widget.onValidationTextChanged,
                      onPinChanged: widget.onPinChanged,
                      onPinConfirmChanged: widget.onPinConfirmChanged,
                      isPinInput: widget.isPinInput,
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      textColor:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                    );
                  }).toList(),
                ),
                TableRow(
                  children: ['', '0', 'C'].map((number) {
                    return (number == 'C' && isPinFieldNotEmpty()) ||
                            number == '0'
                        ? PinNumberButton(
                            number: number,
                            pin: widget.pin,
                            pinConfirm: widget.pinConfirm,
                            onValidationTextChanged:
                                widget.onValidationTextChanged,
                            onPinChanged: widget.onPinChanged,
                            onPinConfirmChanged: widget.onPinConfirmChanged,
                            isPinInput: widget.isPinInput,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            textColor: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          )
                        : Container();
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
