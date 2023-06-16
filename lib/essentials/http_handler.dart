import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:csocsort_szamla/essentials/save_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../auth/login_or_register_page.dart';
import '../config.dart';
import '../groups/join_group.dart';
import '../groups/main_group_page.dart';

enum GetUriKeys {
  groupHasGuests("/groups/{}/has_guests"),
  groupCurrent("/groups/{}"),
  groupMember("/groups/{}/member"),
  groups("/groups"),
  userBalanceSum("/balance"),
  passwordReminder("/password_reminder"),
  groupBoost("/groups/{}/boost"),
  groupGuests("/groups/{}/guests"),
  groupUnapprovedMembers("/groups/{}/members/unapproved"),
  groupExportXls("/groups/{}/export/get_link_xls"),
  groupExportPdf("/groups/{}/export/get_link_pdf"),
  purchases("/purchases"),
  payments("/payments"),
  statisticsPayments("/groups/{}/statistics/payments"),
  statisticsPurchases("/groups/{}/statistics/purchases"),
  statisticsAll("/groups/{}/statistics/all"),
  requests("/requests");

  const GetUriKeys(this.uri);
  final String uri;
}

enum HttpType { get, post, put, delete }

///Generates URI-s from enum values. The default value of [params] is [currentGroupId].
String generateUri(
  GetUriKeys key, {
  HttpType type = HttpType.get,
  List<String>? params,
  Map<String, String?>? queryParams,
}) {
  if (type == HttpType.get) {
    if (params == null) {
      params = [currentGroupId.toString()];
    }
    String uri = key.uri;

    for (String arg in params) {
      if (uri.contains('{}')) {
        uri = uri.replaceFirst('{}', arg);
      } else {
        break;
      }
    }

    if (queryParams != null) {
      if (queryParams.values.any((element) => element != null)) {
        uri += '?';
      }
      for (String name in queryParams.keys) {
        uri += name + '=' + (queryParams[name] ?? '') + '&';
      }
    }
    return uri;
  }
  return '';
}

Widget errorToast(String msg, BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25.0),
      color: Theme.of(context).colorScheme.error,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.clear,
          color: Theme.of(context).colorScheme.onError,
        ),
        SizedBox(
          width: 12.0,
        ),
        Flexible(
            child: Text(msg.tr(),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Theme.of(context).colorScheme.onError))),
      ],
    ),
  );
}

void memberNotInGroup(BuildContext context) {
  usersGroupIds!.remove(currentGroupId);
  usersGroups!.remove(currentGroupName);
  saveUsersGroupIds();
  saveUsersGroups();
  //TODO:currency DOMINIK MEG TUDJA OLDANI, nem tudni, hogy hova kellene mennie, csak currency nelkul
  clearAllCache();
  FToast ft = FToast();
  ft.init(context);
  ft.removeQueuedCustomToasts();
  ft.showToast(
      child: errorToast('not_in_group'.tr(), context),
      toastDuration: Duration(seconds: 2),
      gravity: ToastGravity.BOTTOM);
  if (usersGroups!.length > 0) {
    currentGroupName = usersGroups![0];
    currentGroupId = usersGroupIds![0];
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => MainPage()), (r) => false);
  } else {
    currentGroupName = null;
    currentGroupId = null;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => JoinGroup(
                  fromAuth: true,
                )),
        (r) => false);
  }
}

Future<Directory> _getCacheDir() async {
  String delimiter = Platform.isWindows ? '\\' : '/';
  return Directory((await getTemporaryDirectory()).path + delimiter + 'lender');
}

Future<http.Response?> fromCache(
    {required String uri,
    required bool overwriteCache,
    bool alwaysReturnCache = false}) async {
  try {
    String s = Platform.isWindows ? '\\' : '/';
    String fileName =
        uri.replaceAll('/', '-').replaceAll('&', '-').replaceAll('?', '-');
    var cacheDir = await _getCacheDir();
    if (!cacheDir.existsSync()) {
      return null;
    }
    // print(cacheDir.listSync());
    File file = File(cacheDir.path + s + fileName);
    if (alwaysReturnCache ||
        (!overwriteCache &&
            (file.existsSync() &&
                DateTime.now().difference(await file.lastModified()).inMinutes <
                    5))) {
      // print('from cache');
      return http.Response(file.readAsStringSync(), 200);
    }
    // print('from API');
    return null;
  } catch (e) {
    //TODO: this is wrong, shouldn't be this way
    print(e.toString());
    return null;
  }
}

