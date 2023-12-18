import 'dart:convert';

import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/pages/version_not_supported_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class SupportedVersionInitializer extends StatefulWidget {
  const SupportedVersionInitializer({super.key, required this.builder});

  final Widget Function(BuildContext context) builder;

  @override
  State<SupportedVersionInitializer> createState() => _SupportedVersionInitializerState();
}

class _SupportedVersionInitializerState extends State<SupportedVersionInitializer> {
  late Future<bool> _versionSupported;

  Future<bool> _supportedVersion() async {
    try {
      Map<String, String> header = {
        "Content-Type": "application/json",
      };
      http.Response response = await http.get(
        Uri.parse(context.read<AppConfig>().appUrl + '/supported?version=' + currentVersion.toString()),
        headers: header,
      );
      bool decoded = jsonDecode(response.body) ?? true;
      return decoded;
    } catch (e) {
      log('Supported version could not be fetched!', error: e);
      return true;
    }
  }

  @override
  void initState() {
    super.initState();
    _versionSupported = _supportedVersion();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _versionSupported,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == false) {
          return MaterialApp(
            theme: context.read<AppThemeState>().theme,
            home: VersionNotSupportedPage()
          );
        }
        return widget.builder(context);
      },
    );
  }
}
