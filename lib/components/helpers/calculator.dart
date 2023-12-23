import 'dart:collection';

import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:csocsort_szamla/helpers/data_stack.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
  clear("C"),
  divide("÷", Operator.divide),
  multiply("×", Operator.multiply),
  subtract("-", Operator.subtract),
  add("+", Operator.add);

  const ButtonText(this.text, [this.operator = Operator.none]);
  final String text;
  final Operator operator;

  bool get isOperator => operator != Operator.none;

  bool get isNumber =>
      !isOperator &&
      this != ButtonText.empty &&
      this != ButtonText.dot &&
      this != ButtonText.backspace &&
      this != ButtonText.clear &&
      this != ButtonText.equals;
}

class StringOrOperator {
  StringOrOperator.string(this.value);
  StringOrOperator.operator(this.operator);

  String? value;
  Operator? operator;

  double? get asDouble => this.value != null ? double.tryParse(this.value!) : null;
}

class Calculator extends StatefulWidget {
  final void Function(String fromCalculation) onCalculationReady;
  final String? initialNumber;
  final Currency selectedCurrency;
  Calculator({required this.onCalculationReady, this.initialNumber, required this.selectedCurrency});
  @override
  _CalculatorState createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  String _intermediateResult = '';
  Queue<StringOrOperator> _RPNInput = Queue<StringOrOperator>();
  DataStack<Operator> _operators = DataStack<Operator>();
  bool _isStillNum = false;
  String _storeNum = '';
  Operator _lastOperator = Operator.none;

  @override
  void initState() {
    super.initState();
    if (widget.initialNumber != null) {
      _isStillNum = true;
      _intermediateResult = widget.initialNumber!;
      _storeNum = widget.initialNumber!;
    }
  }

  void parse(ButtonText input) {
    assert(input.isNumber || input.isOperator || input == ButtonText.dot);
    if (input == ButtonText.dot) {
      if (_isStillNum && !_storeNum.contains('.')) {
        _storeNum += input.text;
        setState(() {
          _lastOperator = Operator.none;
          _intermediateResult = _storeNum;
        });
      }
    } else if (input.isNumber) {
      if (_isStillNum || _storeNum == '') {
        _storeNum += input.text;
      }
      _isStillNum = true;
      setState(() {
        _lastOperator = Operator.none;
        _intermediateResult = _storeNum;
      });
    } else {
      if (_isStillNum) {
        if (_storeNum[_storeNum.length - 1] == '.') {
          _storeNum = _storeNum.substring(0, _storeNum.length - 1);
          setState(() {
            _intermediateResult = _storeNum;
          });
        }
        _RPNInput.add(StringOrOperator.string(_storeNum));
        _storeNum = '';
      }
      _isStillNum = false;
      if (_operators.length > 0) {
        _RPNInput.add(StringOrOperator.operator(_operators.pop()));
        String calculated = calculate();
        setState(() {
          _intermediateResult = calculated;
        });
        _RPNInput.clear();
        _RPNInput.add(StringOrOperator.string(calculated));
      }
      _operators.push(input.operator);
      setState(() {
        _lastOperator = input.operator;
      });
    }
    print(_RPNInput);
  }

  void equals() {
    setState(() {
      _lastOperator = Operator.none;
    });
    if (_storeNum != '') {
      _RPNInput.add(StringOrOperator.string(_storeNum));
    }
    while (_operators.length != 0) {
      _RPNInput.add(StringOrOperator.operator(_operators.pop()));
    }
    // print(_RPNintput);
    setState(() {
      _intermediateResult = calculate();
    });
    _storeNum = _intermediateResult;
    _RPNInput.clear();
  }

  void changeOperator(ButtonText input) {
    print('changeOperator');
    print(_intermediateResult);
    _operators.pop();
    _operators.push(input.operator);
    setState(() {
      if (_intermediateResult.length != 0 &&
          _operatorsAndEquals.contains(_intermediateResult[_intermediateResult.length - 1])) {
        _intermediateResult = _intermediateResult.substring(0, _intermediateResult.length - 1) + input.text;
      }
      _lastOperator = input.operator;
    });
  }

  String calculate() {
    DataStack<double> numbers = DataStack<double>();
    while (_RPNInput.length != 0) {
      StringOrOperator stringOrOperator = _RPNInput.removeFirst();
      double? parsed = stringOrOperator.asDouble;
      if (parsed != null) {
        numbers.push(parsed);
      } else {
        assert(stringOrOperator.operator != null && stringOrOperator.operator != Operator.none);
        double a = numbers.pop();
        double b = numbers.pop();
        late double c;
        switch (stringOrOperator.operator!) {
          case Operator.add:
            c = a + b;
            break;
          case Operator.subtract:
            c = -a + b;
            break;
          case Operator.multiply:
            c = a * b;
            break;
          case Operator.divide:
            c = b / a;
            break;
          case Operator.none:
            break;
        }
        numbers.push(c);
      }
    }
    double result = numbers.pop();
    if (result.roundToDouble() == result) {
      return result.toString().split('.')[0];
    }
    return result.toString();
  }

