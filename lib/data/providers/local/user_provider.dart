import 'package:csocsort_szamla/data/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserLocalProvider {

  SharedPreferences _prefs;

  UserLocalProvider(this._prefs);

  Future<User?> getUser() async {
    if (!_prefs.containsKey('user_id')) {
      return null;
    }
    return User(
      id: _prefs.getInt('user_id')!,
      username: _prefs.getString('username')!,
      currency: 'HUF',
    );
  }

  Future<User> updateUser(User user) async {
    await _prefs.setInt('user_id', user.id);
    await _prefs.setString('username', user.username);
    return user;
  }
}