
enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }
enum Month { january, february, march, april, may, june, july, august, september, october, november, december }
enum DayOfModifier { week, month, year }
extension DateTimeModifier on DateTime {
  
  DateTime firstDayOf(DayOfModifier modifier) {
    switch (modifier) {
      case DayOfModifier.week:
        return subtract(Duration(days: weekday - 1));
      case DayOfModifier.month:
        return DateTime(this.year, this.month, 1);
      case DayOfModifier.year:
        return DateTime(this.year, 1, 1);
    }
  }

  DateTime lastDayOf(DayOfModifier modifier) {
    switch (modifier) {
      case DayOfModifier.week:
        return add(Duration(days: 7 - weekday));
      case DayOfModifier.month:
        return DateTime(this.year, this.month + 1, 1).subtract(Duration(days: 1));
      case DayOfModifier.year:
        return DateTime(this.year + 1, 1, 0);
    }
  }

  DateTime midnight() {
    return DateTime(this.year, this.month, this.day);
  }

  DateTime noon() {
    return DateTime(this.year, this.month, this.day, 12);
  }

  DateTime endOfDay() {
    return DateTime(this.year, this.month, this.day, 23, 59, 59, 999);
  }

  DateTime today() {
    return midnight();
  }

  DateTime tomorrow() {
    return midnight().add(Duration(days: 1));
  }

  DateTime yesterday() {
    return midnight().subtract(Duration(days: 1));
  }

  DateTime nthWeekdayOf(int n, Weekday weekday, [DayOfModifier modifier = DayOfModifier.year]) {
    DateTime date = firstDayOf(modifier);
    assert(n > 0);
    assert(modifier != DayOfModifier.week);
    assert((modifier == DayOfModifier.month && n <= 5) || (modifier == DayOfModifier.year && n <= 53));
    int count = 0;
    while (date.weekday != weekday.index) {
      date = date.add(Duration(days: 1));
    }
    while (count < n) {
      date = date.add(Duration(days: 7));
      count++;
    }
    return date.subtract(Duration(days: 1));
  }

  DateTime year(int year) {
    return DateTime(year, this.month, this.day, hour, minute, second, millisecond, microsecond);
  }

  DateTime month(int month) {
    return DateTime(this.year, month, this.day, hour, minute, second, millisecond, microsecond);
  }

  DateTime day(int day) {
    return DateTime(this.year, this.month, day, hour, minute, second, millisecond, microsecond);
  }

  DateTime time(int hour, [int minute = 0, int second = 0, int millisecond = 0, int microsecond = 0]) {
    return DateTime(this.year, this.month, this.day, hour, minute, second, millisecond, microsecond);
  }
}
