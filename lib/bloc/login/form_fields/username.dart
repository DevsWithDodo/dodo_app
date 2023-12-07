import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:formz/formz.dart';

class Username extends FormzInput<String, String> {
  const Username.pure() : super.pure('');
  const Username.dirty([String value = '']) : super.dirty(value);

  @override
  String? validator(String? value) => validateTextField([
        isEmpty(value),
        minimalLength(value, 3),
        allowedRegEx(value, RegExp(r'[^a-z0-9.]+')),
        // ...(_usernameTaken
        //     ? [throwError('username_taken'.tr())]
        //     : []),
      ]);
}
