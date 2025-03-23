// ignore_for_file: use_build_context_synchronously

import 'package:app_links/app_links.dart';
import 'package:csocsort_szamla/helpers/navigator_service.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/main.dart';
import 'package:csocsort_szamla/pages/app/join_group_page.dart';
import 'package:csocsort_szamla/pages/auth/login_or_register_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InviteUrlProvider extends StatelessWidget {
  InviteUrlProvider({super.key, required this.builder}) {
    _inviteUrl = InviteUrlState(null);

    _appLinks.getInitialAppLinkString().then((link) {
      if (link != null) {
        _inviteUrl.inviteUrl = link;
      }
    });

    _appLinks.allStringLinkStream.listen((link) {
      _inviteUrl.inviteUrl = link;

      BuildContext context = getIt.get<NavigationService>().navigatorKey.currentContext!;
      if (context.read<UserNotifier>().user != null) {
        getIt.get<NavigationService>().push(
              MaterialPageRoute(
                builder: (context) => JoinGroupPage(fromAuth: (context.read<UserNotifier>().user?.group == null) ? true : false),
              ),
            );
      } else {
        getIt.get<NavigationService>().push(MaterialPageRoute(builder: (context) => LoginOrRegisterPage()));
      }
    });
  }

  final Widget Function(BuildContext context) builder;
  late final InviteUrlState _inviteUrl;
  final _appLinks = AppLinks();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _inviteUrl,
      builder: (context, child) => builder(context),
    );
  }
}

class InviteUrlState extends ChangeNotifier {
  String? _inviteUrl;

  InviteUrlState(this._inviteUrl);

  String? get inviteUrl => _inviteUrl;

  set inviteUrl(String? value) {
    _inviteUrl = value;
    notifyListeners();
  }
}
