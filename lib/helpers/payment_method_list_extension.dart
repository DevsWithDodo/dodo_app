import 'package:csocsort_szamla/helpers/models.dart';

extension PaymentMethodListExtension on List<PaymentMethod> {
  bool hasSameElementsInOrder(List<PaymentMethod> other) {
    if (this.length != other.length) {
      return false;
    }
    for (int i = 0; i < this.length; i++) {
      if (this[i].name != other[i].name || this[i].value != other[i].value || this[i].priority != other[i].priority) {
        return false;
      }
    }
    return true;
  }
}