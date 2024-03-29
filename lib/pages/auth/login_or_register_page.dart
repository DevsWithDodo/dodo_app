import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csocsort_szamla/pages/auth/name_page.dart';
import 'package:provider/provider.dart';

class LoginOrRegisterPage extends StatefulWidget {
  LoginOrRegisterPage();

  @override
  _LoginOrRegisterPageState createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _doubleTapped = false;
  bool _tapped = false;
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
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            duration: Duration(hours: 10),
                            content: Text(
                              'Test Mode',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondary),
                            ),
                            action: SnackBarAction(
                              label: 'Back to Normal Mode',
                              textColor:
                                  Theme.of(context).colorScheme.onSecondary,
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
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.primary,
                        context.watch<AppThemeState>().themeName.isDodo() &&
                                !kIsWeb
                            ? BlendMode.dst
                            : BlendMode.srcIn),
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
                      fontSize: 50,
                      fontWeight: FontWeight.w300,
                      color: Theme.of(context).colorScheme.onSurface),
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
                      builder: (context) => NamePage(
                      ),
                    ),
                  );
                },
                child: Text(
                  'register'.tr(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
