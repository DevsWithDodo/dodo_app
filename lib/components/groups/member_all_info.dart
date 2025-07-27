import 'dart:convert';

import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/components/groups/dialogs/select_member_to_merge_dialog.dart';
import 'package:csocsort_szamla/components/helpers/background_paint.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/helpers/member_payment_methods.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/history_page.dart';
import 'package:csocsort_szamla/pages/app/join_group_page.dart';
import 'package:csocsort_szamla/pages/app/user_settings_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../pages/app/main_page.dart';
import 'dialogs/change_nickname_dialog.dart';
import 'dialogs/confirm_leave_dialog.dart';

class MemberAllInfo extends StatefulWidget {
  final Member member;
  final bool isCurrentUserAdmin;

  const MemberAllInfo({super.key, required this.member, required this.isCurrentUserAdmin});

  @override
  State<MemberAllInfo> createState() => _MemberAllInfoState();
}

class _MemberAllInfoState extends State<MemberAllInfo> {
  Future<BoolFutureOutput> _changeAdmin(int? memberId, bool isAdmin) async {
    try {
      Map<String, dynamic> body = {"member_id": memberId, "admin": isAdmin};

      await Http.put(
        uri: '/groups/${context.read<UserNotifier>().currentGroup!.id}/admins',
        body: body,
      );

      return BoolFutureOutput.True;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      child: Selector<UserNotifier, User>(
          selector: (context, provider) => provider.user!,
          builder: (context, user, _) {
            return BackgroundPaint(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 30, 15, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.member.username != "" || (widget.member.isGuest ?? false))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'member-info.username'.tr(),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Flexible(
                              child: Text(
                                  widget.member.username! == "" ? 'member-info.guest'.tr() : widget.member.username!),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'member-info.nickname'.tr(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Flexible(
                          child: Text(widget.member.nickname),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                          color: context.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.all(5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 400),
                              child: MemberPaymentMethods(member: widget.member),
                            ),
                          ),
                          if (widget.member.id == user.id)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => UserSettingsPage()),
                                ),
                                child: Text(
                                  'member-info.add-payment-methods'.tr(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: widget.member.isAdmin! && !widget.isCurrentUserAdmin,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'member-all-info.member-is-admin'.tr(namedArgs: {'name': widget.member.nickname}),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: widget.isCurrentUserAdmin && !widget.member.isGuest!,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Admin', style: Theme.of(context).textTheme.titleMedium),
                            Switch(
                              value: widget.member.isAdmin!,
                              activeColor: Theme.of(context).colorScheme.secondary,
                              onChanged: (value) {
                                showFutureOutputDialog(
                                    context: context,
                                    future: _changeAdmin(widget.member.id, value),
                                    outputCallbacks: {
                                      BoolFutureOutput.True: () {
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                        setState(() => widget.member.isAdmin = value);
                                      }
                                    });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => HistoryPage(selectedMemberId: widget.member.id))),
                        child: Text('member-info.transactions'.tr(), textAlign: TextAlign.center),
                      ),
                    ),
                    Visibility(
                      visible: widget.isCurrentUserAdmin || widget.member.id == user.id,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Center(
                          child: GradientButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => ChangeNicknameDialog(
                                  memberId: widget.member.id,
                                ),
                              ).then((value) {
                                if ((value ?? false)) {
                                  Navigator.of(context).pop();
                                }
                              });
                            },
                            icon: Icon(Icons.edit),
                            label: Text('edit_nickname'.tr()),
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: widget.isCurrentUserAdmin && widget.member.id != user.id,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Center(
                          child: GradientButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => ConfirmLeaveDialog(
                                  title: 'kick_member',
                                  choice: 'really_kick',
                                ),
                              ).then((value) {
                                if ((value ?? false)) {
                                  showFutureOutputDialog(
                                    context: context,
                                    future: _removeMember(widget.member.id),
                                    outputCallbacks: {
                                      LeftOrRemovedFromGroupFutureOutput.removedFromGroup: () {
                                        EventBus.instance.fire(EventBus.refreshBalances);
                                        EventBus.instance.fire(EventBus.refreshPurchases);
                                        EventBus.instance.fire(EventBus.refreshPayments);
                                        EventBus.instance.fire(EventBus.refreshShopping);
                                        EventBus.instance.fire(EventBus.refreshGroupMembers);
                                        EventBus.instance.fire(EventBus.refreshGroupInfo);
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pop();
                                      }
                                    },
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
                      visible: widget.member.isGuest! && widget.isCurrentUserAdmin,
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
                                  guestId: widget.member.id,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: widget.member.id == user.id,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Center(
                          child: GradientButton.icon(
                            onPressed: () {
                              double currencyThreshold =
                                  context.read<UserNotifier>().currentGroup!.currency.threshold();
                              if (widget.member.balance <= -currencyThreshold) {
                                FToast ft = FToast();
                                ft.init(context);
                                ft.showToast(
                                    child: errorToast('balance_at_least_0', context),
                                    toastDuration: Duration(seconds: 2),
                                    gravity: ToastGravity.BOTTOM);
                                return;
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => ConfirmLeaveDialog(
                                    title: 'leave_group',
                                    choice: 'really_leave',
                                  ),
                                ).then(
                                  (value) {
                                    if ((value ?? false)) {
                                      showFutureOutputDialog(
                                        context: context,
                                        future: _removeMember(null),
                                        outputCallbacks: {
                                          LeftOrRemovedFromGroupFutureOutput.leftHasOtherGroup: () async {
                                            await Navigator.of(context).pushAndRemoveUntil(
                                              MaterialPageRoute(builder: (context) => MainPage()),
                                              (r) => false,
                                            );

                                            EventBus.instance.fire(EventBus.refreshBalances);
                                            EventBus.instance.fire(EventBus.refreshGroups);
                                            EventBus.instance.fire(EventBus.refreshPurchases);
                                            EventBus.instance.fire(EventBus.refreshPayments);
                                            EventBus.instance.fire(EventBus.refreshShopping);
                                            EventBus.instance.fire(EventBus.refreshGroupInfo);
                                          },
                                          LeftOrRemovedFromGroupFutureOutput.leftNoOtherGroup: () async {
                                            Navigator.of(context).pushAndRemoveUntil(
                                              MaterialPageRoute(
                                                builder: (context) => JoinGroupPage(
                                                  fromAuth: true,
                                                ),
                                              ),
                                              (r) => false,
                                            );
                                            UserNotifier provider = context.read<UserNotifier>();
                                            provider.setGroups([]);
                                            provider.setGroup(null);
                                            clearAllCache();
                                          },
                                        },
                                      );
                                    }
                                  },
                                );
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
              ),
            );
          }),
    );
  }

  Future<LeftOrRemovedFromGroupFutureOutput> _removeMember(int? memberId) async {
    Map<String, dynamic> body = {
      "member_id": memberId ?? context.read<UserNotifier>().user!.id,
      "threshold": context.read<UserNotifier>().currentGroup!.currency.threshold(),
    };

    Response response = await Http.post(
      uri: '/groups/${context.read<UserNotifier>().currentGroup!.id}/members/delete',
      body: body,
    );
    // The member removed another member
    if (memberId != null) {
      return LeftOrRemovedFromGroupFutureOutput.removedFromGroup;
    }
    if (response.body != "") {
      // The API returns the group if the user has other groups
      Map<String, dynamic> decoded = jsonDecode(response.body);
      if (mounted) {
        UserNotifier provider = context.read<UserNotifier>();
        provider.setGroups(provider.user!.groups.where((group) => group.id != provider.user!.group!.id).toList());
        provider.setGroup(Group.fromJson(decoded['data']));
        return LeftOrRemovedFromGroupFutureOutput.leftHasOtherGroup;
      }
    }
    return LeftOrRemovedFromGroupFutureOutput.leftNoOtherGroup;
  }
}

class LeftOrRemovedFromGroupFutureOutput extends FutureOutput {
  const LeftOrRemovedFromGroupFutureOutput(super.value, super.name);

  static const leftHasOtherGroup = LeftOrRemovedFromGroupFutureOutput(true, 'hasOutherGroup');
  static const leftNoOtherGroup = LeftOrRemovedFromGroupFutureOutput(true, 'noOutherGroup');
  static const removedFromGroup = LeftOrRemovedFromGroupFutureOutput(true, 'removedFromGroup');
}
