import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/user_settings/cards/change_password_dialog.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginOptions extends StatefulWidget {
  const LoginOptions({super.key});

  @override
  State<LoginOptions> createState() => _LoginOptionsState();
}

class _LoginOptionsState extends State<LoginOptions> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserNotifier>().user!;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Text(
                'user-settings.login-options'.tr(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 5,
            ),
            Center(
                child: Text(
              'user-settings.login-options.description'.tr(),
              style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            )),
            SizedBox(
              height: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (user.hasPassword) // Only temporary, later on you should be able to set a pin
                  Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: LoginOption(
                      connected: user.hasPassword,
                      loginTypeWidget: Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Text(
                          'user-settings.login-options.pin'.tr(),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      connectedWidget: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.green,
                            size: 30,
                          ),
                          SizedBox(width: 10),
                          IconButton.filled(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => ChangePasswordDialog(),
                              );
                            },
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.edit),
                          ),
                        ],
                      ),
                      notConnectedWidget: TextButton(
                        onPressed: () {},
                        child: Text('user-settings.login-options.set-pin'.tr()),
                      ),
                    ),
                  ),
                LoginOption.social(
                  type: SocialLoginType.google,
                  connected: user.googleConnected,
                  onPressed: () async {
                    final appConfig = context.read<AppConfig>();
                    final credential = await getGoogleAuth(appConfig.googleOAuthServerClientId);
                    if (credential?.idToken == null) {
                      return;
                    }
                    _linkSocialLogin(IdTokenType.google, credential!.idToken!);
                  },
                ),
                SizedBox(height: 10),
                LoginOption.social(
                  type: SocialLoginType.apple,
                  connected: user.appleConnected,
                  onPressed: () async {
                    final appConfig = context.read<AppConfig>();
                    final credential = await getAppleAuth(
                      appConfig.appleOAuthClientId,
                      appConfig.appUrl,
                    );
                    _linkSocialLogin(IdTokenType.apple, credential.authorizationCode);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _linkSocialLogin(IdTokenType idTokenType, String code) {
    showFutureOutputDialog(
      context: context,
      future: context.read<UserNotifier>().linkSocialLogin(idTokenType, code),
    );
  }
}

enum SocialLoginType {
  google,
  apple,
}

class LoginOption extends StatelessWidget {
  final bool connected;
  final Widget loginTypeWidget;
  final Widget connectedWidget;
  final Widget notConnectedWidget;
  const LoginOption({
    super.key,
    required this.connected,
    required this.loginTypeWidget,
    required this.connectedWidget,
    required this.notConnectedWidget,
  });

  factory LoginOption.social({
    required SocialLoginType type,
    required bool connected,
    required VoidCallback onPressed,
  }) {
    Widget loginTypeWidget;
    switch (type) {
      case SocialLoginType.google:
        loginTypeWidget = SizedBox.fromSize(
          size: Size(35, 35),
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Image.asset(
              'assets/google.png',
            ),
          ),
        );
        break;
      case SocialLoginType.apple:
        loginTypeWidget = ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.asset(
            'assets/apple.png',
            height: 35,
            width: 35,
          ),
        );
        break;
    }
    return LoginOption(
      loginTypeWidget: loginTypeWidget,
      connected: connected,
      connectedWidget: Icon(
        Icons.check_circle_outline_rounded,
        color: Colors.green,
        size: 30,
      ),
      notConnectedWidget: TextButton(
        onPressed: onPressed,
        child: Text('user-settings.login-options.social.link'.tr()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        loginTypeWidget,
        if (connected) connectedWidget else notConnectedWidget,
      ],
    );
  }
}
