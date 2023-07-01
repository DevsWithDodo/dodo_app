import 'dart:convert';

import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/providers/event_bus_provider.dart';
import 'package:csocsort_szamla/essentials/providers/user_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/groups/dialogs/select_member_to_merge_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:event_bus_plus/event_bus_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import 'dialogs/change_nickname_dialog.dart';
import 'dialogs/confirm_leave_dialog.dart';
import 'join_group.dart';
import 'main_group_page.dart';

class MemberAllInfo extends StatefulWidget {
  final Member? member;
  final bool? isCurrentUserAdmin;

  MemberAllInfo({required this.member, required this.isCurrentUserAdmin});

  @override
  _MemberAllInfoState createState() => _MemberAllInfoState();
}

class _MemberAllInfoState extends State<MemberAllInfo> {
  FocusNode _nicknameFocus = FocusNode();

  Future<bool> _changeAdmin(int? memberId, bool isAdmin) async {
    try {
      Map<String, dynamic> body = {"member_id": memberId, "admin": isAdmin};

      await Http.put(
        uri: '/groups/' +
            context.read<UserProvider>().currentGroup!.id.toString() +
            '/admins',
        body: body,
      );
      Future.delayed(delayTime()).then((value) => _onChangeAdmin());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onChangeAdmin() {
    Navigator.pop(context);
    Navigator.pop(context, 'madeAdmin');
  }

  @override
  void initState() {
    _nicknameFocus.addListener(() {
      if (_nicknameFocus.hasFocus) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<User>(builder: (context, user, _) {
      return Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.account_circle,
                    color: Theme.of(context).colorScheme.secondary),
                Flexible(
                    child: Text(
                  ' - ' + widget.member!.username,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                )),
              ],
            ),
            SizedBox(
              height: 5,
            ),
            Row(
              children: <Widget>[
                Icon(Icons.account_box,
                    color: Theme.of(context).colorScheme.secondary),
                Flexible(
                    child: Text(
                  ' - ' + widget.member!.nickname,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                )),
              ],
            ),
            Visibility(
              visible: widget.member!.isAdmin! && !widget.isCurrentUserAdmin!,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    'Admin',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: widget.isCurrentUserAdmin! && !widget.member!.isGuest!,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Admin',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    Switch(
                      value: widget.member!.isAdmin!,
                      activeColor: Theme.of(context).colorScheme.secondary,
                      onChanged: (value) {
                        showDialog(
                            builder: (context) => FutureSuccessDialog(
                                  future:
                                      _changeAdmin(widget.member!.id, value),
                                  dataTrueText: 'admin_scf',
                                  onDataTrue: () {
                                    _onChangeAdmin();
                                  },
                                ),
                            barrierDismissible: false,
                            context: context);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Visibility(
              visible:
                  widget.isCurrentUserAdmin! || widget.member!.id == user.id,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: GradientButton.icon(
                    onPressed: () {
                      showDialog(
                              builder: (context) => ChangeNicknameDialog(
                                    username: widget.member!.username,
                                    memberId: widget.member!.id,
                                  ),
                              context: context)
                          .then((value) {
                        if (value != null && value == 'madeAdmin')
                          Navigator.pop(context, 'madeAdmin');
                      });
                    },
                    icon: Icon(Icons.edit),
                    label: Text('edit_nickname'.tr()),
                  ),
                ),
              ),
            ),
            Visibility(
              visible:
                  widget.isCurrentUserAdmin! && widget.member!.id != user.id,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: GradientButton.icon(
                    onPressed: () {
                      showDialog(
                              builder: (context) => ConfirmLeaveDialog(
                                    title: 'kick_member',
                                    choice: 'really_kick',
                                  ),
                              context: context)
                          .then((value) {
                        if (value != null && value) {
                          showDialog(
                              builder: (context) => FutureSuccessDialog(
                                    future: _removeMember(widget.member!.id),
                                    dataTrueText: 'kick_member_scf',
                                    onDataTrue: () {
                                      _onRemoveMember();
                                    },
                                  ),
                              barrierDismissible: false,
                              context: context);
                        }
                      });
                    },
                    icon: Icon(Icons.person_outline),
                    label: Text('kick_member'.tr()),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: widget.member!.isGuest! && widget.isCurrentUserAdmin!,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: GradientButton.icon(
                    icon: Icon(Icons.merge),
                    label: Text('merge_guest'.tr()),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => MergeGuestDialog(
                          guestId: widget.member!.id,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Visibility(
              visible: widget.member!.id == user.id,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: GradientButton.icon(
                    onPressed: () {
                      double currencyThreshold = threshold(
                          context.read<UserProvider>().currentGroup!.currency);
                      (currencies[context
                                      .read<UserProvider>()
                                      .currentGroup!
                                      .currency]!['subunit'] ==
                                  1
                              ? 0.01
                              : 1) /
                          2;
                      if (widget.member!.balance <= -currencyThreshold) {
                        FToast ft = FToast();
                        ft.init(context);
                        ft.showToast(
                            child: errorToast('balance_at_least_0', context),
                            toastDuration: Duration(seconds: 2),
                            gravity: ToastGravity.BOTTOM);
                        return;
                      } else {
                        showDialog(
                                builder: (context) => ConfirmLeaveDialog(
                                      title: 'leave_group',
                                      choice: 'really_leave',
                                    ),
                                context: context)
                            .then((value) {
                          if (value != null && value) {
                            showDialog(
                                builder: (context) => FutureSuccessDialog(
                                      future: _removeMember(null),
                                      onDataTrue: () async {
                                        _onRemoveMemberNull();
                                      },
                                    ),
                                barrierDismissible: false,
                                context: context);
                          }
                        });
                      }
                    },
                    icon: Icon(Icons.arrow_back),
                    label: Text('leave_group'.tr()),
                  ),
                ),
              ),
            )
          ],
        ),
      );
    });
  }

  Future<bool> _removeMember(int? memberId) async {
    Map<String, dynamic> body = {
      "member_id": memberId ?? context.read<UserProvider>().user!.id,
      "threshold": (currencies[context
                      .read<UserProvider>()
                      .currentGroup!
                      .currency]!['subunit'] ==
                  1
              ? 0.01
              : 1) /
          2
    };

    Response response = await Http.post(
      uri: '/groups/' +
          context.read<UserProvider>().currentGroup!.id.toString() +
          '/members/delete',
      body: body,
    );
    // The member leaves on his own
    if (memberId == null) {
      UserProvider userProvider = context.read<UserProvider>();
      if (response.body != "") { // The API returns the group if the user has other groups
        Map<String, dynamic> decoded = jsonDecode(response.body);
        userProvider.setGroup(Group(
          id: decoded['data']['group_id'],
          name: decoded['data']['group_name'],
          currency: decoded['data']['currency'],
        ));
      } else {
        userProvider.setGroup(null);
      }
      Future.delayed(delayTime()).then((value) => _onRemoveMemberNull());
    } else {
      // The member got kicked
      Future.delayed(delayTime()).then((value) => _onRemoveMember());
    }
    return true;
  }

  void _onRemoveMember() async {
    //if removed member was chosen guest
    await clearGroupCache(context);
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => MainPage()), (r) => false);
  }

  void _onRemoveMemberNull() async {
    await clearAllCache();
    if (context.read<UserProvider>().currentGroup != null) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (context) => MainPage()), (r) => false);
    } else {
      context.read<EventBus>().fire(RefreshGroups(context));
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => JoinGroup(
                    fromAuth: true,
                  )),
          (r) => false);
    }
  }
}
