import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:formz/formz.dart';

class Pin extends FormzInput<String, String> {
  const Pin.pure() : super.pure('');
  const Pin.dirty([String value = '']) : super.dirty(value);

  @override
  String? validator(String? value) => validateTextField([
        isEmpty(value),
        minimalLength(value, 4),
      ]);
}