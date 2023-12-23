import 'dart:collection';
import 'dart:convert';

import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class ExchangeRateInitializer extends StatelessWidget {
  ExchangeRateInitializer({required this.builder, required BuildContext context, super.key}) {
    init(context);
  }

  late final Widget Function(BuildContext context) builder;

  void init(BuildContext context) async {
    try {
      Map<String, String> header = {
        "Content-Type": "application/json",
      };
      http.Response response =
          await http.get(Uri.parse(context.read<AppConfig>().appUrl + '/currencies'), headers: header);
      Map<String, dynamic> decoded = jsonDecode(response.body);
      List<String> notFound = [];
      for (String currency in (decoded["rates"] as LinkedHashMap<String, dynamic>).keys) {
        try {
          Currency.fromCode(currency).setRate(decoded['rates'][currency]);
        } catch (e) {
          if (e is CurrencyNotFoundException) {
            notFound.add(currency);
          } else {
            log(e.toString());
          }
        }
      }
      if (notFound.isNotEmpty) {
        log("Couldn't find the following currencies: ${notFound.join(', ')}");
      }
    } catch (_) {
      for (String currency in Currency.allCodes()) {
        Currency.fromCode(currency).setRate(1);
      }
      log("Couldn't fetch exchange rates. Fallback: set all rates to 1:1.");
    }
  }

  @override
  Widget build(BuildContext context) => this.builder(context);
}