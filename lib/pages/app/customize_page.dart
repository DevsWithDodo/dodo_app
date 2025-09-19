import 'package:csocsort_szamla/components/helpers/ad_unit.dart';
import 'package:csocsort_szamla/components/user_settings/cards/change_language.dart';
import 'package:csocsort_szamla/components/user_settings/components/theme_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CustomizePage extends StatefulWidget {
  const CustomizePage({super.key});

  @override
  State<CustomizePage> createState() => _CustomizePageState();
}

class _CustomizePageState extends State<CustomizePage> {
  Widget? stackWidget;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'customization'.tr(),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ThemePicker(),
                      LanguagePicker(),
                    ],
                  ),
                ),
              ),
              AdUnit(site: 'settings'),
            ],
          ),
        ),
      ),
    );
  }
}