  void backspace() {
    if (_storeNum != '') {
      _storeNum = _storeNum.substring(0, _storeNum.length - 1);
      setState(() {
        _intermediateResult = _storeNum;
      });
    }
  }

  void clearAll() {
    _storeNum = '';
    _lastOperator = Operator.none;
    _operators = DataStack<Operator>();
    _RPNInput.clear();
    _isStillNum = false;
    setState(() {
      _intermediateResult = '0';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Text(
            'calculator'.tr(),
            style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'calculator_explanation'.tr(),
            style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          SizedBox(
            height: 15,
          ),
          Column(
            children: [
              Visibility(
                visible: _intermediateResult == '',
                child: Text(
                  '0',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall!
                      .copyWith(color: Theme.of(context).colorScheme.tertiary),
                ),
              ),
              Visibility(
                visible: _intermediateResult != '',
                child: Text(
                  _intermediateResult,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall!
                      .copyWith(color: Theme.of(context).colorScheme.tertiary),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
              child: Table(
                children: [0, 1, 2, 3].map((index) {
                  return TableRow(
                    children: _generateRow(index),
                  );
                }).toList(),
                // defaultColumnWidth: FractionColumnWidth(0.2),
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Ink(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _operators.length != 0 && _isStillNum
                  ? LinearGradient(colors: [Colors.grey, Colors.grey])
                  : AppTheme.gradientFromTheme(context.watch<AppThemeState>().themeName),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: _operators.length != 0 && _isStillNum
                  ? null
                  : () {
                      Navigator.pop(context);
                      if (double.tryParse(_intermediateResult) != null) {
                        widget.onCalculationReady(
                            double.parse(_intermediateResult).toMoneyString(widget.selectedCurrency));
                      }
                    },
              child: Icon(
                Icons.copy,
                color: _operators.length != 0 && _isStillNum ? Colors.black : Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          )
        ],
      ),
    );
  }

  List<ButtonText> _operatorsAndEquals = [
    ButtonText.add,
    ButtonText.subtract,
    ButtonText.divide,
    ButtonText.multiply,
    ButtonText.equals
  ];

  List<List<ButtonText>> _rows = [
    [ButtonText.divide, ButtonText.one, ButtonText.two, ButtonText.three, ButtonText.clear],
    [ButtonText.multiply, ButtonText.four, ButtonText.five, ButtonText.six, ButtonText.empty],
    [ButtonText.subtract, ButtonText.seven, ButtonText.eight, ButtonText.nine, ButtonText.empty],
    [ButtonText.add, ButtonText.dot, ButtonText.zero, ButtonText.backspace, ButtonText.equals],
  ];

  List<Widget> _generateRow(int index) {
    return _rows[index].map((buttonText) {
      Color color, textColor;
      if (_lastOperator == buttonText.operator && buttonText.isOperator) {
        color = Theme.of(context).colorScheme.secondary;
        textColor = Theme.of(context).colorScheme.onSecondary;
      } else if (buttonText.isOperator || buttonText == ButtonText.backspace || buttonText == ButtonText.dot) {
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
        color = Theme.of(context).colorScheme.surfaceVariant;
        textColor = Theme.of(context).colorScheme.onSurfaceVariant;
      }

      return AspectRatio(
        aspectRatio: 1,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: CalculatorButton(
            backgroundColor: color,
            textColor: textColor,
            onPressed: buttonText == ButtonText.empty
                ? null
                : () {
                    if (buttonText == ButtonText.clear) {
                      clearAll();
                      return;
                    }
                    if (buttonText == ButtonText.backspace) {
                      backspace();
                      return;
                    }
                    if (buttonText.isOperator || buttonText == ButtonText.equals) {
                      if (_isStillNum) {
                        if (buttonText == ButtonText.equals) {
                          equals();
                        } else {
                          parse(buttonText);
                        }
                      } else if (buttonText != ButtonText.equals && _operators.length != 0) {
                        changeOperator(buttonText);
                      }
                    } else {
                      parse(buttonText);
                    }
                  },
            child: Center(
              child: buttonText != ButtonText.backspace
                  ? Text(
                      buttonText.text,
                      style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: textColor),
                    )
                  : Icon(Icons.backspace, color: textColor),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class CalculatorButton extends StatefulWidget {
  const CalculatorButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    required this.child,
    super.key,
  });

  final VoidCallback? onPressed;
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
    return Ink(
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
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onPressed?.call();
          },
          child: widget.child,
        ),
      ),
    );
  }
}
