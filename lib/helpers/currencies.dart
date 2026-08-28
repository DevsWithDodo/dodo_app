import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';

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
    if (!Currency.isInitialized) {
      throw CurrenciesNotInitializedException();
    }
    return this * toCurrency.rate! / fromCurrency.rate!;
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

class CurrenciesNotInitializedException implements Exception {
  CurrenciesNotInitializedException();
  @override
  String toString() {
    return 'CurrenciesNotInitializedException: Currencies are not initialized';
  }
}

class Currency {
  Currency._(this.code, this.countryCodes, this.hasSubunit, this.symbol, this.flag,
      this.symbolBeforeAmount,
      {this.isMajor = false});

  factory Currency.fromCode(String code, {bool safe = false}) {
    final currency = byCode[code];
    if (currency == null) {
      if (safe) {
        return byCode["EUR"]!;
      }
      throw CurrencyNotFoundException(code);
    }
    return currency;
  }

  final String code;
  final List<String> countryCodes;
  final String symbol;
  final String? flag;
  final bool symbolBeforeAmount;
  final bool hasSubunit;
  final bool isMajor;
  double? rate;

  static List<String> allCodes() {
    return _all.map((currency) => currency.code).toList();
  }

  static List<Currency> all() {
    return _all;
  }

  double get smallestUnit => hasSubunit ? 0.01 : 1;

  double threshold() => smallestUnit / 2;

  String get fullName => "currency.name.$code".tr();

  List<String> get allFullNames => _all.map((currency) => currency.fullName).toList();

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

  static bool get isInitialized =>
      all().every((currency) => currency.rate != null);

  /// ISO 3166-1 alpha-2 country code → currency.
  static Currency? fromCountryCode(String countryCode) {
    return byCountryCode[countryCode.toUpperCase()];
  }

