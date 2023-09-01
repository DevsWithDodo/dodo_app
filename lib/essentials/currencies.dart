import 'dart:collection';

extension Money on double? {
  String toMoneyString(String code, {withSymbol = false}) {
    if (!withSymbol) {
      double? d = this;
      if (this! > -Currency.threshold(code) && this! < 0) {
        d = -this!;
      }
      return currencies[code]!["subunit"] == 1
          ? d!.toStringAsFixed(2)
          : d!.toStringAsFixed(0);
    } else {
      return currencies[code]!["before"] == 1
          ? this! < 0
              ? "-" +
                  currencies[code]!["symbol"] +
                  "" +
                  this!.abs().toMoneyString(code)
              : currencies[code]!["symbol"] + "" + this.toMoneyString(code)
          : this.toMoneyString(code) + " " + currencies[code]!["symbol"];
    }
  }

  double? exchange(String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) {
      return this;
    }
    if (currencies[toCurrency]!["rate"] == null ||
        currencies[fromCurrency]!["rate"] == null) {
      return this;
    }
    return this! *
        currencies[toCurrency]!["rate"] /
        currencies[fromCurrency]!["rate"];
  }
}

class Currency {
  static double threshold(String code) {
    return (currencies[code]!['subunit'] == 1 ? 0.01 : 1) / 2;
  }

  static bool hasSubunit(String code) {
    return currencies[code]!["subunit"] == 1;
  }

  static String getSymbol(String code) {
    return currencies[code]!["symbol"];
  }

  static List<String> enumerateCurrencies() {
    return currencies.keys
        .map((key) => key + ";" + currencies[key]!["symbol"])
        .toList();
  }
}

Map<String, Map<String, dynamic>> currencies =
    SplayTreeMap.from(unorderedCurrencies, (a, b) => a.compareTo(b));

Map<String, Map<String, dynamic>> unorderedCurrencies = {
  "CAD": {"subunit": 1, "symbol": "C\$", "before": 1},
  "HKD": {"subunit": 1, "symbol": "HK\$", "before": 1},
  "ISK": {"subunit": 0, "symbol": "Íkr.", "before": 0},
  "PHP": {"subunit": 0, "symbol": "₱", "before": 1},
  "DKK": {"subunit": 1, "symbol": "Kr.", "before": 0},
  "HUF": {"subunit": 0, "symbol": "Ft", "before": 0},
  "CZK": {"subunit": 0, "symbol": "Kč", "before": 0},
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