Future toCache({required String uri, required http.Response response}) async {
  // print('to cache');
  String s = Platform.isWindows ? '\\' : '/';
  String fileName =
      uri.replaceAll('/', '-').replaceAll('&', '-').replaceAll('?', '-');
  var cacheDir = await _getCacheDir();
  //print('itt');
  cacheDir.create();
  File file = File(cacheDir.path + s + fileName);
  file.writeAsString(response.body, flush: true, mode: FileMode.write);
}

///Deletes file at the given [uri] from the cache directory.
///The [multipleArgs] bool is used for [uri]-s where not all of the [args]
///are known at the time of the removal. (See [generateUri] function)
///In this case the [uri] becomes a search word
Future deleteCache({required String uri, bool multipleArgs = false}) async {
  if (!kIsWeb) {
    uri = uri.substring(1);
    String fileName =
        uri.replaceAll('/', '-').replaceAll('&', '-').replaceAll('?', '-');
    String separator = Platform.isWindows ? '\\' : '/';
    var cacheDir = await _getCacheDir();
    if (multipleArgs) {
      if (cacheDir.existsSync()) {
        List<FileSystemEntity> files = cacheDir.listSync();
        for (var file in files) {
          if (file is File) {
            String fileName = file.path.split(separator).last;
            if (fileName.contains(uri)) {
              file.deleteSync();
            }
          }
        }
      }
    } else {
      File file = File(cacheDir.path + separator + fileName);
      if (file.existsSync()) {
        // print('delete cache'+fileName);
        await file.delete();
      }
    }
  }
}

Future clearGroupCache() async {
  if (!kIsWeb) {
    var cacheDir = await _getCacheDir();
    String s = Platform.isWindows ? '\\' : '/';
    if (cacheDir.existsSync()) {
      List<FileSystemEntity> files = cacheDir.listSync();
      for (var file in files) {
        if (file is File) {
          String fileName = file.path.split(s).last;
          if (fileName.contains('groups-' + currentGroupId.toString()) ||
              fileName.contains('group=' + currentGroupId.toString())) {
            // print('deleting '+fileName);
            file.deleteSync();
          }
        }
      }
    }
  }
}

Future clearAllCache() async {
  if (!kIsWeb) {
    // print('all cache');
    var cacheDir = await _getCacheDir();
    if (cacheDir.existsSync()) {
      for (FileSystemEntity file in cacheDir.listSync()) {
        if (file is File) {
          file.deleteSync();
          // print(delet)
        }
      }
      // cacheDir.delete(recursive: true);
      // for (String uri in getUris) {
      //   uri =
      //       uri.replaceAll('/', '-').replaceAll('&', '-').replaceAll('?', '-');
      //   File file = File(cacheDir.path + s + uri);
      //   print(file.path);
      //   if (file.existsSync()) {
      //     file.deleteSync();
      //     print(file.path);
      //   }
      // }
    }
  }
}

Duration delayTime() {
  return Duration(milliseconds: 700);
}

Future<http.Response> httpGet({
  required BuildContext context,
  required String? uri,
  bool overwriteCache = false,
  bool useCache = true,
}) async {
  try {
    useCache = useCache && !kIsWeb;
    if (useCache) {
      http.Response? responseFromCache = await fromCache(
          uri: uri!.substring(1), overwriteCache: overwriteCache);
      if (responseFromCache != null) {
        //print('de cache!');
        await Future.delayed(Duration(milliseconds: 300 + ((Random().nextDouble() - 0.5) * 100).toInt()));
        return responseFromCache;
      }
    }
    // print(Uri.parse((useTest ? TEST_URL : APP_URL) + uri));
    //print('nem cache...');
    Map<String, String> header = {
      "Content-Type": "application/json",
      "Authorization": "Bearer " + (apiToken == null ? '' : apiToken!)
    };
    http.Response response = await http
        .get(Uri.parse((useTest ? TEST_URL : APP_URL) + uri!), headers: header);
    if (response.statusCode < 300 && response.statusCode >= 200) {
      if (useCache) toCache(uri: uri.substring(1), response: response);
      return response;
    } else {
      Map<String, dynamic> error = jsonDecode(response.body);
      if (error['error'] == 'Unauthenticated.') {
        //TODO: lehet itt dobja a random hibat
        clearAllCache();
        FToast ft = FToast();
        ft.init(context);
        ft.removeQueuedCustomToasts();
        ft.showToast(
            child: errorToast('login_required', context),
            toastDuration: Duration(seconds: 2),
            gravity: ToastGravity.BOTTOM);
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginOrRegisterPage()),
            (r) => false);
      } else if (error['error'] == 'user_not_member') {
        memberNotInGroup(context);
      }
      throw error['error'];
    }
  } on FormatException {
    throw 'format_exception';
  } on SocketException {
    http.Response? response = await fromCache(
        uri: uri!.substring(1), overwriteCache: false, alwaysReturnCache: true);
    if (response != null) {
      return response;
    }
    throw 'cannot_connect';
  } catch (_) {
    throw _;
  }
}

