import 'dart:convert';

import 'package:csocsort_szamla/data/providers/api/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'http_wrapper.dart' as http;

class AuthenticationApiProvider {

  AuthenticationApiProvider(this._prefs);

  final SharedPreferences _prefs;

  Future<bool> login(String username, String password) async {
    final response = await http.post(http.generateUri('login'), body: {'username': username, 'password': password});
    final token = jsonDecode(response.body)['data']['api_token'];
    TokenManager.setToken(token, _prefs);
    return true;    
  }

  Future<bool> signUp(String username, String password) async {
    await http.post(http.generateUri('sign-up'), body: {'username': username, 'password': password});
    TokenManager.setToken('token', _prefs);
    return true;
  }

  void logOut() {
    TokenManager.setToken(null, _prefs);
  }
}