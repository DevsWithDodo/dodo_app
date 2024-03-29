import 'dart:convert';

import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/groups/dialogs/change_group_currency_dialog.dart';
import 'package:csocsort_szamla/components/groups/dialogs/change_nickname_dialog.dart';
import 'package:csocsort_szamla/components/groups/dialogs/rename_group_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../helpers/error_message.dart';
import 'boost_group.dart';
import 'group_members.dart';
import 'invitation.dart';

class GroupSettings extends StatefulWidget {
  final String? scrollTo;
  GroupSettings({this.scrollTo});
  @override
  _GroupSettingState createState() => _GroupSettingState();
}

class _GroupSettingState extends State<GroupSettings> {
  Future<bool>? _isUserAdmin;
  Future<bool>? _hasGuests;
  var guestsKey = GlobalKey();

  Future<bool> _getHasGuests() async {
    try {
      Response response = await Http.get(
        uri: generateUri(GetUriKeys.groupHasGuests, context,
            params: [context.read<UserState>().user!.group!.id.toString()]),
      );
      Map<String, dynamic> decoded = jsonDecode(response.body);
      // print(decoded);
      return decoded['data'] == 1;
    } catch (_) {
      throw _;
    }
  }

  Future<bool> _getIsUserAdmin() async {
    try {
      Response response = await Http.get(
        uri: generateUri(GetUriKeys.groupMember, context),
        useCache: false,
      );
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
    bool bigScreen = !context.select<ScreenSize, bool>((screenWidth) => screenWidth.isMobile);

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
        child: FutureBuilder(
            future: _isUserAdmin,
            builder: (context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  List<Widget> columnWidgets = _columnWidgets(snapshot);
                  if (bigScreen) {
                    return Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: columnWidgets.take(2).toList(),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: ScrollController(),
                            child: Column(
                              children: columnWidgets.reversed.take(3).toList().reversed.toList(),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return SingleChildScrollView(
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
      ),
    );
  }

  List<Widget> _columnWidgets(AsyncSnapshot<bool> snapshot) {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Visibility(
                visible: snapshot.data!,
                child: Column(
                  children: [
                    Text(
                      'rename_group'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    SizedBox(height: 10),
                    GradientButton(
                      useSecondary: true,
                      child: Icon(Icons.edit),
                      onPressed: () => showDialog(
                          builder: (context) => RenameGroupDialog(),
                          context: context,
                        ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
              Text(
                'group-settings.change-nickname'.tr(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GradientButton(
                    useSecondary: true,
                    child: Icon(Icons.edit),
                    onPressed: () {
                      User user = context.read<UserState>().user!;
                      showDialog(
                        context: context,
                        builder: (context) => ChangeNicknameDialog(
                          memberId: user.id,
                          username: user.username,
                        ),
                      );
                    },
                  ),
                ],
              )
            ],
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
                  style:
                      Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurface),
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
                      child: Icon(Icons.monetization_on),
                      onPressed: () {
                        showDialog(builder: (context) => ChangeGroupCurrencyDialog(), context: context);
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
    ];
  }
}
