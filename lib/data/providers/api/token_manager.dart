import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static String? _token;

  static void setToken(String? token, SharedPreferences prefs) {
    _token = token;
    if (token == null) {
      prefs.remove('token');
    } else {
      prefs.setString('token', token);
    }
  }

  static String? getToken() {
    return _token;
  }
}