  static final List<Currency> _all = [
    Currency._("AED", ["AE"], true, "د.إ", "🇦🇪", true),
    Currency._("AFN", ["AF"], true, "؋", "🇦🇫", true),
    Currency._("ALL", ["AL"], true, "L", "🇦🇱", false),
    Currency._("AMD", ["AM"], true, "֏", "🇦🇲", false),
    Currency._("AOA", ["AO"], true, "Kz", "🇦🇴", false),
    Currency._("ARS", ["AR"], true, "\$", "🇦🇷", true),
    Currency._(
        "AUD", ["AU", "CC", "CX", "KI", "NF", "NR", "TV"], true, "A\$", "🇦🇺", true),
    Currency._("AWG", ["AW"], true, "ƒ", "🇦🇼", true),
    Currency._("AZN", ["AZ"], true, "₼", "🇦🇿", true),
    Currency._("BAM", ["BA"], true, "KM", "🇧🇦", false),
    Currency._("BBD", ["BB"], true, "Bds\$", "🇧🇧", true),
    Currency._("BDT", ["BD"], true, "৳", "🇧🇩", true),
    Currency._("BHD", ["BH"], true, ".د.ب", "🇧🇭", true),
    Currency._("BIF", ["BI"], false, "FBu", "🇧🇮", false),
    Currency._("BMD", ["BM"], true, "\$", "🇧🇲", true),
    Currency._("BND", ["BN"], true, "B\$", "🇧🇳", true),
    Currency._("BOB", ["BO"], true, "Bs", "🇧🇴", true),
    Currency._("BRL", ["BR"], true, "R\$", "🇧🇷", true),
    Currency._("BSD", ["BS"], true, "\$", "🇧🇸", true),
    Currency._("BTN", ["BT"], true, "Nu.", "🇧🇹", true),
    Currency._("BWP", ["BW"], true, "P", "🇧🇼", true),
    Currency._("BYN", ["BY"], true, "Br", "🇧🇾", false),
    Currency._("BZD", ["BZ"], true, "BZ\$", "🇧🇿", true),
    Currency._("CAD", ["CA"], true, "C\$", "🇨🇦", true),
    Currency._("CDF", ["CD"], true, "FC", "🇨🇩", false),
    Currency._("CHF", ["CH", "LI"], true, "CHf", "🇨🇭", false),
    Currency._("CLP", ["CL"], true, "\$", "🇨🇱", true),
    Currency._("CML", [""], false, "🐪", null, false),
    Currency._("CNY", ["CN"], true, "¥", "🇨🇳", true),
    Currency._("COP", ["CO"], true, "\$", "🇨🇴", true),
    Currency._("CRC", ["CR"], true, "₡", "🇨🇷", true),
    Currency._("CUP", ["CU"], true, "\$", "🇨🇺", true),
    Currency._("CVE", ["CV"], true, "\$", "🇨🇻", true),
    Currency._("CZK", ["CZ"], true, "Kč", "🇨🇿", false),
    Currency._("DJF", ["DJ"], false, "Fdj", "🇩🇯", false),
    Currency._("DKK", ["DK", "FO", "GL"], true, "Kr.", "🇩🇰", false),
    Currency._("DOP", ["DO"], true, "RD\$", "🇩🇴", true),
    Currency._("DZD", ["DZ"], true, "دج", "🇩🇿", true),
    Currency._("EGP", ["EG"], true, "E£", "🇪🇬", true),
    Currency._("ERN", ["ER"], true, "Nfk", "🇪🇷", false),
    Currency._("ETB", ["ET"], true, "Br", "🇪🇹", true),
    Currency._(
        "EUR",
        [
          "AD",
          "AT",
          "AX",
          "BE",
          "BL",
          "CY",
          "DE",
          "EE",
          "ES",
          "FI",
          "FR",
          "GF",
          "GP",
          "GR",
          "HR",
          "IE",
          "IT",
          "LT",
          "LU",
          "LV",
          "MC",
          "ME",
          "MF",
          "MQ",
          "MT",
          "NL",
          "PM",
          "PT",
          "RE",
          "SI",
          "SK",
          "SM",
          "TF",
          "VA",
          "XK",
          "YT"
        ],
        true,
        "€",
        "🇪🇺",
        true,
        isMajor: true),
    Currency._("FJD", ["FJ"], true, "FJ\$", "🇫🇯", true),
    Currency._("FKP", ["FK"], true, "£", "🇫🇰", true),
    Currency._("GBP", ["GB"], true, "£", "🇬🇧", true, isMajor: true),
    Currency._("GEL", ["GE"], true, "₾", "🇬🇪", true),
    Currency._("GGP", ["GG"], true, "£", "🇬🇬", true),
    Currency._("GHS", ["GH"], true, "GH₵", "🇬🇭", true),
    Currency._("GIP", ["GI"], true, "£", "🇬🇮", true),
    Currency._("GMD", ["GM"], true, "D", "🇬🇲", true),
    Currency._("GNF", ["GN"], false, "FG", "🇬🇳", false),
    Currency._("GTQ", ["GT"], true, "Q", "🇬🇹", true),
    Currency._("GYD", ["GY"], true, "\$", "🇬🇾", true),
    Currency._("HKD", ["HK"], true, "HK\$", "🇭🇰", true),
    Currency._("HNL", ["HN"], true, "L", "🇭🇳", true),
    Currency._("HTG", ["HT"], true, "G", "🇭🇹", true),
    Currency._("HUF", ["HU"], false, "Ft", "🇭🇺", false),
    Currency._("IDR", ["ID"], false, "Rp", "🇮🇩", true),
    Currency._("ILS", ["IL", "PS"], true, "₪", "🇮🇱", true),
    Currency._("IMP", ["IM"], true, "£", "🇮🇲", true),
    Currency._("INR", ["IN"], true, "₹", "🇮🇳", true, isMajor: true),
    Currency._("IQD", ["IQ"], true, "ع.د", "🇮🇶", true),
    Currency._("IRR", ["IR"], true, "﷼", "🇮🇷", true),
    Currency._("ISK", ["IS"], false, "Íkr.", "🇮🇸", false),
    Currency._("JEP", ["JE"], true, "£", "🇯🇪", true),
    Currency._("JMD", ["JM"], true, "J\$", "🇯🇲", true),
    Currency._("JOD", ["JO"], true, "JD", "🇯🇴", true),
    Currency._("JPY", ["JP"], false, "JP¥", "🇯🇵", true, isMajor: true),
    Currency._("KES", ["KE"], true, "KSh", "🇰🇪", true),
    Currency._("KGS", ["KG"], true, "сом", "🇰🇬", false),
    Currency._("KHR", ["KH"], true, "៛", "🇰🇭", true),
    Currency._("KMF", ["KM"], false, "CF", "🇰🇲", false),
    Currency._("KRW", ["KR"], false, "₩", "🇰🇷", true),
    Currency._("KWD", ["KW"], true, "د.ك", "🇰🇼", true),
    Currency._("KYD", ["KY"], true, "\$", "🇰🇾", true),
    Currency._("KZT", ["KZ"], true, "₸", "🇰🇿", true),
    Currency._("LAK", ["LA"], true, "₭", "🇱🇦", true),
    Currency._("LBP", ["LB"], true, "ل.ل", "🇱🇧", true),
    Currency._("LKR", ["LK"], true, "Rs", "🇱🇰", true),
    Currency._("LRD", ["LR"], true, "\$", "🇱🇷", true),
    Currency._("LSL", ["LS"], true, "L", "🇱🇸", true),
    Currency._("LYD", ["LY"], true, "ل.د", "🇱🇾", true),
    Currency._("MAD", ["MA", "EH"], true, "DH", "🇲🇦", false),
    Currency._("MDL", ["MD"], true, "L", "🇲🇩", false),
    Currency._("MGA", ["MG"], true, "Ar", "🇲🇬", true),
    Currency._("MKD", ["MK"], true, "ден", "🇲🇰", false),
    Currency._("MMK", ["MM"], true, "K", "🇲🇲", true),
    Currency._("MNT", ["MN"], true, "₮", "🇲🇳", true),
    Currency._("MOP", ["MO"], true, "MOP\$", "🇲🇴", true),
    Currency._("MRU", ["MR"], true, "UM", "🇲🇷", false),
    Currency._("MUR", ["MU"], true, "₨", "🇲🇺", true),
    Currency._("MVR", ["MV"], true, "Rf", "🇲🇻", true),
    Currency._("MWK", ["MW"], true, "MK", "🇲🇼", true),
    Currency._("MXN", ["MX"], true, "\$", "🇲🇽", true),
    Currency._("MYR", ["MY"], true, "RM", "🇲🇾", true),
    Currency._("MZN", ["MZ"], true, "MT", "🇲🇿", true),
    Currency._("NAD", ["NA"], true, "\$", "🇳🇦", true),
    Currency._("NGN", ["NG"], true, "₦", "🇳🇬", true),
    Currency._("NIO", ["NI"], true, "C\$", "🇳🇮", true),
    Currency._("NOK", ["NO", "SJ"], true, "kr", "🇳🇴", false),
    Currency._("NPR", ["NP"], true, "Rs", "🇳🇵", true),
    Currency._("NZD", ["NZ", "CK", "NU", "PN", "TK"], true, "\$", "🇳🇿", true),
    Currency._("OMR", ["OM"], true, "ر.ع.", "🇴🇲", true),
    Currency._("PAB", ["PA"], true, "B/.", "🇵🇦", true),
    Currency._("PEN", ["PE"], true, "S/", "🇵🇪", true),
    Currency._("PGK", ["PG"], true, "K", "🇵🇬", true),
    Currency._("PHP", ["PH"], false, "₱", "🇵🇭", true),
    Currency._("PKR", ["PK"], true, "₨", "🇵🇰", true),
    Currency._("PLN", ["PL"], true, "zł", "🇵🇱", false),
    Currency._("PYG", ["PY"], false, "₲", "🇵🇾", true),
    Currency._("QAR", ["QA"], true, "ر.ق", "🇶🇦", true),
    Currency._("RON", ["RO"], true, "lei", "🇷🇴", false),
    Currency._("RSD", ["RS"], true, "дин", "🇷🇸", false),
    Currency._("RUB", ["RU"], true, "₽", "🇷🇺", false),
    Currency._("RWF", ["RW"], false, "FRw", "🇷🇼", false),
    Currency._("SAR", ["SA"], true, "ر.س", "🇸🇦", true),
    Currency._("SBD", ["SB"], true, "\$", "🇸🇧", true),
    Currency._("SCR", ["SC"], true, "₨", "🇸🇨", true),
    Currency._("SDG", ["SD"], true, "ج.س.", "🇸🇩", true),
    Currency._("SEK", ["SE"], true, "kr", "🇸🇪", false),
    Currency._("SGD", ["SG"], true, "S\$", "🇸🇬", true),
    Currency._("SLE", ["SL"], true, "Le", "🇸🇱", true),
    Currency._("SOS", ["SO"], true, "Sh", "🇸🇴", true),
    Currency._("SRD", ["SR"], true, "\$", "🇸🇷", true),
    Currency._("STN", ["ST"], true, "Db", "🇸🇹", true),
    Currency._("SVC", ["SV"], true, "₡", "🇸🇻", true),
    Currency._("SZL", ["SZ"], true, "L", "🇸🇿", true),
    Currency._("THB", ["TH"], false, "฿ ", "🇹🇭", true),
    Currency._("TJS", ["TJ"], true, "SM", "🇹🇯", false),
    Currency._("TMT", ["TM"], true, "m", "🇹🇲", false),
    Currency._("TND", ["TN"], true, "د.ت", "🇹🇳", true),
    Currency._("TRY", ["TR"], true, "₺", "🇹🇷", true),
    Currency._("TTD", ["TT"], true, "TT\$", "🇹🇹", true),
    Currency._("TWD", ["TW"], true, "NT\$", "🇹🇼", true),
    Currency._("TZS", ["TZ"], true, "TSh", "🇹🇿", true),
    Currency._("UAH", ["UA"], true, "₴", "🇺🇦", true),
    Currency._("UGX", ["UG"], false, "USh", "🇺🇬", true),
    Currency._(
        "USD",
        [
          "US",
          "AS",
          "BQ",
          "EC",
          "FM",
          "GU",
          "MH",
          "MP",
          "PR",
          "PW",
          "SV",
          "TC",
          "TL",
          "UM",
          "VG",
          "VI"
        ],
        true,
        "\$",
        "🇺🇸",
        true,
        isMajor: true),
    Currency._("UYU", ["UY"], true, "\$", "🇺🇾", true),
    Currency._("UZS", ["UZ"], true, "so'm", "🇺🇿", false),
    Currency._("VES", ["VE"], true, "Bs.S", "🇻🇪", true),
    Currency._("VND", ["VN"], false, "₫", "🇻🇳", false),
    Currency._("VUV", ["VU"], false, "VT", "🇻🇺", false),
    Currency._("WST", ["WS"], true, "WS\$", "🇼🇸", true),
    Currency._(
        "XAF",
        [
          "CF",
          "CG",
          "CM",
          "GA",
          "GQ",
          "TD",
        ],
        false,
        "F.CFA",
        null,
        false),
    Currency._("XCD", ["AG", "AI", "DM", "GD", "KN", "LC", "MS", "VC"], true,
        "\$", null, true),
    Currency._("XCG", ["CW", "SX"], true, "Cg", null, true),
    Currency._("XOF", ["BF", "BJ", "CI", "GW", "ML", "NE", "SN", "TG"], false,
        "CFA", null, false),
    Currency._("XPF", ["NC", "PF", "WF"], false, "₣", null, false),
    Currency._("YER", ["YE"], true, "﷼", "🇾🇪", true),
    Currency._("ZAR", ["ZA"], true, "R", "🇿🇦", true),
    Currency._("ZMW", ["ZW"], true, "ZK", "🇿🇲", true),
    Currency._("ZWL", ["ZW"], true, "\$", "🇿🇼", true),
  ];

  static final byCode = SplayTreeMap.of(Map.fromEntries(
      _all.map((currency) => MapEntry(currency.code, currency))));
  static final _allCountryCodes =
      _all.expand((currency) => currency.countryCodes).toSet();
  static final byCountryCode = Map.fromEntries(_allCountryCodes.map(
      (countryCode) => MapEntry(
          countryCode,
          _all.firstWhere(
              (currency) => currency.countryCodes.contains(countryCode)))));
}
