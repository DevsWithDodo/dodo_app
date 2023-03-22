import 'package:easy_localization/easy_localization.dart';

String validateTextField(List<Function> validationRules) {
  for (Function rule in validationRules) {
    // List<dynamic> arguments = validationRules[rule];
    String problem = rule();
    if (problem != null) {
      return problem;
    }
  }
  return null;
}

//TextField Rules

/// Returns error if String value is empty.
Function isEmpty(String value) => () {
      if (value.trim().isEmpty) {
        return 'field_empty'.tr();
      }
      return null;
    };

/// Returns error if String value's length is smaller
/// than given length.
Function minimalLength(String value, int length) => () {
      if (value.trim().length < length) {
        return 'minimal_length'.tr(args: [length.toString()]);
      }
      return null;
    };

/// Returns error if String value's is not a valid number.
///
///  Optional parameters:
///  * [type] of number.
///  * boolean if the number needs to be greater than 0.
Function notValidNumber(String value, {String type = 'double', bool needsGreaterZero = true}) =>
    () {
      switch (type) {
        case 'double':
          if (double.tryParse(value) == null) {
            return 'not_valid_num'.tr();
          }
          if (needsGreaterZero && double.parse(value) < 0) {
            return 'not_valid_num'.tr();
          }
          break;
        case 'integer':
          if (int.tryParse(value) == null) {
            return 'not_valid_num'.tr();
          }
          if (needsGreaterZero && int.parse(value) < 0) {
            return 'not_valid_num'.tr();
          }
      }
      return null;
    };

/// Returns error if String value doesn't match String otherValue.
///
///  Optional parameters:
///  * [problem] String to print out to the user.
Function matchString(String value, String otherValue, {String problem = 'passwords_not_match'}) =>
    () {
      if (value != otherValue) {
        return problem.tr();
      }
      return null;
    };

Function allowedRegEx(String value, RegExp regExp) => () {
      String match = regExp.stringMatch(value);
      if (match != null) {
        return 'char_not_allowed'.tr(args: [match]);
      }
      return null;
    };

Function throwError(String error) => () {
      return error.tr();
    };
