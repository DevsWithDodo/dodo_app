import 'dart:convert';
import 'dart:io' show Platform;
import 'package:csocsort_szamla/auth/login_or_register_page.dart';
import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/ad_management.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/save_preferences.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/user_settings/user_settings_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../essentials/models.dart';
import '../essentials/validation_rules.dart';
import 'create_group.dart';
import 'merge_on_join_page.dart';
import 'qr_scanner_page.dart';
import 'main_group_page.dart';

class JoinGroup extends StatefulWidget {
  final bool fromAuth;
  final String? inviteURL;

  JoinGroup({this.fromAuth = false, this.inviteURL});

  @override
  _JoinGroupState createState() => _JoinGroupState();
}

class _JoinGroupState extends State<JoinGroup> {
  TextEditingController _tokenController = TextEditingController();
  TextEditingController _nicknameController = TextEditingController(
      text: currentUsername![0].toUpperCase() + currentUsername!.substring(1));

  var _formKey = GlobalKey<FormState>();

  Future _logout() async {
    try {
      await clearAllCache();
      await httpPost(context: context, uri: '/logout', body: {});
      deleteApiToken();
      deleteUserId();
      deleteUserCurrency();
      deleteUsesPassword();
      deleteGroupId();
      deleteGroupName();
    } catch (_) {
      throw _;
    }
  }

  Future<bool> _joinGroup(String token, String nickname) async {
    try {
      Map<String, dynamic> body = {
        'invitation_token': token,
        'nickname': nickname
      };
      http.Response response =
          await httpPost(uri: '/join', context: context, body: body);

      if (response.body != "") {
        Map<String, dynamic> decoded = jsonDecode(response.body);
        saveGroupName(decoded['data']['group_name']);
        saveGroupId(decoded['data']['group_id']);
        saveGroupCurrency(decoded['data']['currency']);
        if (usersGroups == null) {
          usersGroupIds = <int>[];
          usersGroups = <String>[];
        }
        usersGroupIds!.add(decoded['data']['group_id']);
        usersGroups!.add(decoded['data']['group_name']);
        saveUsersGroupIds();
        saveUsersGroups();
        print(decoded['data']['members']);
        List<Member> guests = (decoded['data']['members'] as List<dynamic>)
            .where((element) => element['is_guest'] == 1)
            .map((e) => Member.fromJson(e))
            .toList();
        if (guests.isNotEmpty) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MergeOnJoinPage(
                guests: guests,
              ),
            ),
          );
        }
        Future.delayed(delayTime()).then((value) => _onJoinGroup());
      } else {
        return false;
      }

      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onJoinGroup() async {
    await clearAllCache();
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => MainPage()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_tokenController.text == '') {
      _tokenController.text = widget.inviteURL != null
          ? widget.inviteURL!.split('/').removeLast()
          : '';
    }
    return WillPopScope(
      onWillPop: () {
        if (currentGroupName != null && currentGroupId != null) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainPage()),
              (r) => false);
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: Form(
        key: _formKey,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'join'.tr(),
            ),
            leading: (currentGroupName != null)
                ? IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => MainPage()),
                        (r) => false),
                  )
                : null,
          ),
          drawer: !(widget.fromAuth || currentGroupName != null)
              ? null
              : Drawer(
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.horizontal(right: Radius.circular(16))),
                  elevation: 16,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: <Widget>[
                            DrawerHeader(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'DODO',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    'hi'.tr() + ' ' + currentUsername! + '!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(
                          Icons.settings,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          'settings'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Settings()));
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.exit_to_app,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          'logout'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                        ),
                        onTap: () {
                          _logout();
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginOrRegisterPage()),
                              (r) => false);
                        },
                      ),
                    ],
                  ),
                ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            children: [
                              Visibility(
                                visible: widget.inviteURL == null &&
                                    !kIsWeb &&
                                    (Platform.isAndroid || Platform.isIOS),
                                child: Column(
                                  children: [
                                    Text(
                                      'scan_code'.tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        GradientButton(
                                          child: Icon(
                                            Icons.qr_code_scanner,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                          onPressed: () async {
                                            if (await Permission.camera
                                                .request()
                                                .isGranted) {
                                              String? scanResult;
                                              await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              QRScannerPage()))
                                                  .then((value) =>
                                                      scanResult = value);
                                              if (scanResult != null) {
                                                setState(() {
                                                  _tokenController.text =
                                                      scanResult!;
                                                });
                                              }
                                            } else {
                                              Fluttertoast.showToast(
                                                  msg: 'no_camera_access'.tr(),
                                                  toastLength:
                                                      Toast.LENGTH_LONG);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      'paste_code'.tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    )
                                  ],
                                ),
                              ),
                              TextFormField(
                                validator: (value) => validateTextField([
                                  isEmpty(value),
                                ]),
                                decoration: InputDecoration(
                                  hintText: 'invitation'.tr(),
                                  prefixIcon: Icon(
                                    Icons.mail,
                                  ),
                                ),
                                controller: _tokenController,
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                validator: (value) => validateTextField([
                                  isEmpty(value),
                                  minimalLength(value, 1),
                                ]),
                                decoration: InputDecoration(
                                  labelText: 'nickname_in_group'.tr(),
                                  hintText: 'nickname_in_group'.tr(),
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  prefixIcon: Icon(
                                    Icons.account_circle,
                                  ),
                                  border: UnderlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                controller: _nicknameController,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(15),
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GradientButton(
                                    child: Text('join_group'.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary)),
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        String token = _tokenController.text;
                                        String nickname = _nicknameController
                                                .text[0]
                                                .toUpperCase() +
                                            _nicknameController.text
                                                .substring(1);
                                        showDialog(
                                            builder: (context) =>
                                                FutureSuccessDialog(
                                                  future: _joinGroup(
                                                      token, nickname),
                                                  dataTrueText: 'join_scf',
                                                  dataFalse: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Flexible(
                                                          child: Text(
                                                        'approve_still_needed'
                                                            .tr(),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge!
                                                            .copyWith(
                                                                color: Colors
                                                                    .white),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )),
                                                      SizedBox(
                                                        height: 15,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          GradientButton(
                                                            child: Icon(
                                                                Icons.check,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .onPrimary),
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ),
                                            barrierDismissible: false,
                                            context: context);
                                      }
                                    },
                                    // color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

//              SizedBox(height: 40,),
//              Divider(),
//              SizedBox(height: 40,),
                Visibility(
                  visible: MediaQuery.of(context).viewInsets.bottom == 0,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Center(
                              child: Text(
                                'no_group_yet'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GradientButton(
                                  child: Text('create_group'.tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary)),
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                CreateGroup()));
                                  },
                                  // color: Theme.of(context).colorScheme.secondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AdUnitForSite(site: 'join_group'),
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
}
