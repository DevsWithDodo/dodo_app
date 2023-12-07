import 'dart:convert';

import 'package:csocsort_szamla/data/models/user.dart';
import 'http_wrapper.dart' as http;

class UserApiProvider {
  Future<User> getUser() async {
    final response = await http.get(http.generateUri('users.show', params: {'id': "me"}));
    final decoded = jsonDecode(response.body);
    return User(
      username: decoded['data']['username'],
      id: decoded['data']['id'],
      currency: decoded['data']['default_currency'],
      group: null,
      groups: [],
      personalisedAds: decoded['data']['personalised_ads'] == 1,
      showAds: decoded['data']['ad_free'] == 0,
      useGradients: decoded['data']['gradients_enabled'] == 1,
      trialVersion: decoded['data']['trial'] == 1,
      paymentMethods: [],
    );
  }

  Future<User> updateUser(User user) async {
    await Future.delayed(Duration(seconds: 1));
    return user;
  }

  Future deleteUser(User user) async {
    await Future.delayed(Duration(seconds: 1));
  }
}
