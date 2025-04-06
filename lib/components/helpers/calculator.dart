import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:customized_keyboard/customized_keyboard.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum Operator { add, subtract, multiply, divide, none }

enum ButtonText {
  empty(""),
  one("1"),
  two("2"),
  three("3"),
  four("4"),
  five("5"),
  six("6"),
  seven("7"),
  eight("8"),
  nine("9"),
  zero("0"),
  dot("."),
  equals("="),
  backspace("b"),
  clear("AC"),
  parentheses("( )"), // New button for parentheses
  divide("÷", Operator.divide),
  multiply("×", Operator.multiply),
  subtract("-", Operator.subtract),
  add("+", Operator.add);

  const ButtonText(this.text, [this.operator = Operator.none]);

  factory ButtonText.fromString(String text) {
    return ButtonText.values.firstWhere((element) => element.text == text, orElse: () => ButtonText.empty);
  }
  final String text;
  final Operator operator;

  bool get isOperator => operator != Operator.none;

  bool get isNumber => !isOperator && this != ButtonText.empty && this != ButtonText.dot && this != ButtonText.backspace && this != ButtonText.clear && this != ButtonText.equals;
}

class CalculatorTextField extends StatelessWidget {
  final TextEditingController controller;
  final Currency selectedCurrency;
  final CustomKeyboard calculatorKeyboard = CalculatorKeyboard();
  final void Function(double value) onChanged;
  final FocusNode? focusNode;

  CalculatorTextField({
    super.key,
    required this.controller,
    required this.selectedCurrency,
    required this.onChanged,
    this.focusNode,
  });

  void _calculateCurrentExpression() {
    final value = controller.text;
    if (value.isEmpty) return;

    if (value.contains('=')) {
      // Already has an equals sign, just remove it
      String expression = value.replaceAll('=', '');
      controller.text = expression;
    }

    double result = _evaluateExpression(value);

    if (result > 0) {
      controller.text = result.toMoneyString(selectedCurrency);
      onChanged(result);
    } else {
      controller.text = '0';
      onChanged(0);
    }
  }

