import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../config.dart';
import '../../essentials/http_handler.dart';
import '../../essentials/save_preferences.dart';
import '../../essentials/widgets/gradient_button.dart';
import '../../groups/join_group.dart';

class PersonalisedAdsPage extends StatefulWidget {
  final String? inviteUrl;
  final String? username;
  final String? pin;
  final String? defaultCurrency;

  PersonalisedAdsPage({this.inviteUrl, this.username, this.pin, this.defaultCurrency});

  @override
  State<PersonalisedAdsPage> createState() => _PersonalisedAdsPageState();
}

class _PersonalisedAdsPageState extends State<PersonalisedAdsPage> {
  bool _personalisedAds = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('register'.tr()),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ListView(
                      padding: EdgeInsets.only(left: 20, right: 20),
                      shrinkWrap: true,
                      children: <Widget>[
                        Text(
                          'we_are_concerned_your_privacy'.tr(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: TextButton(
                                onPressed: () =>
                                    launchUrlString('https://policies.google.com/privacy'),
                                child: Text(
                                  'personalised_ads'.tr(),
                                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                        decoration: TextDecoration.underline,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Switch(
                              onChanged: (newValue) => setState(() => _personalisedAds = newValue),
                              value: _personalisedAds,
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GradientButton(
                        child: Icon(
                          Icons.arrow_left,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      GradientButton(
                        child: Icon(
                          Icons.send,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => FutureSuccessDialog(
                              future:
                                  _register(widget.username, widget.pin, widget.defaultCurrency),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onRegister() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => JoinGroup(
                  fromAuth: true,
                  inviteURL: widget.inviteUrl,
                )),
        (r) => false);
  }

  Future<bool> _register(String? username, String? password, String? currency) async {
    try {
      dynamic token;
      if (isFirebasePlatformEnabled) {
        FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
        token = await _firebaseMessaging.getToken();
      }
      Map<String, dynamic> body = {
        "username": username,
        "default_currency": currency,
        "password": password,
        "password_confirmation": password,
        "fcm_token": token,
        "language": context.locale.languageCode,
        "personalised_ads": _personalisedAds ? 1 : 0
      };
      Map<String, String> header = {
        "Content-Type": "application/json",
      };

      String bodyEncoded = jsonEncode(body);
      http.Response response = await http.post(
          Uri.parse((useTest ? TEST_URL : APP_URL) + '/register'),
          headers: header,
          body: bodyEncoded);
      print(bodyEncoded);
      if (response.statusCode == 201) {
        Map<String, dynamic> decoded = jsonDecode(response.body);
        showAds = false;
        useGradients = true;
        trialVersion = true;
        saveApiToken(decoded['api_token']);
        saveUsername(decoded['username']);
        saveUserId(decoded['id']);
        saveUserCurrency(decoded['default_currency']);
        await clearAllCache();
        Future.delayed(delayTime()).then((value) => _onRegister());
        return true;
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
