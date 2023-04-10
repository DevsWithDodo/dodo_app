import 'dart:convert';

import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/groups/dialogs/change_group_currency_dialog.dart';
import 'package:csocsort_szamla/groups/dialogs/rename_group_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../essentials/widgets/error_message.dart';
import 'boost_group.dart';
import 'group_members.dart';
import 'invitation.dart';

class GroupSettings extends StatefulWidget {
  final bool bigScreen;
  final double? height;
  final double? width;
  final GlobalKey<State>? bannerKey;
  final String? scrollTo;
  GroupSettings({this.bannerKey, this.scrollTo, this.bigScreen = false, this.height, this.width});
  @override
  _GroupSettingState createState() => _GroupSettingState();
}

class _GroupSettingState extends State<GroupSettings> {
  Future<bool>? _isUserAdmin;
  Future<bool>? _hasGuests;
  var guestsKey = GlobalKey();

  Future<bool> _getHasGuests() async {
    try {
      http.Response response = await httpGet(
          uri: generateUri(GetUriKeys.groupHasGuests, args: [currentGroupId.toString()]),
          context: context);
      Map<String, dynamic> decoded = jsonDecode(response.body);
      // print(decoded);
      return decoded['data'] == 1;
    } catch (_) {
      throw _;
    }
  }

  Future<bool> _getIsUserAdmin() async {
    try {
      http.Response response = await httpGet(
          uri: generateUri(GetUriKeys.groupMember), context: context, useCache: false);
      Map<String, dynamic> decoded = jsonDecode(response.body);
      return decoded['data']['is_admin'] == 1;
    } catch (_) {
      throw _;
    }
  }

  @override
  void initState() {
    _isUserAdmin = null;
    _isUserAdmin = _getIsUserAdmin();
    _hasGuests = null;
    _hasGuests = _getHasGuests();
    WidgetsFlutterBinding.ensureInitialized();
    _hasGuests!.whenComplete(() {
      Future.delayed(Duration(milliseconds: 1000)).then((value) {
        if (widget.scrollTo == 'guests') {
          // print(guestsKey.currentContext);
          Scrollable.ensureVisible(guestsKey.currentContext!);
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = widget.width ?? MediaQuery.of(context).size.width;
    double height = widget.height ?? MediaQuery.of(context).size.height;
    return RefreshIndicator(
      onRefresh: () async {
        await deleteCache(uri: '/groups');
        setState(() {
          _isUserAdmin = null;
          _isUserAdmin = _getIsUserAdmin();
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: SingleChildScrollView(
          physics:
              widget.bigScreen ? NeverScrollableScrollPhysics() : AlwaysScrollableScrollPhysics(),
          child: Column(
            children: <Widget>[
              FutureBuilder(
                  future: _isUserAdmin,
                  builder: (context, AsyncSnapshot<bool> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        List<Widget> columnWidgets = _columnWidgets(snapshot);
                        if (widget.bigScreen) {
                          return Table(
                            columnWidths: {
                              0: FractionColumnWidth(0.5),
                              1: FractionColumnWidth(0.5),
                            },
                            children: [
                              TableRow(children: [
                                AspectRatio(
                                  aspectRatio: width / 2 / height,
                                  child: ListView(
                                    controller: ScrollController(),
                                    children: columnWidgets.take(2).toList(),
                                  ),
                                ),
                                AspectRatio(
                                  aspectRatio: width / 2 / height,
                                  child: ListView(
                                    controller: ScrollController(),
                                    children:
                                        columnWidgets.reversed.take(4).toList().reversed.toList(),
                                  ),
                                ),
                              ])
                            ],
                          );
                        }
                        return SingleChildScrollView(
                          physics: NeverScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: columnWidgets,
                          ),
                        );
                      } else {
                        return ErrorMessage(
                          error: snapshot.error.toString(),
                          errorLocation: 'is_user_admin',
                          onTap: () {
                            setState(() {
                              _isUserAdmin = null;
                              _isUserAdmin = _getIsUserAdmin();
                            });
                          },
                        );
                      }
                    }
                    return LinearProgressIndicator(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _columnWidgets(AsyncSnapshot<bool> snapshot) {
    return [
      Visibility(
        visible: snapshot.data!,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: <Widget>[
                Center(
                  child: Text(
                    'rename_group'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(color: Theme.of(context).colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Center(
                    child: Text(
                  'rename_group_explanation'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(color: Theme.of(context).colorScheme.onSurface),
                  textAlign: TextAlign.center,
                )),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GradientButton(
                      useSecondary: true,
                      child: Icon(
                        Icons.edit,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                      onPressed: () {
                        showDialog(builder: (context) => RenameGroupDialog(), context: context);
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
      Invitation(isAdmin: snapshot.data),
      BoostGroup(),
      Visibility(
        visible: false && snapshot.data!,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: <Widget>[
                Center(
                  child: Text(
                    'change_group_currency'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(color: Theme.of(context).colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Center(
                    child: Text(
                  'change_group_currency_explanation'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(color: Theme.of(context).colorScheme.onSurface),
                  textAlign: TextAlign.center,
                )),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GradientButton(
                      useSecondary: true,
                      child: Icon(
                        Icons.monetization_on,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                      onPressed: () {
                        showDialog(
                            builder: (context) => ChangeGroupCurrencyDialog(), context: context);
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
      GroupMembers(),
      SizedBox(height: 80)
    ];
  }
}
