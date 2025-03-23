import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserUsageNotifier extends ChangeNotifier {
  final SharedPreferences _prefs;
  bool ratedApp;
  int expenseCount;
  int receiptScannerCount;
  bool receiptScannedFlag;
  bool copiedSettleUpFlag;
  bool usedAutomaticSettleUpFlag;
  bool addedPaymentMethodFlag;
  DateTime lastRateAppDialogDate;
  int appOpenCount;
  bool themeChangedFlag;
  int groupsUsedCount;

  UserUsageNotifier(this._prefs)
      : ratedApp = _prefs.getBool('user-usage.rated-app') ?? false,
        expenseCount = _prefs.getInt('user-usage.expense-count') ?? 0,
        receiptScannerCount = _prefs.getInt('user-usage.receipt-scanner-count') ?? 0,
        copiedSettleUpFlag = _prefs.getBool('user-usage.copied-settle-up-flag') ?? false,
        usedAutomaticSettleUpFlag = _prefs.getBool('user-usage.used-automatic-settle-up-flag') ?? false,
        addedPaymentMethodFlag = _prefs.getBool('user-usage.added-payment-method-flag') ?? false,
        lastRateAppDialogDate = DateTime.parse(_prefs.getString('user-usage.last-rate-app-dialog-date') ?? DateTime.now().toString()),
        appOpenCount = _prefs.getInt('user-usage.app-open-count') ?? 0,
        themeChangedFlag = _prefs.getBool('user-usage.theme-changed-flag') ?? false,
        groupsUsedCount = _prefs.getInt('user-usage.groups-used-count') ?? 0,
        receiptScannedFlag = _prefs.getBool('user-usage.receipt-scanned-flag') ?? false;

  bool anyFlagTrue() {
    return copiedSettleUpFlag || usedAutomaticSettleUpFlag || addedPaymentMethodFlag || themeChangedFlag || receiptScannedFlag;
  }

  void setFlagsFalse() {
    copiedSettleUpFlag = false;
    usedAutomaticSettleUpFlag = false;
    addedPaymentMethodFlag = false;
    themeChangedFlag = false;
    receiptScannedFlag = false;
    _prefs.setBool('user-usage.copied-settle-up-flag', copiedSettleUpFlag);
    _prefs.setBool('user-usage.used-automatic-settle-up-flag', usedAutomaticSettleUpFlag);
    _prefs.setBool('user-usage.added-payment-method-flag', addedPaymentMethodFlag);
    _prefs.setBool('user-usage.theme-changed-flag', themeChangedFlag);
    _prefs.setBool('user-usage.receipt-scanned-flag', receiptScannedFlag);
    notifyListeners();
  }

  void setRatedApp(bool value) {
    ratedApp = value;
    _prefs.setBool('user-usage.rated-app', value);
    notifyListeners();
  }

  void setExpenseCount(int value) {
    expenseCount = value;
    _prefs.setInt('user-usage.expense-count', value);
    notifyListeners();
  }

  void incrementExpenseCount() => setExpenseCount(expenseCount + 1);

  void setReceiptScannerCount(int value) {
    receiptScannerCount = value;
    _prefs.setInt('user-usage.receipt-scanner-count', value);
    notifyListeners();
  }

  void setReceiptScannedFlag(bool value) {
    receiptScannedFlag = value;
    _prefs.setBool('user-usage.receipt-scanned-flag', value);
    notifyListeners();
  }

  void incrementReceiptScannerCount() => setReceiptScannerCount(receiptScannerCount + 1);

  void setCopiedSettleUpFlag(bool value) {
    copiedSettleUpFlag = value;
    _prefs.setBool('user-usage.copied-settle-up-flag', value);
    notifyListeners();
  }

  void setUsedAutomaticSettleUpFlag(bool value) {
    usedAutomaticSettleUpFlag = value;
    _prefs.setBool('user-usage.used-automatic-settle-up-flag', value);
    notifyListeners();
  }

  void setAddedPaymentMethodFlag(bool value) {
    addedPaymentMethodFlag = value;
    _prefs.setBool('user-usage.added-payment-method-flag', value);
    notifyListeners();
  }

  void setLastRateAppDialogDate(DateTime date) {
    lastRateAppDialogDate = date;
    _prefs.setString('user-usage.last-rate-app-dialog-date', date.toIso8601String());
    notifyListeners();
  }

  void setAppOpenCount(int count) {
    appOpenCount = count;
    _prefs.setInt('user-usage.app-open-count', count);
    notifyListeners();
  }

  void incrementAppOpenCount() => setAppOpenCount(appOpenCount + 1);

  void setThemeChangedFlag(bool value) {
    themeChangedFlag = value;
    _prefs.setBool('user-usage.theme-changed-flag', value);
    notifyListeners();
  }

  void setGroupsUsedCount(int count) {
    groupsUsedCount = count;
    _prefs.setInt('user-usage.groups-used-count', count);
    notifyListeners();
  }

  void incrementGroupsUsedCount() => setGroupsUsedCount(groupsUsedCount + 1);

  void reset() {
    ratedApp = false;
    expenseCount = 0;
    receiptScannerCount = 0;
    copiedSettleUpFlag = false;
    usedAutomaticSettleUpFlag = false;
    addedPaymentMethodFlag = false;
    lastRateAppDialogDate = DateTime.now();
    appOpenCount = 0;
    themeChangedFlag = false;
    groupsUsedCount = 0;

    _prefs.remove('user-usage.rated-app');
    _prefs.remove('user-usage.expense-count');
    _prefs.remove('user-usage.receipt-scanner-count');
    _prefs.remove('user-usage.copied-settle-up-flag');
    _prefs.remove('user-usage.used-automatic-settle-up-flag');
    _prefs.remove('user-usage.added-payment-method-flag');
    _prefs.remove('user-usage.last-rate-app-dialog-date');
    _prefs.remove('user-usage.app-open-count');
    _prefs.remove('user-usage.theme-changed-flag');
    _prefs.remove('user-usage.groups-used-count');
    notifyListeners();
  }
}
