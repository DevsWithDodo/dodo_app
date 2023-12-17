import 'package:csocsort_szamla/bloc/authentication/authentication_bloc.dart';
import 'package:csocsort_szamla/data/providers/api/authentication_provider.dart';
import 'package:csocsort_szamla/data/providers/api/user_provider.dart';
import 'package:csocsort_szamla/data/providers/local/user_provider.dart';
import 'package:csocsort_szamla/data/repositories/authentication_repository.dart';
import 'package:csocsort_szamla/data/repositories/user_repository.dart';
import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/pages/app/main_page.dart';
import 'package:csocsort_szamla/pages/auth/login_or_register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class App extends StatefulWidget {
  const App(this.prefs, {super.key});

  final SharedPreferences prefs;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthenticationRepository _authenticationRepository;
  late final UserRepository _userRepository;

  @override
  void initState() {
    super.initState();
    
    _authenticationRepository = AuthenticationRepository(AuthenticationApiProvider(widget.prefs), widget.prefs);
    _userRepository = UserRepository(UserApiProvider(), UserLocalProvider(widget.prefs));
  }

  @override
  void dispose() {
    _authenticationRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _authenticationRepository,
      child: BlocProvider(
        create: (_) => AuthenticationBloc(
          authenticationRepository: _authenticationRepository,
          userRepository: _userRepository,
        ),
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator => _navigatorKey.currentState!;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.themes[ThemeName.dodoLight],
      navigatorKey: _navigatorKey,
      builder: (context, child) {
        return BlocListener<AuthenticationBloc, AuthenticationState>( 
          listener: (context, state) {
            switch (state.status) {
              case AuthenticationStatus.authenticated:
                _navigator.pushAndRemoveUntil<void>(
                  MaterialPageRoute(builder: (context) => MainPage()),
                  (route) => false,
                );
              case AuthenticationStatus.unauthenticated:
                _navigator.pushAndRemoveUntil<void>(
                  MaterialPageRoute(builder: (context) => LoginOrRegisterPage()),
                  (route) => false,
                );
              default:
                break;
            }
          },
          child: child,
        );
      },
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const Scaffold()),
    );
  }
}
