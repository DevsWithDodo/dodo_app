import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import '../../config.dart';
import '../../essentials/http_handler.dart';
import '../../essentials/models.dart';
import '../../essentials/save_preferences.dart';
import '../../groups/join_group.dart';
import '../../groups/main_group_page.dart';

class LoginMethods {
  static Future<bool> _selectGroup(
      int? lastActiveGroup, BuildContext context, String? inviteUrl) async {
    try {
      http.Response response =
          await httpGet(uri: generateUri(GetUriKeys.groups), context: context);
      Map<String, dynamic> decoded = jsonDecode(response.body);
      List<Group> groups = [];
      for (var group in decoded['data']) {
        groups.add(Group(
            groupName: group['group_name'],
            groupId: group['group_id'],
            groupCurrency: group['currency']));
      }
      if (groups.length > 0) {
        usersGroups = groups.map<String>((group) => group.groupName!).toList();
        usersGroupIds = groups.map<int>((group) => group.groupId!).toList();
        saveUsersGroups();
        saveUsersGroupIds();
        if (groups
                .where((group) => group.groupId == lastActiveGroup)
                .toList()
                .length !=
            0) {
          Group currentGroup =
              groups.firstWhere((group) => group.groupId == lastActiveGroup);
          saveGroupName(currentGroup.groupName);
          saveGroupId(lastActiveGroup);
          saveGroupCurrency(currentGroup.groupCurrency);
          Future.delayed(delayTime())
              .then((value) => _onSelectGroupTrue(context, inviteUrl));
          return true;
        }
        saveGroupName(groups[0].groupName);
        saveGroupId(groups[0].groupId);
        saveGroupCurrency(groups[0].groupCurrency);
        Future.delayed(delayTime())
            .then((value) => _onSelectGroupTrue(context, inviteUrl));
        return true;
      }
      Future.delayed(delayTime())
          .then((value) => _onSelectGroupFalse(context, inviteUrl));
      return true;
    } catch (_) {
      throw _;
    }
  }

  static void _onSelectGroupTrue(BuildContext context, String? inviteUrl) {
    if (inviteUrl == null) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (context) => MainPage()), (r) => false);
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => JoinGroup(
                    inviteURL: inviteUrl,
                  )),
          (r) => false);
    }
  }

  static void _onSelectGroupFalse(BuildContext context, String? inviteUrl) {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => JoinGroup(
                  fromAuth: true,
                  inviteURL: inviteUrl,
                )),
        (r) => false);
  }

  static Future<bool> login(String? username, String password,
      BuildContext context, String? inviteUrl, bool usesPassword) async {
    print(inviteUrl);
    try {
      dynamic token;
      if (isFirebasePlatformEnabled) {
        FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
        token = await _firebaseMessaging.getToken();
      }
      Map<String, String?> body = {
        "username": username,
        "password": password,
        "fcm_token": kIsWeb ? null : token
      };
      Map<String, String> header = {"Content-Type": "application/json"};
      String bodyEncoded = jsonEncode(body);
      http.Response response = await http.post(
          Uri.parse((useTest ? TEST_URL : APP_URL) + '/login'),
          headers: header,
          body: bodyEncoded);
      if (response.statusCode == 200) {
        Map<String, dynamic> decoded = jsonDecode(response.body);
        showAds = decoded['data']['ad_free'] == 0;
        useGradients = decoded['data']['gradients_enabled'] == 1;
        trialVersion = decoded['data']['trial'] == 1;
        print(decoded['data']);
        if (decoded['data']['trial'] == null) {
          //Means that the trial just ended
          trialJustEnded = true;
        }
        saveUsername(decoded['data']['username']);
        saveUserId(decoded['data']['id']);
        saveUserCurrency(decoded['data']['default_currency']);
        saveUsesPassword(usesPassword);
        saveApiToken(decoded['data']['api_token']);
        await clearAllCache();
        return await _selectGroup(
            decoded['data']['last_active_group'], context, inviteUrl);
      } else {
        Map<String, dynamic> error = jsonDecode(response.body);
        throw error['error'];
      }
    } on FormatException {
      throw 'format_exception'.tr() + ' F01';
    } on SocketException {
      throw 'cannot_connect'.tr() + ' F02';
    } catch (_) {
      throw _;
    }
  }
}
