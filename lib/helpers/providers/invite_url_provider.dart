import 'package:csocsort_szamla/helpers/navigator_service.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/main.dart';
import 'package:csocsort_szamla/pages/app/join_group_page.dart';
import 'package:csocsort_szamla/pages/auth/login_or_register_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

class InviteUrlProvider extends StatelessWidget {
  InviteUrlProvider({required this.builder}) {
    _inviteUrl = InviteUrlState(null);

    _appLinks.getInitialAppLinkString().then((link) {
      if (link != null) {
        _inviteUrl.inviteUrl = link;
      }
    });

    _appLinks.allStringLinkStream.listen((link) {
      _inviteUrl.inviteUrl = link;

      BuildContext context = getIt.get<NavigationService>().navigatorKey.currentContext!;
      if (context.read<UserState>().user != null) {
        getIt.get<NavigationService>().push(
              MaterialPageRoute(
                builder: (context) =>
                    JoinGroupPage(fromAuth: (context.read<UserState>().user?.group == null) ? true : false),
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
      builder: (context, child) => this.builder(context),
    );
  }
}

class InviteUrlState extends ChangeNotifier {
  String? _inviteUrl = null;

  InviteUrlState(this._inviteUrl);

  String? get inviteUrl => _inviteUrl;

  set inviteUrl(String? value) {
    _inviteUrl = value;
    notifyListeners();
  }
}