  bool _endsWithOperator(String expression) {
    return expression.endsWith('+') || expression.endsWith('-') || expression.endsWith('*') || expression.endsWith('/') || expression.endsWith('(') || expression.endsWith(')');
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      focusNode: focusNode,
      validator: (value) => validateTextField([
        isEmpty(value),
        notValidNumber(value!.replaceAll(',', '.')),
      ]),
      selectionControls: EmptyTextSelectionControls(),
      decoration: InputDecoration(
        labelText: 'full_amount'.tr(),
        prefixIcon: Icon(Icons.payments),
      ),
      controller: controller,
      keyboardType: calculatorKeyboard.inputType,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9\\.\\,\\+\\-\\*\\/\\÷\\×\\=\\(\\)]'))],
      onTapOutside: (event) {
        _calculateCurrentExpression();
        // focusNode?.unfocus();
      },
      onChanged: (value) {
        final parenthesesIndex = value.indexOf('()');
        if (parenthesesIndex != -1) {
          // Handle smart parentheses insertion
          List<String> splitted = value.split('()');
          String interestingPart = splitted[0];
          // Max 1 () in value
          String rest = splitted.length > 1 ? splitted[1] : '';
          int openCount = interestingPart.split('(').length - 1;
          int closeCount = interestingPart.split(')').length - 1;

          if (openCount > closeCount) {
            controller.text = "$interestingPart)$rest";
          } else {
            controller.text = "$interestingPart($rest";
          }
          controller.selection = TextSelection.fromPosition(TextPosition(offset: parenthesesIndex + 1));
          if (controller.text.contains('()')) {
            // If the text still contains '()', remove it
            controller.text = controller.text.replaceAll('()', '');
          }
        } else if (value.contains('=')) {
          // Calculate result when = is entered
          String expression = value.replaceAll('=', '');
          double result = _evaluateExpression(expression);
          if (result == result.toInt()) {
            controller.text = result.toInt().toString();
          } else {
            controller.text = result.toString();
          }
          if (result > 0) {
            onChanged(result);
          }
        } else if (_endsWithOperator(value) && _endsWithOperator(value.substring(0, value.length - 1))) {
          // If the last character is an operator and the second last is also an operator, change the last operator
          controller.text = value.substring(0, value.length - 2) + value[value.length - 1];
        } else {
          // Try to parse as a number for the onChanged callback
          double? parsedTotal = double.tryParse(value.replaceAll(',', '.'));
          if (parsedTotal != null && parsedTotal > 0) {
            onChanged(parsedTotal);
          }
        }
      },
    );
  }

  double _evaluateExpression(String expression) {
    // Convert special characters
    expression = expression.replaceAll('×', '*').replaceAll('÷', '/');

    if (_endsWithOperator(expression)) {
      // Remove trailing operator
      expression = expression.substring(0, expression.length - 1);
    }

    int openCount = expression.split('(').length - 1;
    int closeCount = expression.split(')').length - 1;

    while (openCount > closeCount) {
      expression += ')';
      closeCount++;
    }

    expression = _addImplicitMultiplication(expression);

    // Simple expression evaluator for basic operations
    try {
      // First handle parentheses
      while (expression.contains('(') && expression.contains(')')) {
        // Find the innermost parentheses
        int closeIndex = expression.indexOf(')');
        int openIndex = expression.lastIndexOf('(', closeIndex);

        if (openIndex == -1 || closeIndex == -1) break;

        // Extract and evaluate the expression inside the parentheses
        String subExpr = expression.substring(openIndex + 1, closeIndex);
        double result = _evaluateExpression(subExpr);

        // Replace the parenthesized expression with its result
        expression = expression.substring(0, openIndex) + result.toString() + expression.substring(closeIndex + 1);
      }

      // Then handle multiplication and division
      while (expression.contains('*') || expression.contains('/')) {
        RegExp regex = RegExp(r'(\d+\.?\d*)[*/](\d+\.?\d*)');
        Match? match = regex.firstMatch(expression);

        if (match != null) {
          String fullMatch = match.group(0)!;
          double a = double.parse(match.group(1)!);
          double b = double.parse(match.group(2)!);
          double result;

          if (fullMatch.contains('*')) {
            result = a * b;
          } else {
            result = a / b;
          }

          expression = expression.replaceFirst(fullMatch, result.toString());
        } else {
          break;
        }
      }

      // Then handle addition and subtraction
      while (expression.contains('+') || (expression.contains('-') && !expression.startsWith('-'))) {
        RegExp regex = RegExp(r'(\d+\.?\d*)[+\-](\d+\.?\d*)');
        Match? match = regex.firstMatch(expression);

        if (match != null) {
          String fullMatch = match.group(0)!;
          double a = double.parse(match.group(1)!);
          double b = double.parse(match.group(2)!);
          double result;

          if (fullMatch.contains('+')) {
            result = a + b;
          } else {
            result = a - b;
          }

          expression = expression.replaceFirst(fullMatch, result.toString());
        } else {
          break;
        }
      }

      return (double.parse(expression) * 10000).round() / 10000;
    } catch (e) {
      return 0;
    }
  }

  String _addImplicitMultiplication(String expression) {
    // Use regex to find number followed by opening parenthesis or closing parenthesis followed by a number
    RegExp regex = RegExp(r'(\d)(\()|(\))(\d)');
    return expression.replaceAllMapped(regex, (match) {
      if (match.group(1) != null) {
        return '${match.group(1)}*${match.group(2)}';
      } else {
        return '${match.group(3)}*${match.group(4)}';
      }
    });
  }
}

