import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/join_group_page.dart';
import 'package:csocsort_szamla/pages/app/main_page.dart';
import 'package:csocsort_szamla/pages/auth/name_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _doubleTapped = false;
  bool _tapped = false;
  // final List<String> scopes = <String>[
  //   'email',
  //   'https://www.googleapis.com/auth/contacts.readonly',
  // ];

  // GoogleSignIn _googleSignIn = GoogleSignIn(
  //   // Optional clientId
  //   // clientId: 'your-client_id.apps.googleusercontent.com',
  //   scopes: scopes,
  // );

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appConfig = context.read<AppConfig>();
      if (appConfig.useTest) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          duration: Duration(hours: 10),
          content: Text(
            'Test Mode',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.onSecondary),
          ),
          action: SnackBarAction(
            label: 'Back to Normal Mode',
            textColor: Theme.of(context).colorScheme.onSecondary,
            onPressed: () {
              setState(() {
                appConfig.useTest = !appConfig.useTest;
                _tapped = false;
                _doubleTapped = false;
              });
            },
          ),
        ));
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.read<AppConfig>();
    return Scaffold(
      key: _scaffoldKey,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: GestureDetector(
                  onTap: () {
                    _tapped = true;
                    _doubleTapped = false;
                  },
                  onDoubleTap: () {
                    if (_tapped) {
                      _doubleTapped = true;
                    }
                  },
                  onLongPress: () {
                    if (_tapped && _doubleTapped) {
                      setState(() {
                        if (!appConfig.useTest) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            duration: Duration(hours: 10),
                            content: Text(
                              'Test Mode',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge!
                                  .copyWith(color: Theme.of(context).colorScheme.onSecondary),
                            ),
                            action: SnackBarAction(
                              label: 'Back to Normal Mode',
                              textColor: Theme.of(context).colorScheme.onSecondary,
                              onPressed: () {
                                setState(() {
                                  appConfig.useTest = !appConfig.useTest;
                                  _tapped = false;
                                  _doubleTapped = false;
                                });
                              },
                            ),
                          ));
                        } else {
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        }
                        clearAllCache();
                        appConfig.useTest = !appConfig.useTest;
                        _tapped = false;
                        _doubleTapped = false;
                      });
                    }
                  },
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary,
                        context.watch<AppThemeState>().themeName.isDodo() && !kIsWeb ? BlendMode.dst : BlendMode.srcIn),
                    child: Image(
                      image: AssetImage('assets/dodo.png'),
                      height: MediaQuery.of(context).size.width / 3,
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'title'.tr().toUpperCase(),
                  style: TextStyle(
                      fontSize: 50, fontWeight: FontWeight.w300, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
              Flexible(
                  child: Text(
                'subtitle'.tr().toUpperCase(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.1,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              )),
              Flexible(
                child: SizedBox(
                  height: 50,
                ),
              ),
              GradientButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NamePage(
                        isLogin: true,
                      ),
                    ),
                  );
                },
                child: Text(
                  'login'.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 15),
              GradientButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NamePage(),
                    ),
                  );
                },
                child: Text(
                  'register'.tr(),
                ),
              ),
              SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(50),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(
                          'assets/google.png',
                          height: 20,
                          width: 20,
                        ),
                      ),
                    ),
                    onTap: () async {
                      final googleAuth = await getGoogleAuth(
                        context.read<AppConfig>().googleOAuthServerClientId,
                      );
                      if (googleAuth?.idToken == null) return;
                      _registerWithToken(IdTokenType.google, googleAuth!.idToken!);
                    },
                  ),
                  SizedBox(width: 10),
                  IconButton.outlined(
                    icon: Icon(Icons.privacy_tip),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('social-login.privacy-notice.title').tr(),
                        content: Text('social-login.privacy-notice.content').tr(),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('back').tr(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () async {
                      final appConfig = context.read<AppConfig>();
                      final credential = await getAppleAuth(
                        appConfig.appleOAuthClientId,
                        appConfig.appUrl,
                      );
                      _registerWithToken(IdTokenType.apple, credential.authorizationCode);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        'assets/apple.png',
                        height: 44,
                        width: 44,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _registerWithToken(IdTokenType idTokenType, String code) {
    showFutureOutputDialog(
      context: context,
      future: context.read<UserNotifier>().loginOrRegisterWithToken(
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
              MaterialPageRoute(builder: (context) => JoinGroupPage()),
              (route) => false,
            ),
        LoginFutureOutputs.joinGroupFromAuth: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => JoinGroupPage(
                        fromAuth: true,
                      )),
              (route) => false,
            ),
      },
    );
  }
}
