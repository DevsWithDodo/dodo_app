import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinNumberButton extends StatefulWidget {
  final String? number;
  final bool isPinInput;
  final String? pin, pinConfirm;
  final ValueChanged<String> onPinChanged;
  final ValueChanged<String>? onPinConfirmChanged;
  final ValueChanged<String?> onValidationTextChanged;
  final Color backgroundColor;
  final Color textColor;
  const PinNumberButton({
    this.number,
    required this.isPinInput,
    this.pin,
    this.pinConfirm,
    required this.onPinChanged,
    this.onPinConfirmChanged,
    required this.onValidationTextChanged,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  State<PinNumberButton> createState() => _PinNumberButtonState();
}

class _PinNumberButtonState extends State<PinNumberButton>
    with SingleTickerProviderStateMixin {
  bool isTapped = false;
  late AnimationController _controller;
  late Animation<Color?> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 400),
    );
    _animation = ColorTween(
      end: widget.backgroundColor,
    ).animate(
        new CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic))
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Ink(
        decoration: BoxDecoration(
          color: _animation.value,
          borderRadius:
              BorderRadius.circular(20 + (1 - _controller.value) * 50),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: InkWell(
            splashFactory: NoSplash.splashFactory,
            customBorder: CircleBorder(),
            borderRadius: BorderRadius.circular(20),
            onTapDown: (details) {
              _controller.forward(from: 0);
            },
            onTapUp: (details) {
              _controller.reverse(from: 1);
            },
            onTapCancel: () {
              _controller.reverse(from: 1);
            },
            // hoverColor: Colors.transparent,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            onTap: widget.number == '' ||
                    (widget.isPinInput &&
                        widget.number == 'C' &&
                        widget.pin == '') ||
                    (!widget.isPinInput &&
                        widget.number == 'C' &&
                        widget.pinConfirm == '')
                ? null
                : () {
                    if (!kIsWeb && Platform.isAndroid) {
                      HapticFeedback.vibrate();
                    } else {
                      HapticFeedback.heavyImpact();
                    }
                    if (widget.number != '' && widget.number != 'C') {
                      setState(() {
                        if (widget.isPinInput) {
                          if (widget.pin?.length == 3) {
                            widget.onPinChanged(widget.pin! + widget.number!);
                            widget.onValidationTextChanged(null);
                          } else if (widget.pin!.length < 4) {
                            widget.onPinChanged(widget.pin! + widget.number!);
                          }
                        } else {
                          if (widget.pinConfirm?.length == 3) {
                            widget.onPinConfirmChanged!(
                                widget.pinConfirm! + widget.number!);
                            widget.onValidationTextChanged(null);
                          } else if ((widget.pinConfirm?.length ?? 4) < 4) {
                            widget.onPinConfirmChanged!(
                                widget.pinConfirm! + widget.number!);
                          }
                        }
                      });
                    } else if (widget.number == 'C') {
                      setState(() {
                        if (widget.isPinInput) {
                          widget.onPinChanged('');
                        } else {
                          widget.onPinConfirmChanged!('');
                        }
                      });
                    }
                  },
            child: Center(
              child: Builder(builder: (context) {
                if (widget.number == 'C') {
                  if ((widget.isPinInput && widget.pin != '') ||
                      (!widget.isPinInput && widget.pinConfirm != '')) {
                    return Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.tertiary,
                    );
                  }
                  return Container();
                }
                if (widget.number == '') {
                  return Container();
                }
                return Text(
                  widget.number!,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: _controller.value > 0.5
                          ? widget.textColor
                          : Theme.of(context).colorScheme.primary),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
