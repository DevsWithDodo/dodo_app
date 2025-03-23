import 'package:csocsort_szamla/helpers/navigator_service.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/helpers/providers/invite_url_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/main.dart';
import 'package:csocsort_szamla/pages/app/join_group_page.dart';
import 'package:csocsort_szamla/pages/app/main_page.dart';
import 'package:csocsort_szamla/pages/auth/login_or_register_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    var userState = context.watch<UserNotifier>();
    var link = context.watch<InviteUrlState>().inviteUrl;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dodo',
      theme: context.watch<AppThemeState>().theme,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: FToastBuilder(),
      navigatorKey: getIt.get<NavigationService>().navigatorKey,
      home: userState.user == null
          ? LoginOrRegisterPage()
          : (link != null)
              ? JoinGroupPage(
                  inviteURL: link,
                  fromAuth: (userState.user?.group == null) ? true : false,
                )
              : (userState.user?.group == null)
                  ? JoinGroupPage(
                      fromAuth: true,
                    )
                  : MainPage(),
    );
  }
}
