import 'package:csocsort_szamla/essentials/ad_unit.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/user_settings/change_password.dart';
import 'package:csocsort_szamla/user_settings/change_user_currency.dart';
import 'package:csocsort_szamla/user_settings/delete_all_data.dart';
import 'package:csocsort_szamla/user_settings/payment_methods.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'about_us.dart';
import 'change_language.dart';
import 'change_username.dart';
import 'components/color_picker.dart';
import 'personalised_ads.dart';
import 'report_bug.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    print('asdasdasd');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'settings'.tr(),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Column(
          children: [
            if (context.watch<ScreenWidth>().isMobile)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _settings(),
                  ),
                ),
              )
            else
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: ScrollController(),
                        children: _settings().take(3).toList(),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: ScrollController(),
                        children: _settings()
                            .reversed
                            .take(7)
                            .toList()
                            .reversed
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            AdUnit(site: 'settings'),
          ],
        ),
      ),
    );
  }

  List<Widget> _settings() {
    return [
      ColorPicker(),
      LanguagePicker(),
      ChangePassword(),
      ChangeUsername(),
      ChangeUserCurrency(),
      PaymentMethods(),
      Selector<AppStateProvider, bool>(
          selector: (context, provider) => provider.user!.showAds,
          builder: (context, showAds, child) {
            return Visibility(
              visible: showAds,
              child: PersonalisedAds(),
            );
          }),
      AboutUs(),
      DeleteAllData(),
      ReportBug(),
    ];
  }
}
