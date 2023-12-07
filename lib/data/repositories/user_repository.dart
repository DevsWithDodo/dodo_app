import 'package:csocsort_szamla/data/models/user.dart';
import 'package:csocsort_szamla/data/providers/api/user_provider.dart';
import 'package:csocsort_szamla/data/providers/local/user_provider.dart';

class UserRepository {
  final UserApiProvider _userApiProvider;
  final UserLocalProvider _userLocalProvider;

  UserRepository(this._userApiProvider, this._userLocalProvider);

  Future<User> getUser() async {
    final localUser = await _userLocalProvider.getUser();
    if (localUser != null) {
      _userApiProvider.getUser().then((value) => _userLocalProvider.updateUser(value));
      return localUser;
    }
    final apiUser = await _userApiProvider.getUser();
    _userLocalProvider.updateUser(apiUser);
    return apiUser;
  }
}