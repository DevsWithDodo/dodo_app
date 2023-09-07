import 'dart:convert';

import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/event_bus.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/essentials/widgets/member_payment_methods.dart';
import 'package:csocsort_szamla/groups/dialogs/select_member_to_merge_dialog.dart';
import 'package:csocsort_szamla/history/all_history_page.dart';
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
  final Member member;
  final bool isCurrentUserAdmin;

  MemberAllInfo({required this.member, required this.isCurrentUserAdmin});

  @override
  _MemberAllInfoState createState() => _MemberAllInfoState();
}

class _MemberAllInfoState extends State<MemberAllInfo> {
  Future<BoolFutureOutput> _changeAdmin(int? memberId, bool isAdmin) async {
    try {
      Map<String, dynamic> body = {"member_id": memberId, "admin": isAdmin};

      await Http.put(
        uri: '/groups/' + context.read<AppStateProvider>().currentGroup!.id.toString() + '/admins',
        body: body,
      );

      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      child: Selector<AppStateProvider, User>(
          selector: (context, provider) => provider.user!,
          builder: (context, user, _) {
            return Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "${'member-info.username'.tr()} - ",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Flexible(
                        child: Text(widget.member.username),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      Text(
                        "${'member-info.nickname'.tr()} - ",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Flexible(
                        child: Text(widget.member.nickname),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'member-info.payment-methods'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 5),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 400),
                      child: MemberPaymentMethods(member: widget.member),
                    ),
                  ),
                  Visibility(
                    visible: widget.member.isAdmin! && !widget.isCurrentUserAdmin,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Admin',
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                      Navigator.pop(context, 'madeAdmin');
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
                          MaterialPageRoute(builder: (context) => AllHistoryPage(selectedMemberId: widget.member.id))),
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
                                username: widget.member.username,
                                memberId: widget.member.id,
                              ),
                            ).then((value) {
                              if (value ?? false) {
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
                              if (value ?? false) {
                                showFutureOutputDialog(
                                  context: context,
                                  future: _removeMember(widget.member.id),
                                  outputCallbacks: {
                                    LeftOrRemovedFromGroupFutureOutput.RemovedFromGroup: () {
                                          EventBus.instance.fire(EventBus.refreshBalances);
                                          EventBus.instance.fire(EventBus.refreshPurchases);
                                          EventBus.instance.fire(EventBus.refreshPayments);
                                          EventBus.instance.fire(EventBus.refreshShopping);
                                          EventBus.instance.fire(EventBus.refreshGroupMembers);
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
                                Currency.threshold(context.read<AppStateProvider>().currentGroup!.currency);
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
                                  if (value ?? false) {
                                    showFutureOutputDialog(
                                      context: context,
                                      future: _removeMember(null),
                                      outputCallbacks: {
                                        LeftOrRemovedFromGroupFutureOutput.LeftHasOutherGroup: () async {
                                          await Navigator.of(context).pushAndRemoveUntil(
                                            MaterialPageRoute(builder: (context) => MainPage()),
                                            (r) => false,
                                          );

                                          EventBus.instance.fire(EventBus.refreshBalances);
                                          EventBus.instance.fire(EventBus.refreshGroups);
                                          EventBus.instance.fire(EventBus.refreshPurchases);
                                          EventBus.instance.fire(EventBus.refreshPayments);
                                          EventBus.instance.fire(EventBus.refreshShopping);
                                        },
                                        LeftOrRemovedFromGroupFutureOutput.LeftNoOutherGroup: () async {
                                          await Navigator.of(context).pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder: (context) => JoinGroup(
                                                fromAuth: true,
                                              ),
                                            ),
                                            (r) => false,
                                          );
                                          await clearAllCache();
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
            );
          }),
    );
  }

  Future<LeftOrRemovedFromGroupFutureOutput> _removeMember(int? memberId) async {
    Map<String, dynamic> body = {
      "member_id": memberId ?? context.read<AppStateProvider>().user!.id,
      "threshold": Currency.threshold(context.read<AppStateProvider>().currentGroup!.currency),
    };

    Response response = await Http.post(
      uri: '/groups/' + context.read<AppStateProvider>().currentGroup!.id.toString() + '/members/delete',
      body: body,
    );
    // The member removed another member
    if (memberId != null) {
      return LeftOrRemovedFromGroupFutureOutput.RemovedFromGroup;
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
      return LeftOrRemovedFromGroupFutureOutput.LeftHasOutherGroup;
    }
    return LeftOrRemovedFromGroupFutureOutput.LeftNoOutherGroup;
  }
}

class LeftOrRemovedFromGroupFutureOutput extends FutureOutput {
  const LeftOrRemovedFromGroupFutureOutput(super.value, super.name);

  static const LeftHasOutherGroup = LeftOrRemovedFromGroupFutureOutput(true, 'hasOutherGroup');
  static const LeftNoOutherGroup = LeftOrRemovedFromGroupFutureOutput(true, 'noOutherGroup');
  static const RemovedFromGroup = LeftOrRemovedFromGroupFutureOutput(true, 'removedFromGroup');
}