Future<http.Response> httpPost({
  required BuildContext context,
  required String uri,
  Map<String, dynamic>? body,
}) async {
  try {
    Map<String, String> header = {
      "Content-Type": "application/json",
      "Authorization": "Bearer " + (apiToken == null ? '' : apiToken!)
    };
    http.Response response;
    if (body != null) {
      String bodyEncoded = json.encode(body);
      response = await http.post(
          Uri.parse((useTest ? TEST_URL : APP_URL) + uri),
          headers: header,
          body: bodyEncoded);
    } else {
      response = await http.post(
          Uri.parse((useTest ? TEST_URL : APP_URL) + uri),
          headers: header);
    }

    if (response.statusCode < 300 && response.statusCode >= 200) {
      return response;
    } else {
      Map<String, dynamic> error = jsonDecode(response.body);
      if (error['error'] == 'Unauthenticated.') {
        clearAllCache();
        FToast ft = FToast();
        ft.init(context);
        ft.removeQueuedCustomToasts();
        ft.showToast(
            child: errorToast('login_required', context),
            toastDuration: Duration(seconds: 2),
            gravity: ToastGravity.BOTTOM);
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginOrRegisterPage()),
            (r) => false);
      } else if (error['error'] == 'user_not_member') {
        memberNotInGroup(context);
      }
      throw error['error'];
    }
  } on FormatException {
    throw 'format_exception';
  } on SocketException {
    throw 'cannot_connect';
  } catch (_) {
    throw _;
  }
}

Future<http.Response> httpPut({
  required BuildContext context,
  required String uri,
  Map<String, dynamic>? body,
}) async {
  try {
    Map<String, String> header = {
      "Content-Type": "application/json",
      "Authorization": "Bearer " + (apiToken == null ? '' : apiToken!)
    };
    http.Response response;
    if (body != null) {
      String bodyEncoded = json.encode(body);
      response = await http.put(Uri.parse((useTest ? TEST_URL : APP_URL) + uri),
          headers: header, body: bodyEncoded);
    } else {
      response = await http.put(Uri.parse((useTest ? TEST_URL : APP_URL) + uri),
          headers: header);
    }

    if (response.statusCode < 300 && response.statusCode >= 200) {
      return response;
    } else {
      Map<String, dynamic> error = jsonDecode(response.body);
      if (error['error'] == 'Unauthenticated.') {
        clearAllCache();
        FToast ft = FToast();
        ft.init(context);
        ft.removeQueuedCustomToasts();
        ft.showToast(
            child: errorToast('login_required', context),
            toastDuration: Duration(seconds: 2),
            gravity: ToastGravity.BOTTOM);
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginOrRegisterPage()),
            (r) => false);
      } else if (error['error'] == 'user_not_member') {
        memberNotInGroup(context);
      }
      throw error['error'];
    }
  } on FormatException {
    throw 'format_exception';
  } on SocketException {
    throw 'cannot_connect';
  } catch (_) {
    throw _;
  }
}

Future<http.Response> httpDelete(
    {required BuildContext context, required String uri}) async {
  try {
    Map<String, String> header = {
      "Content-Type": "application/json",
      "Authorization": "Bearer " + (apiToken == null ? '' : apiToken!)
    };
    http.Response response = await http.delete(
        Uri.parse((useTest ? TEST_URL : APP_URL) + uri),
        headers: header);

    if (response.statusCode < 300 && response.statusCode >= 200) {
      return response;
    } else {
      Map<String, dynamic> error = jsonDecode(response.body);
      if (error['error'] == 'Unauthenticated.') {
        clearAllCache();
        FToast ft = FToast();
        ft.init(context);
        ft.showToast(
            child: errorToast('login_required', context),
            toastDuration: Duration(seconds: 2),
            gravity: ToastGravity.BOTTOM);
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginOrRegisterPage()),
            (r) => false);
      } else if (error['error'] == 'user_not_member') {
        memberNotInGroup(context);
      }
      throw error['error'];
    }
  } on FormatException {
    throw 'format_exception';
  } on SocketException {
    throw 'cannot_connect';
  } catch (_) {
    throw _;
  }
}
