import 'dart:async';

import 'package:csocsort_szamla/data/providers/api/authentication_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthenticationStatus { unknown, authenticated, unauthenticated }

class AuthenticationRepository {
  final AuthenticationApiProvider _authenticationProvider;
  final SharedPreferences _prefs;

  final _controller = StreamController<AuthenticationStatus>();

  Stream<AuthenticationStatus> get status async* {
    if (_prefs.containsKey('token')) {
      yield AuthenticationStatus.authenticated;
    } else {
      yield AuthenticationStatus.unauthenticated;
    }
    yield* _controller.stream;
  }

  AuthenticationRepository(this._authenticationProvider, this._prefs);

  Future login(String username, String password) async {
    await _authenticationProvider.login(username, password);
    _controller.add(AuthenticationStatus.authenticated);
  }

  Future signUp(String username, String password) async {
    await _authenticationProvider.signUp(username, password);
    _controller.add(AuthenticationStatus.authenticated);
  }

  void logOut() {
    _authenticationProvider.logOut();
    _controller.add(AuthenticationStatus.unauthenticated);
  }

  void dispose() => _controller.close();

}