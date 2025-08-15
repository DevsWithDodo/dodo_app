// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/navigator_service.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/helpers/providers/invite_url_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_usage_provider.dart';
import 'package:csocsort_szamla/main.dart';
import 'package:csocsort_szamla/pages/app/main_page.dart';
import 'package:csocsort_szamla/pages/auth/login_or_register_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum IdTokenType { google, apple }

class UserProvider extends StatelessWidget {
  UserProvider({
    required BuildContext context,
    required this.builder,
    super.key,
  }) : _userState = UserNotifier(context);

  late final UserNotifier _userState;
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _userState,
      builder: (context, _) => builder(context),
    );
  }
}

class UserNotifier extends ChangeNotifier {
  User? user;
  Group? get currentGroup => user?.group;
  late UserUsageNotifier usage;

  UserNotifier(BuildContext context) {
    final preferences = context.read<SharedPreferences>();
    usage = context.read<UserUsageNotifier>();
    if (preferences.containsKey('api_token')) {
      user = User.fromPreferences(preferences);
      _fetchUser(context);
    }
  }

  Future _fetchUser(BuildContext context) async {
    http.Response response = await http.get(Uri.parse('${context.read<AppConfig>().appUrl}/user'), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${user!.apiToken}",
    });
    var decoded = jsonDecode(response.body);
    if (response.statusCode.httpStatusCodeRange != HttpStatusCodeRange.success) {
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
    User fetchedUser = User.fromJson(decoded['data']);
    setUser(user!.mergeWith(fetchedUser), notify: false);
    int? lastActiveGroup = decoded['data']['last_active_group'];

    http.Response groupResponse = await Http.get(uri: generateUri(GetUriKeys.groups, context));
    setGroups(Group.fromJsonList(jsonDecode(groupResponse.body)['data'], true));

    if (currentGroup == null && user!.groups.isNotEmpty) {
      Group group = user!.groups.firstWhere((element) => element.id == lastActiveGroup, orElse: () => user!.groups[0]);
      setGroup(group);
      getIt.get<NavigationService>().pushAndRemoveUntil(MaterialPageRoute(builder: (context) => MainPage()));
    }
    var themeState = context.read<AppThemeState>();
    if (!user!.useGradients && themeState.themeName.type != ThemeType.simpleColor) {
      themeState.themeName =
          themeState.themeName.brightness == Brightness.dark ? ThemeName.greenDark : ThemeName.greenLight;
    }
  }

  Future<LoginFutureOutputs> loginOrRegisterWithToken(
      String? idToken, String? authCode, IdTokenType tokenType, BuildContext context) async {
    assert(
        (idToken != null && tokenType == IdTokenType.google) || (authCode != null && tokenType == IdTokenType.apple));
    try {
      String? fcmToken;
      if (context.read<AppConfig>().isFirebasePlatformEnabled) {
        FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
        fcmToken = await firebaseMessaging.getToken();
      }
      Map<String, String?> body = {
        ...(tokenType == IdTokenType.google ? {"id_token": idToken!} : {"auth_code": authCode!}),
        'device_type': kIsWeb ? 'web' : Platform.operatingSystem,
        "fcm_token": kIsWeb ? null : fcmToken,
        "token_type": tokenType.name,
        "language": context.locale.languageCode,
      };
      Map<String, String> header = {"Content-Type": "application/json"};
      String bodyEncoded = jsonEncode(body);
      http.Response response = await http.post(
        Uri.parse('${context.read<AppConfig>().appUrl}/register-with-token'),
        headers: header,
        body: bodyEncoded,
      );
      if (response.statusCode.httpStatusCodeRange == HttpStatusCodeRange.success) {
        Map<String, dynamic> decoded = jsonDecode(response.body);
        int? lastActiveGroup = decoded['data']['last_active_group'];
        user = User.fromJson(decoded['data'], false);
        setUser(user, notify: false);

        http.Response groupResponse = await Http.get(uri: generateUri(GetUriKeys.groups, context));
        List<Group> groups = Group.fromJsonList(jsonDecode(groupResponse.body)['data'], true);
        setGroups(groups);
        if (groups.isEmpty) {
          return LoginFutureOutputs.joinGroupFromAuth;
        }

        Group currentGroup = groups.firstWhere((group) => group.id == lastActiveGroup, orElse: () => groups[0]);
        setGroup(currentGroup, notify: false);

        String? inviteUrl = context.read<InviteUrlState>().inviteUrl;
        return inviteUrl == null ? LoginFutureOutputs.main : LoginFutureOutputs.joinGroup;
      } else {
        Map<String, dynamic> error = jsonDecode(response.body);
        throw error['error'];
      }
    } on FormatException {
      throw '${'format_exception'.tr()} F01';
    } on SocketException {
      throw '${'cannot_connect'.tr()} F02';
    } catch (_) {
      rethrow;
    }
  }

