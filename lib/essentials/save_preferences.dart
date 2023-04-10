import 'package:shared_preferences/shared_preferences.dart';

import 'package:csocsort_szamla/config.dart';

Future<SharedPreferences> _getPrefs() async {
  return await SharedPreferences.getInstance();
}

Future _saveString(String key, String? value) async {
  return await _getPrefs().then((prefs) {
    prefs.setString(key, value!);
  });
}

Future _saveInt(String key, int? value) async {
  return await _getPrefs().then((prefs) {
    prefs.setInt(key, value!);
  });
}

Future _saveBool(String key, bool value) async {
  return await _getPrefs().then((prefs) {
    prefs.setBool(key, value);
  });
}

Future _delete(String key) async {
  return await _getPrefs().then((prefs) {
    prefs.remove(key);
  });
}

void saveApiToken(String? newApiToken) {
  apiToken = newApiToken;
  _saveString('api_token', newApiToken);
}

void saveUsername(String? newUsername) {
  currentUsername = newUsername;
  _saveString('current_username', newUsername);
}

void saveUserId(int? newUserId) {
  currentUserId = newUserId;
  _saveInt('current_user_id', newUserId);
}

void saveUserCurrency(String? newUserCurrency) {
  currentUserCurrency = newUserCurrency;
  _saveString('current_user_currency', newUserCurrency);
}

void saveUsesPassword(bool newUsesPassword) {
  usesPassword = newUsesPassword;
  _saveBool('uses_password', newUsesPassword);
}

void saveGroupName(String? groupName) {
  currentGroupName = groupName;
  _saveString('current_group_name', groupName);
}

void saveGroupId(int? groupId) {
  currentGroupId = groupId;
  _saveInt('current_group_id', groupId);
}

void saveGroupCurrency(String? groupCurrency) {
  currentGroupCurrency = groupCurrency;
  _saveString('current_group_currency', groupCurrency);
}

void saveRatedApp(bool newRatedApp) {
  ratedApp = newRatedApp;
  _saveBool('rated_app', newRatedApp);
}

///If [usersGroupIds] are already saved locally
void saveUsersGroupIds() {
  _getPrefs().then((value) => value.setStringList('users_group_ids',
      usersGroupIds!.map<String>((e) => e.toString()).toList()));
}

///If [usersGroups] are already saved locally
void saveUsersGroups() {
  _getPrefs()
      .then((value) => value.setStringList('users_groups', usersGroups!));
}

//-------------------------------------------------------//
void deleteApiToken() {
  apiToken = null;
  _delete('api_token');
}

void deleteUsername() {
  currentUsername = null;
  _delete('current_username');
}

void deleteUserId() {
  currentUserId = null;
  _delete('current_user_id');
}

void deleteUserCurrency() {
  currentUserCurrency = null;
  _delete('current_user_currency');
}

void deleteGroupName() {
  currentGroupName = null;
  _delete('current_group_name');
}

void deleteGroupId() {
  currentGroupId = null;
  _delete('current_group_id');
}

void deleteGroupCurrency() {
  currentGroupCurrency = null;
  _delete('current_group_currency');
}

void deleteUsesPassword() {
  usesPassword = null;
  _delete('uses_password');
}

void deleteRatedApp() {
  ratedApp = false;
  _delete('rated_app');
}

void deleteUsersGroupIds() {
  usersGroups = null;
  _getPrefs().then((value) => value.remove('users_group_ids'));
}

void deleteUsersGroups() {
  usersGroups = null;
  _getPrefs().then((value) => value.remove('users_groups'));
}

Future loadAllPrefs() async {
  await _getPrefs().then((preferences) {
    if (preferences.containsKey('current_username')) {
      currentUsername = preferences.getString('current_username');
      currentUserId = preferences.getInt('current_user_id');
      currentUserCurrency = preferences.getString('current_user_currency');
      apiToken = preferences.getString('api_token');
      if (preferences.containsKey('uses_password')) {
        usesPassword = preferences.getBool('uses_password');
      } else {
        saveUsesPassword(true);
      }
    } else {
      if (preferences.containsKey('uses_password')) {
        usesPassword = preferences.getBool('uses_password');
      } else {
        saveUsesPassword(false);
      }
    }
    if (preferences.containsKey('rated_app')) {
      ratedApp = preferences.getBool('rated_app');
    } else {
      saveRatedApp(false);
    }
    if (preferences.containsKey('current_user')) {
      currentUsername = preferences.getString('current_user');
    }
    if (preferences.containsKey('current_group_name')) {
      currentGroupName = preferences.getString('current_group_name');
      currentGroupId = preferences.getInt('current_group_id');
      currentGroupCurrency = preferences.getString('current_group_currency');
    }
    if (preferences.containsKey('users_groups')) {
      usersGroups = preferences.getStringList('users_groups');
      usersGroupIds = preferences
          .getStringList('users_group_ids')!
          .map((e) => int.parse(e))
          .toList();
    }
  });
}
