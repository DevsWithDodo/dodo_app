import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csocsort_szamla/auth/login_or_register_page.dart';
import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/app_theme.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/navigator_service.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/providers/invite_url_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
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
  late ThemeName _themeName;

  ThemeName get themeName => AppTheme.themes.containsKey(_themeName)
      ? _themeName
      : _themeName.brightness == Brightness.dark
          ? ThemeName.dodoDark
          : ThemeName.dodoLight;
  Group? get currentGroup => user?.group;
  ThemeData get theme {
    return AppTheme.themes[themeName] ?? AppTheme.generateThemeData(ThemeName.greenLight, Colors.lightGreen).value;
  }

  AppStateProvider(BuildContext context, ThemeName themeName) {
    this._themeName = themeName;
    final preferences = context.read<SharedPreferences>();
    if (preferences.containsKey('api_token')) {
      List<String> usersGroupNames = preferences.getStringList('users_groups') ?? [];
      List<int> usersGroupIds = preferences.getStringList('users_group_ids')?.map((e) => int.parse(e)).toList() ?? [];
      List<String> usersGroupCurrencies = preferences.getStringList('users_group_currencies') ?? [];
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
          paymentMethods: [],
          userStatus: UserStatus(
            pinVerificationCount: 100,
            pinVerifiedAt: DateTime.now(),
            trialStatus: TrialStatus.seen,
          ));
      _fetchUserData();
    }
  }

  Future _fetchUserData() async {
    try {
      http.Response response = await http.get(Uri.parse((useTest ? TEST_URL : APP_URL) + '/user'),
          headers: {"Content-Type": "application/json", "Authorization": "Bearer ${user!.apiToken}"});
      var decoded = jsonDecode(response.body);
      if (response.statusCode > 299 || response.statusCode < 200) {
        if (response.statusCode == 401) {
          await logout(withoutRequest: true);
          BuildContext? context = getIt.get<NavigationService>().navigatorKey.currentContext;
          if (context == null) return;
          Navigator.of(getIt.get<NavigationService>().navigatorKey.currentContext!).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginOrRegisterPage()),
            (route) => false,
          );
          return;
        }
      }
      setShownAds(decoded['data']['ad_free'] == 0);
      setUseGradients(decoded['data']['gradients_enabled'] == 1);
      setPersonalisedAds(decoded['data']['personalised_ads'] == 1);
      setTrialVersion(decoded['data']['trial'] == 1);
      if (decoded['data']['payment_details'] != null) {
        setPaymentMethods(
            (jsonDecode(decoded['data']['payment_details']) as List).map((e) => PaymentMethod.fromJson(e)).toList());
      }
      if (decoded['data']['status'] != null) {
        setUserStatus(UserStatus.fromJson(decoded['data']['status']));
      }
      if (currentGroup == null && decoded['data']['last_active_group'] != null) {
        Group? group = user!.groups.firstWhereOrNull((element) => element.id == decoded['data']['last_active_group']);
        group ??= user!.groups.isNotEmpty ? user!.groups[0] : null;
        if (group != null) {
          setGroup(group);
        }
        getIt.get<NavigationService>().pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => MainPage()),
            );
      }
      if (!user!.useGradients && themeName.type != ThemeType.simpleColor) {
        themeName.brightness == Brightness.dark
            ? setThemeName(ThemeName.greenDark)
            : setThemeName(ThemeName.greenLight);
      }
    } catch (_) {
      throw _;
    }
  }

  Future<LoginFutureOutputs> login(String username, String password, BuildContext context) async {
    try {
      String? token;
      if (isFirebasePlatformEnabled) {
        FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
        token = await _firebaseMessaging.getToken();
      }
      Map<String, String?> body = {"username": username, "password": password, "fcm_token": kIsWeb ? null : token};
      Map<String, String> header = {"Content-Type": "application/json"};
      String bodyEncoded = jsonEncode(body);
      http.Response response =
          await http.post(Uri.parse((useTest ? TEST_URL : APP_URL) + '/login'), headers: header, body: bodyEncoded);
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
          paymentMethods: decoded['data']['payment_details'] != null
              ? (jsonDecode(decoded['data']['payment_details']) as List).map((e) => PaymentMethod.fromJson(e)).toList()
              : [],
          userStatus: decoded['data']['status'] != null
              ? UserStatus.fromJson(decoded['data']['status'])
              : UserStatus(
                  trialStatus: TrialStatus.seen,
                  pinVerifiedAt: DateTime.now(),
                  pinVerificationCount: 100,
                ),
        );
        setUser(user, notify: false);

        http.Response groupResponse = await Http.get(uri: generateUri(GetUriKeys.groups, context));
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
          return LoginFutureOutputs.joinGroupFromAuth;
        }

        Group currentGroup = groups.firstWhere((group) => group.id == lastActiveGroup, orElse: () => groups[0]);
        setGroup(currentGroup, notify: false);

        return inviteUrl == null ? LoginFutureOutputs.main : LoginFutureOutputs.joinGroup;
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

  Future<BoolFutureOutput> register(
      String username, String password, String currency, BuildContext context) async {
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
          personalisedAds: false,
          trialVersion: true,
          paymentMethods: [],
          userStatus: UserStatus.fromJson(decoded['status']),
        ));
        await clearAllCache();
        return BoolFutureOutput.True;
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
      preferences.setStringList('users_groups', groups.map((e) => e.name).toList());
      preferences.setStringList('users_group_ids', groups.map((e) => e.id.toString()).toList());
      preferences.setStringList('users_group_currencies', groups.map((e) => e.currency).toList());
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

  void setThemeName(ThemeName themeName, {bool notify = true}) {
    this._themeName = themeName;
    SharedPreferences.getInstance().then((preferences) {
      preferences.setString('theme', themeName.storageName);
    });
    if (notify) {
      notifyListeners();
    }
  }

  void setPaymentMethods(List<PaymentMethod> paymentMethods, {bool notify = true}) {
    user!.paymentMethods = paymentMethods;
    if (notify) {
      notifyListeners();
    }
  }

  void setUserStatus(UserStatus userStatus, {bool notify = true}) {
    user!.userStatus = userStatus;
    if (notify) {
      notifyListeners();
    }
  }
}

class LoginFutureOutputs extends FutureOutput {
  static const main = LoginFutureOutputs(true, 'main');
  static const joinGroup = LoginFutureOutputs(true, 'joinGroup');
  static const joinGroupFromAuth = LoginFutureOutputs(true, 'joinGroupFromAuth');

  const LoginFutureOutputs(super.value, super.name);
}
