import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:formz/formz.dart';

class Password extends FormzInput<String, String> {
  const Password.pure() : super.pure('');
  const Password.dirty([String value = '']) : super.dirty(value);

  @override
  String? validator(String? value) => validateTextField([
        isEmpty(value),
        minimalLength(value, 4),
        // ...(_usernameTaken
        //     ? [throwError('username_taken'.tr())]
        //     : []),
      ]);
}