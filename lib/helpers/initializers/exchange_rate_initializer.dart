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
          await http.get(Uri.parse('${context.read<AppConfig>().appUrl}/currencies'), headers: header);
      Map<String, dynamic> decoded = jsonDecode(response.body);
      List<String> notFound = [];
      for (String currency in (decoded["rates"] as LinkedHashMap<String, dynamic>).keys) {
        try {
          Currency.fromCode(currency).rate = decoded['rates'][currency] * 1.0;
        } catch (e) {
          if (e is CurrencyNotFoundException) {
            notFound.add(currency);
          } else {
            log(e.toString());
          }
        }
      }
      if (notFound.isNotEmpty) {
        log("The following currencies are supported by the provider but not found in the app: ${notFound.join(', ')}");
      }
    } catch (_) {
      log("Couldn't fetch exchange rates.");
    }
  }

  @override
  Widget build(BuildContext context) => builder(context);
}