  Future<BoolFutureOutput> linkSocialLogin(IdTokenType idTokenType, String code) async {
    final response = await Http.post(uri: "/user/link_social_login", body: {
      "token_type": idTokenType.name,
      ...(idTokenType == IdTokenType.google ? {"id_token": code} : {"auth_code": code}),
      'device_type': kIsWeb ? 'web' : Platform.operatingSystem,
    });

    if (response.statusCode.httpStatusCodeRange != HttpStatusCodeRange.success) {
      Map<String, dynamic> error = jsonDecode(response.body);
      throw error['error'];
    }

    final decoded = jsonDecode(response.body);
    setUser(user!.mergeWith(User.fromJson(decoded['data'], user!.ratedApp)));

    return BoolFutureOutput.True;
  }

  Future<LoginFutureOutputs> login(String username, String password, BuildContext context) async {
    try {
      String? token;
      if (context.read<AppConfig>().isFirebasePlatformEnabled) {
        FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
        token = await firebaseMessaging.getToken();
      }
      Map<String, String?> body = {
        "username": username,
        "password": password,
        "fcm_token": kIsWeb ? null : token,
      };
      Map<String, String> header = {"Content-Type": "application/json"};
      String bodyEncoded = jsonEncode(body);
      http.Response response =
          await http.post(Uri.parse('${context.read<AppConfig>().appUrl}/login'), headers: header, body: bodyEncoded);
      if (response.statusCode.httpStatusCodeRange == HttpStatusCodeRange.success) {
        final preferences = context.read<SharedPreferences>();

        Map<String, dynamic> decoded = jsonDecode(response.body);
        int? lastActiveGroup = decoded['data']['last_active_group'];
        user = User.fromJson(decoded['data'], preferences.getBool('rated_app'));
        setUser(user, notify: false);

        http.Response groupResponse = await Http.get(uri: generateUri(GetUriKeys.groups, context));
        List<Group> groups = Group.fromJsonList(jsonDecode(groupResponse.body)['data'], true);
        setGroups(groups);
        if (groups.isEmpty) {
          return LoginFutureOutputs.joinGroupFromAuth;
        }

        Group currentGroup = groups.firstWhere((group) => group.id == lastActiveGroup, orElse: () => groups[0]);
        setGroup(currentGroup, notify: false);

        String? inviteUrl = context.read<InviteUrlState>().inviteUrl;
        return inviteUrl == null ? LoginFutureOutputs.main : LoginFutureOutputs.joinGroup;
      } else {
        Map<String, dynamic> error = jsonDecode(response.body);
        throw error['error'];
      }
    } on FormatException {
      throw '${'format_exception'.tr()} F01';
    } on SocketException {
      throw '${'cannot_connect'.tr()} F02';
    } catch (_) {
      rethrow;
    }
  }

  Future<BoolFutureOutput> register(String username, String password, Currency currency, BuildContext context) async {
    try {
      String? token;
      if (context.read<AppConfig>().isFirebasePlatformEnabled) {
        FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
        token = await firebaseMessaging.getToken();
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

      String bodyEncoded = json.encode(body, toEncodable: (e) => e.toString());
      http.Response response = await http.post(
        Uri.parse('${context.read<AppConfig>().appUrl}/register'),
        headers: header,
        body: bodyEncoded,
      );
      if (response.statusCode.httpStatusCodeRange == HttpStatusCodeRange.success) {
        setUser(User.fromJson(jsonDecode(response.body)));
        await clearAllCache();
        return BoolFutureOutput.True;
      } else {
        Map<String, dynamic> error = jsonDecode(response.body);
        throw error['error'];
      }
    } on FormatException {
      throw '${'format_exception'.tr()} F01';
    } on SocketException {
      throw '${'cannot_connect'.tr()} F02';
    } catch (_, __) {
      rethrow;
    }
  }

  Future logout({bool withoutRequest = false}) async {
    try {
      if (!withoutRequest) await Http.post(uri: '/logout', body: {});
      await clearAllCache();
      setGroup(null, notify: false);
      setGroups([], notify: false);
      setUser(null, notify: false);
      usage.reset();
    } catch (_) {
      rethrow;
    }
  }

  void setGroups(List<Group> groups, {bool notify = true}) {
    user!.groups = groups;
    SharedPreferences.getInstance().then((preferences) {
      preferences.setStringList('users_groups', groups.map((e) => e.name).toList());
      preferences.setStringList('users_group_ids', groups.map((e) => e.id.toString()).toList());
      preferences.setStringList('users_group_currencies', groups.map((e) => e.currency.code).toList());
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
      preferences.setString('current_group_currency', group.currency.code);
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

  void setGroupCurrency(Currency currency, {bool notify = true}) {
    user!.group!.currency = currency;
    SharedPreferences.getInstance().then((preferences) {
      preferences.setString('current_group_currency', currency.code);
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
      if (user.username != null) {
        preferences.setString('current_username', user.username!);
      }
      preferences.setInt('current_user_id', user.id);
      preferences.setString('current_user_currency', user.currency.code);
      preferences.setString('api_token', user.apiToken);
      preferences.setBool('rated_app', user.ratedApp);
    });
    if (notify) {
      notifyListeners();
    }
  }

  void setUserCurrency(String currency, {bool notify = true}) {
    user!.currency = Currency.fromCode(currency);
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

  void setShowAds(bool showAds, {bool notify = true}) {
    user!.showAds = showAds;
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