class Calculator extends StatelessWidget {
  Calculator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 380,
      ),
      padding: const EdgeInsets.only(
        left: 10,
        right: 10,
        top: 15,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Table(
          children: [0, 1, 2, 3].map((index) {
            return TableRow(
              children: _generateRow(context, index),
            );
          }).toList(),
        ),
      ),
    );
  }

  final List<List<ButtonText>> _rows = [
    [ButtonText.divide, ButtonText.one, ButtonText.two, ButtonText.three, ButtonText.clear],
    [ButtonText.multiply, ButtonText.four, ButtonText.five, ButtonText.six, ButtonText.parentheses],
    [ButtonText.subtract, ButtonText.seven, ButtonText.eight, ButtonText.nine, ButtonText.empty],
    [ButtonText.add, ButtonText.dot, ButtonText.zero, ButtonText.backspace, ButtonText.equals],
  ];

  List<Widget> _generateRow(BuildContext context, int index) {
    return _rows[index].map((buttonText) {
      Color color, textColor;

      if (buttonText.isOperator || buttonText == ButtonText.backspace || buttonText == ButtonText.dot || buttonText == ButtonText.parentheses) {
        color = Theme.of(context).colorScheme.secondaryContainer;
        textColor = Theme.of(context).colorScheme.onSecondaryContainer;
      } else if (buttonText == ButtonText.clear) {
        color = Theme.of(context).colorScheme.tertiaryContainer;
        textColor = Theme.of(context).colorScheme.onTertiaryContainer;
      } else if (buttonText == ButtonText.equals) {
        color = Theme.of(context).colorScheme.primaryContainer;
        textColor = Theme.of(context).colorScheme.onPrimaryContainer;
      } else if (buttonText == ButtonText.empty) {
        color = Colors.transparent;
        textColor = Theme.of(context).colorScheme.onSurface;
      } else {
        color = Theme.of(context).colorScheme.surfaceContainerHighest;
        textColor = Theme.of(context).colorScheme.onSurfaceVariant;
      }

      return Padding(
        padding: const EdgeInsets.all(3),
        child: buttonText == ButtonText.empty
            ? Container()
            : CalculatorButton(
                backgroundColor: color,
                textColor: textColor,
                keyEvent: buttonText == ButtonText.clear
                    ? CustomKeyboardEvent.clear()
                    : buttonText == ButtonText.backspace
                        ? CustomKeyboardEvent.deleteOne()
                        : CustomKeyboardEvent.character(buttonText.text),
                child: Center(
                  child: buttonText != ButtonText.backspace
                      ? Text(
                          buttonText.text,
                          style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: textColor),
                        )
                      : Icon(Icons.backspace, color: textColor),
                ),
              ),
      );
    }).toList();
  }
}

class CalculatorButton extends StatefulWidget {
  const CalculatorButton({
    required this.keyEvent,
    required this.backgroundColor,
    required this.textColor,
    required this.child,
    super.key,
  });

  final CustomKeyboardEvent keyEvent;
  final Color backgroundColor;
  final Color textColor;
  final Widget child;

  @override
  State<CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<CalculatorButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      reverseDuration: const Duration(milliseconds: 300),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Ink(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(20 + (1 - _controller.value) * 50),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: InkWell(
            onTapDown: (details) => _controller.forward(from: 0),
            onTapUp: (details) => _controller.reverse(from: 1),
            onTapCancel: () => _controller.reverse(from: 1),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            onTap: () {
              HapticFeedback.lightImpact();
              final keyboardWrapper = KeyboardWrapper.of(context);
              if (keyboardWrapper == null) {
                throw KeyboardWrapperNotFound();
              }
              keyboardWrapper.onKey(widget.keyEvent);
            },
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

class CalculatorKeyboard extends CustomKeyboard {
  @override
  Widget build(BuildContext context) {
    return TextFieldTapRegion(child: Calculator());
  }

  @override
  double get height => 380;

  @override
  String get name => 'CALCULATOR_KEYBOARD';
}
