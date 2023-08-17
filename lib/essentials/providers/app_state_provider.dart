import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/app_theme.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/navigator_service.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/providers/invite_url_provider.dart';
import 'package:csocsort_szamla/groups/join_group.dart';
import 'package:csocsort_szamla/groups/main_group_page.dart';
import 'package:csocsort_szamla/main.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AppStateProvider extends ChangeNotifier {
  User? user;
  late String themeName;

  Group? get currentGroup => user?.group;
  ThemeData get theme => AppTheme.themes[themeName]!;

  AppStateProvider(BuildContext context, String themeName) {
    this.themeName = themeName;
    final preferences = context.read<SharedPreferences>();
    if (preferences.containsKey('api_token')) {
      List<String> usersGroupNames =
          preferences.getStringList('users_groups') ?? [];
      List<int> usersGroupIds = preferences
              .getStringList('users_group_ids')
              ?.map((e) => int.parse(e))
              .toList() ??
          [];
      List<String> usersGroupCurrencies =
          preferences.getStringList('users_group_currencies') ?? [];
      user = User(
        apiToken: preferences.getString('api_token')!,
        username: preferences.getString('current_username')!,
        id: preferences.getInt('current_user_id')!,
        currency: preferences.getString('current_user_currency') ?? 'EUR',
        group: preferences.containsKey('current_group_id')
            ? Group(
                id: preferences.getInt('current_group_id')!,
                name: preferences.getString('current_group_name')!,
                currency: preferences.getString('current_group_currency')!,
              )
            : null,
        groups: usersGroupNames
            .asMap()
            .map((index, value) => MapEntry(
                index,
                Group(
                  id: usersGroupIds[index],
                  name: value,
                  currency: usersGroupCurrencies.length > index ? usersGroupCurrencies[index] : 'EUR',
                )))
            .values
            .toList(),
        ratedApp: preferences.getBool('rated_app') ?? false,
        paymentMethods: [], // TODO
      );
      _fetchUserData();
    }
  }

  Future _fetchUserData() async {
    try {
      http.Response response = await http
          .get(Uri.parse((useTest ? TEST_URL : APP_URL) + '/user'), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${user!.apiToken}"
      });
      var decoded = jsonDecode(response.body);
      setShownAds(decoded['data']['ad_free'] == 0);
      setUseGradients(decoded['data']['gradients_enabled'] == 1);
      setPersonalisedAds(decoded['data']['personalised_ads'] == 1);
      setTrialVersion(decoded['data']['trial'] == 1);
      if(decoded['data']['payment_details'] != null) {
        setPaymentMethods(((jsonDecode(decoded['data']['payment_details']) as List).map((e) => PaymentMethod.fromJson(e))
            .toList()));
      }
      if (currentGroup == null &&
          decoded['data']['last_active_group'] != null) {
        Group? group = user!.groups.firstWhereOrNull(
            (element) => element.id == decoded['data']['last_active_group']);
        group ??= user!.groups.isNotEmpty ? user!.groups[0] : null;
        if (group != null) {
          setGroup(group);
        }
        getIt.get<NavigationService>().pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => MainPage()),
            );
      }
      if (!user!.useGradients &&
          !AppTheme.simpleColorThemes.contains(themeName)) {
        themeName.contains('Dark')
            ? setThemeName('greenDarkTheme')
            : setThemeName('greenLightTheme');
      }
    } catch (_) {
      throw _;
    }
  }

  Future<bool> login(
      String username, String password, BuildContext context) async {
    try {
      String? token;
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
        final preferences = context.read<SharedPreferences>();

        Map<String, dynamic> decoded = jsonDecode(response.body);
        int? lastActiveGroup = decoded['data']['last_active_group'];

        user = User(
          apiToken: decoded['data']['api_token'],
          username: decoded['data']['username'],
          id: decoded['data']['id'],
          currency: decoded['data']['default_currency'],
          group: null,
          groups: [],
          ratedApp: preferences.getBool('rated_app') ?? false,
          personalisedAds: decoded['data']['personalised_ads'] == 1,
          showAds: decoded['data']['ad_free'] == 0,
          useGradients: decoded['data']['gradients_enabled'] == 1,
          trialVersion: decoded['data']['trial'] == 1,
          paymentMethods: decoded['data']['payment_details'] != null ? jsonDecode(decoded['data']['payment_details'])
              .map((paymentMethod) => PaymentMethod.fromJson(paymentMethod))
              .toList() : [],
        );
        setUser(user, notify: false);

        http.Response groupResponse =
            await Http.get(uri: generateUri(GetUriKeys.groups, context));
        Map<String, dynamic> groupDecoded = jsonDecode(groupResponse.body);
        List<Group> groups = [];
        for (var group in groupDecoded['data']) {
          groups.add(Group(
            name: group['group_name'],
            id: group['group_id'],
            currency: group['currency'],
          ));
        }
        String? inviteUrl = context.read<InviteUrlProvider>().inviteUrl;
        setGroups(groups);
        if (groups.isEmpty) {
          Future.delayed(delayTime()).then((value) {
            getIt<NavigationService>().pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => JoinGroup(
                        fromAuth: true,
                        inviteURL: inviteUrl,
                      )),
            );
          });
          return true;
        }

        Group currentGroup = groups.firstWhere(
            (group) => group.id == lastActiveGroup,
            orElse: () => groups[0]);
        setGroup(currentGroup, notify: false);

        Future.delayed(delayTime()).then((value) {
          if (inviteUrl == null) {
            getIt<NavigationService>().pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => MainPage()),
            );
          } else {
            getIt<NavigationService>().pushAndRemoveUntil(MaterialPageRoute(
              builder: (context) => JoinGroup(
                inviteURL: inviteUrl,
              ),
            ));
          }
        });
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

  Future<bool> register(String username, String password, String currency,
      bool personalisedAds, BuildContext context) async {
    try {
      String? token;
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
        "personalised_ads": personalisedAds ? 1 : 0
      };
      Map<String, String> header = {
        "Content-Type": "application/json",
      };

      String bodyEncoded = jsonEncode(body);
      http.Response response = await http.post(
        Uri.parse((useTest ? TEST_URL : APP_URL) + '/register'),
        headers: header,
        body: bodyEncoded,
      );
      if (response.statusCode == 201) {
        Map<String, dynamic> decoded = jsonDecode(response.body);
        print(decoded);
        setUser(User(
          apiToken: decoded['api_token'],
          username: decoded['username'],
          id: decoded['id'],
          currency: decoded['default_currency'],
          group: null,
          groups: [],
          ratedApp: false,
          showAds: false,
          useGradients: true,
          personalisedAds: personalisedAds,
          trialVersion: true,
          paymentMethods: [],
        ));
        await clearAllCache();
        Future.delayed(delayTime()).then(
          (value) => getIt<NavigationService>().pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => JoinGroup(
                fromAuth: true,
                inviteURL: context.read<InviteUrlProvider>().inviteUrl,
              ),
            ),
          ),
        );
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

  Future logout({bool withoutRequest = false}) async {
    try {
      if (!withoutRequest) await Http.post(uri: '/logout', body: {});
      await clearAllCache();
      setGroup(null, notify: false);
      setGroups([], notify: false);
      setUser(null, notify: false);
    } catch (_) {
      throw _;
    }
  }

  void setGroups(List<Group> groups, {bool notify = true}) {
    user!.groups = groups;
    SharedPreferences.getInstance().then((preferences) {
      preferences.setStringList(
          'users_groups', groups.map((e) => e.name).toList());
      preferences.setStringList(
          'users_group_ids', groups.map((e) => e.id.toString()).toList());
      preferences.setStringList(
          'users_group_currencies', groups.map((e) => e.currency).toList());
    });
    if (notify) {
      notifyListeners();
    }
  }

  void setGroup(Group? group, {bool notify = true}) {
    if (group == null) {
      user!.groups.remove(user!.group);
    }
    user!.group = group;
    SharedPreferences.getInstance().then((preferences) {
      if (group == null) {
        preferences.remove('current_group_name');
        preferences.remove('current_group_id');
        preferences.remove('current_group_currency');
        return;
      }
      preferences.setString('current_group_name', group.name);
      preferences.setInt('current_group_id', group.id);
      preferences.setString('current_group_currency', group.currency);
    });
    if (notify) {
      notifyListeners();
    }
  }

  void setGroupName(String name, {bool notify = true}) {
    user!.group!.name = name;
    SharedPreferences.getInstance().then((preferences) {
      preferences.setString('current_group_name', name);
    });
    if (notify) {
      notifyListeners();
    }
  }

  void setGroupCurrency(String currency, {bool notify = true}) {
    user!.group!.currency = currency;
    SharedPreferences.getInstance().then((preferences) {
      preferences.setString('current_group_currency', currency);
    });
    if (notify) {
      notifyListeners();
    }
  }

  void setUser(User? user, {bool notify = true}) {
    this.user = user;
    SharedPreferences.getInstance().then((preferences) {
      if (user == null) {
        preferences.remove('current_user_id');
        preferences.remove('current_user_currency');
        preferences.remove('api_token');
        preferences.remove('rated_app');
        return;
      }
      preferences.setString('current_username', user.username);
      preferences.setInt('current_user_id', user.id);
      preferences.setString('current_user_currency', user.currency);
      preferences.setString('api_token', user.apiToken);
      preferences.setBool('rated_app', user.ratedApp);
    });
    if (notify) {
      notifyListeners();
    }
  }

  void setUserCurrency(String currency, {bool notify = true}) {
    user!.currency = currency;
    SharedPreferences.getInstance().then((preferences) {
      preferences.setString('current_user_currency', currency);
    });
    if (notify) {
      notifyListeners();
    }
  }

  void setUsername(String name, {bool notify = true}) {
    user!.username = name;
    SharedPreferences.getInstance().then((preferences) {
      preferences.setString('current_username', name);
    });
    if (notify) {
      notifyListeners();
    }
  }

  void setRatedApp(bool ratedApp, {bool notify = true}) {
    user!.ratedApp = ratedApp;
    SharedPreferences.getInstance().then((preferences) {
      preferences.setBool('rated_app', ratedApp);
    });
    if (notify) {
      notifyListeners();
    }
  }

  void setUseGradients(bool useGradients, {bool notify = true}) {
    user!.useGradients = useGradients;
    if (notify) {
      notifyListeners();
    }
  }

  void setPersonalisedAds(bool personalisedAds, {bool notify = true}) {
    user!.personalisedAds = personalisedAds;
    if (notify) {
      notifyListeners();
    }
  }

  void setTrialVersion(bool trialVersion, {bool notify = true}) {
    user!.trialVersion = trialVersion;
    if (notify) {
      notifyListeners();
    }
  }

  void setShownAds(bool showAds, {bool notify = true}) {
    user!.showAds = showAds;
    if (notify) {
      notifyListeners();
    }
  }

  void setThemeName(String themeName, {bool notify = true}) {
    this.themeName = themeName;
    SharedPreferences.getInstance().then((preferences) {
      preferences.setString('theme', themeName);
    });
    if (notify) {
      notifyListeners();
    }
  }

  void setPaymentMethods(List<PaymentMethod> paymentMethods,
      {bool notify = true}) {
    user!.paymentMethods = paymentMethods;
    if (notify) {
      notifyListeners();
    }
  }
}
