import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/user_settings/cards/change_password_dialog.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/invite_url_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/join_group_page.dart';
import 'package:csocsort_szamla/pages/app/main_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginOptions extends StatefulWidget {
  const LoginOptions({super.key});

  @override
  State<LoginOptions> createState() => _LoginOptionsState();
}

class _LoginOptionsState extends State<LoginOptions> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserState>().user!;
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Text(
                        'user-settings.login-options.pin'.tr(),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (user.hasPassword)
                      Row(
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
                      )
                    else
                      TextButton(
                        onPressed: () {},
                        child: Text('TODO user-settings.login-options.set-pin'.tr()),
                      ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox.fromSize(
                      size: Size(35, 35),
                      child: Padding(
                        padding: EdgeInsets.all(5),
                        child: Image.asset(
                          'assets/google.png',
                        ),
                      ),
                    ),
                    if (user.googleConnected)
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        size: 30,
                      )
                    else
                      TextButton(
                        onPressed: () async {
                          final GoogleSignInAccount? googleUser = await GoogleSignIn(
                            serverClientId: context.read<AppConfig>().googleOAuthServerClientId,
                            scopes: [
                              'openid',
                            ],
                          ).signIn();
                          final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
                          if (googleAuth?.idToken == null) return;
                          _registerWithToken(IdTokenType.google, googleAuth!.idToken!);
                        },
                        child: Text('user-settings.login-options.social.link'.tr()),
                      ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        'assets/apple.png',
                        height: 35,
                        width: 35,
                      ),
                    ),
                    if (user.appleConnected)
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        size: 30,
                      )
                    else
                      TextButton(
                        onPressed: () async {
                          final credential = await SignInWithApple.getAppleIDCredential(
                            scopes: [],
                            webAuthenticationOptions: WebAuthenticationOptions(
                              clientId: 'net.dodoapp.dodo',
                              redirectUri: Uri.parse('${context.read<AppConfig>().appUrl}/callbacks/sign-in-with-apple'),
                            ),
                          );
                          _registerWithToken(IdTokenType.apple, credential.authorizationCode);
                        },
                        child: Text('user-settings.login-options.social.link'.tr()),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _registerWithToken(IdTokenType idTokenType, String code) {
    showFutureOutputDialog(
      context: context,
      future: context.read<UserState>().loginOrRegisterWithToken(
            idTokenType == IdTokenType.google ? code : null,
            idTokenType == IdTokenType.apple ? code : null,
            idTokenType,
            context,
          ),
      outputCallbacks: {
        LoginFutureOutputs.main: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainPage(),
            ),
            (r) => false),
        LoginFutureOutputs.joinGroup: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => JoinGroupPage(
                        inviteURL: context.read<InviteUrlState>().inviteUrl,
                      )),
              (route) => false,
            ),
        LoginFutureOutputs.joinGroupFromAuth: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => JoinGroupPage(
                        inviteURL: context.read<InviteUrlState>().inviteUrl,
                        fromAuth: true,
                      )),
              (route) => false,
            ),
      },
    );
  }
}
