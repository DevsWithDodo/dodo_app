import 'dart:convert';

import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/event_bus.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/groups/dialogs/select_member_to_merge_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
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

  Future<BoolFutureOutput> _changeAdmin(int? memberId, bool isAdmin) async {
    try {
      Map<String, dynamic> body = {"member_id": memberId, "admin": isAdmin};

      await Http.put(
        uri: '/groups/' +
            context.read<AppStateProvider>().currentGroup!.id.toString() +
            '/admins',
        body: body,
      );

      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
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
    return Selector<AppStateProvider, User>(
        selector: (context, provider) => provider.user!,
        builder: (context, user, _) {
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
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
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
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    )),
                  ],
                ),
                Visibility(
                  visible:
                      widget.member!.isAdmin! && !widget.isCurrentUserAdmin!,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        'Admin',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible:
                      widget.isCurrentUserAdmin! && !widget.member!.isGuest!,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'Admin',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                        ),
                        Switch(
                          value: widget.member!.isAdmin!,
                          activeColor: Theme.of(context).colorScheme.secondary,
                          onChanged: (value) {
                            showFutureOutputDialog(
                                context: context,
                                future: _changeAdmin(widget.member!.id, value),
                                outputCallbacks: {
                                  BoolFutureOutput.True: () {
                                    Navigator.pop(context);
                                    Navigator.pop(context, 'madeAdmin');
                                  }
                                });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: widget.isCurrentUserAdmin! ||
                      widget.member!.id == user.id,
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
                  visible: widget.isCurrentUserAdmin! &&
                      widget.member!.id != user.id,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Center(
                      child: GradientButton.icon(
                        onPressed: () {
                          showDialog<bool>(
                            builder: (context) => ConfirmLeaveDialog(
                              title: 'kick_member',
                              choice: 'really_kick',
                            ),
                            context: context,
                          ).then((value) {
                            if (value ?? false) {
                              showFutureOutputDialog(
                                context: context,
                                future: _removeMember(widget.member!.id),
                                outputCallbacks: {
                                  BoolFutureOutput.True: () async {
                                    await clearGroupCache(context); // TODO: event bus
                                    Navigator.of(context).pop();
                                  }
                                }
                              );
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
                  visible:
                      widget.member!.isGuest! && widget.isCurrentUserAdmin!,
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
                          double currencyThreshold = threshold(context
                              .read<AppStateProvider>()
                              .currentGroup!
                              .currency);
                          if (widget.member!.balance <= -currencyThreshold) {
                            FToast ft = FToast();
                            ft.init(context);
                            ft.showToast(
                                child:
                                    errorToast('balance_at_least_0', context),
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
                                showFutureOutputDialog(
                                  context: context,
                                  future: _removeMember(null),
                                  outputCallbacks: {
                                    BoolFutureOutput.True: () async {
                                      await clearAllCache(); // TODO: event bus
                                      if (context.read<AppStateProvider>().currentGroup != null) {
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (context) => MainPage()), 
                                          (r) => false,
                                        );
                                      } else {
                                        EventBus.instance.fire(EventBus.refreshGroups);
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (context) => JoinGroup(
                                              fromAuth: true,
                                            )),
                                          (r) => false,
                                        );
                                      }
                                    },
                                  }
                                );
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

  Future<BoolFutureOutput> _removeMember(int? memberId) async {
    Map<String, dynamic> body = {
      "member_id": memberId ?? context.read<AppStateProvider>().user!.id,
      "threshold":
          threshold(context.read<AppStateProvider>().currentGroup!.currency),
    };

    Response response = await Http.post(
      uri: '/groups/' +
          context.read<AppStateProvider>().currentGroup!.id.toString() +
          '/members/delete',
      body: body,
    );
    // The member leaves on his own
    if (memberId != null) {
      return BoolFutureOutput.True;
    }
    AppStateProvider userProvider = context.read<AppStateProvider>();
    if (response.body != "") {
      // The API returns the group if the user has other groups
      Map<String, dynamic> decoded = jsonDecode(response.body);
      userProvider.setGroup(Group(
        id: decoded['data']['group_id'],
        name: decoded['data']['group_name'],
        currency: decoded['data']['currency'],
      ));
    } else {
      userProvider.setGroup(null);
    }
    return BoolFutureOutput.True;
  }
}
