import 'dart:collection';

extension Money on double {
  String toMoneyString(Currency currency, {bool withSymbol = false}) {
    if (!withSymbol) {
      double d = this;
      if (this > -currency.threshold() && this < 0) {
        d = -this;
      }
      return currency.hasSubunit ? d.toStringAsFixed(2) : d.toStringAsFixed(0);
    } else {
      return currency.symbolBeforeAmount
          ? this < 0
              ? "-${currency.symbol}${abs().toMoneyString(currency)}"
              : "${currency.symbol}${toMoneyString(currency)}"
          : "${toMoneyString(currency)} ${currency.symbol}";
    }
  }

  double exchange(Currency fromCurrency, Currency toCurrency) {
    if (fromCurrency == toCurrency) {
      return this;
    }
    return this * toCurrency.rate / fromCurrency.rate;
  }
}

class CurrencyNotFoundException implements Exception {
  CurrencyNotFoundException(this.code);

  final String code;

  @override
  String toString() {
    return 'CurrencyNotFoundException: There is no currency with the given code $code';
  }
}

class Currency {
  const Currency._(this.code, this.hasSubunit, this.symbol, this.symbolBeforeAmount, [this.rate = 1]);

  factory Currency.fromCode(String code, {bool safe = false}) {
    if (!_unorderedCurrencies.containsKey(code)) {
      if (safe) {
        return Currency.fromCode('EUR');
      }
      throw CurrencyNotFoundException(code);
    }
    return Currency._fromEntry(code, _unorderedCurrencies[code]!);
  }

  factory Currency._fromEntry(String code, Map<String, dynamic> entry) {
    return Currency._(
      code,
      entry['subunit'] == 1,
      entry['symbol'],
      entry['before'] == 1,
      (entry['rate'] ?? 1) * 1.0,
    );
  }

  final String code;
  final String symbol;
  final bool symbolBeforeAmount;
  final bool hasSubunit;
  final double rate;

  static List<String> allCodes() {
    return _currencies.keys.toList();
  }

  static List<Currency> all() {
    return _currencies.keys.map((code) => Currency.fromCode(code)).toList();
  }

  void setRate(dynamic rate) {
    _currencies[code]!['rate'] = rate;
  }

  double get smallestUnit => hasSubunit ? 0.01 : 1;

  double threshold() => smallestUnit / 2;

  @override
  String toString() {
    return code;
  }

  @override
  bool operator ==(Object other) {
    return other is Currency && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}

Map<String, Map<String, dynamic>> _currencies = SplayTreeMap.from(_unorderedCurrencies, (a, b) => a.compareTo(b));

Map<String, Map<String, dynamic>> _unorderedCurrencies = {
  "CAD": {"subunit": 1, "symbol": "C\$", "before": 1},
  "HKD": {"subunit": 1, "symbol": "HK\$", "before": 1},
  "ISK": {"subunit": 0, "symbol": "Íkr.", "before": 0},
  "PHP": {"subunit": 0, "symbol": "₱", "before": 1},
  "DKK": {"subunit": 1, "symbol": "Kr.", "before": 0},
  "HUF": {"subunit": 0, "symbol": "Ft", "before": 0},
  "CZK": {"subunit": 1, "symbol": "Kč", "before": 0},
  "AUD": {"subunit": 1, "symbol": "A\$", "before": 1},
  "RON": {"subunit": 1, "symbol": "lei", "before": 0},
  "SEK": {"subunit": 1, "symbol": "kr", "before": 0},
  "IDR": {"subunit": 0, "symbol": "Rp", "before": 1},
  "INR": {"subunit": 1, "symbol": "₹", "before": 1},
  "BRL": {"subunit": 1, "symbol": "R\$", "before": 1},
  "RUB": {"subunit": 1, "symbol": "₽", "before": 0},
  "HRK": {"subunit": 1, "symbol": "kn", "before": 0},
  "JPY": {"subunit": 0, "symbol": "JP¥", "before": 1},
  "THB": {"subunit": 0, "symbol": "฿ ", "before": 1},
  "CHF": {"subunit": 1, "symbol": "CHf", "before": 0},
  "SGD": {"subunit": 1, "symbol": "S\$", "before": 1},
  "PLN": {"subunit": 1, "symbol": "zł", "before": 0},
  "BGN": {"subunit": 1, "symbol": "Лв", "before": 0},
  "TRY": {"subunit": 1, "symbol": "₺", "before": 1},
  "CNY": {"subunit": 1, "symbol": "¥", "before": 1},
  "NOK": {"subunit": 1, "symbol": "kr", "before": 0},
  "NZD": {"subunit": 1, "symbol": "\$", "before": 1},
  "ZAR": {"subunit": 1, "symbol": "R", "before": 1},
  "USD": {"subunit": 1, "symbol": "\$", "before": 1},
  "MXN": {"subunit": 1, "symbol": "\$", "before": 1},
  "ILS": {"subunit": 1, "symbol": "₪", "before": 1},
  "GBP": {"subunit": 1, "symbol": "£", "before": 1},
  "KRW": {"subunit": 0, "symbol": "₩", "before": 1},
  "MYR": {"subunit": 1, "symbol": "RM", "before": 1},
  "EUR": {"subunit": 1, "symbol": "€", "before": 1},
  "CML": {"subunit": 0, "symbol": "🐪", "before": 0}
};
