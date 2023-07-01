import 'dart:convert';

import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/providers/user_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/error_message.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/groups/dialogs/add_guest_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import 'dialogs/share_group_dialog.dart';

class Invitation extends StatefulWidget {
  final bool? isAdmin;
  Invitation({this.isAdmin});
  @override
  _InvitationState createState() => _InvitationState();
}

class _InvitationState extends State<Invitation> {
  Future<String>? _invitation;
  Future<List<Member>>? _unapproved;
  late bool _needsApproval;

  Future<String> _getInvitation() async {
    try {
      Response response = await Http.get(
        uri: generateUri(GetUriKeys.groupCurrent, context),
        useCache: false,
      );
      Map<String, dynamic> decoded = jsonDecode(response.body);
      _needsApproval = decoded['data']['admin_approval'] == 1;
      return decoded['data']['invitation'];
    } catch (_) {
      throw _;
    }
  }

  Future<List<Member>> _getUnapprovedMembers() async {
    try {
      Response response = await Http.get(
        uri: generateUri(GetUriKeys.groupUnapprovedMembers, context),
        useCache: false,
      );
      Map<String, dynamic> decoded = jsonDecode(response.body);
      List<Member> members = <Member>[];
      for (Map<String, dynamic> member in decoded['data']) {
        members.add(Member.fromJson(member));
      }
      return members;
    } catch (_) {
      throw _;
    }
  }

  Future<bool> _updateNeedsApproval() async {
    try {
      Map<String, dynamic> body = {'admin_approval': _needsApproval ? 1 : 0};
      await Http.put(
        uri: '/groups/' + context.read<UserProvider>().user!.group!.id.toString(),
        body: body,
      );
      Future.delayed(delayTime()).then((value) => _onUpdateNeedsApproval());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onUpdateNeedsApproval() {
    Navigator.pop(context);
  }

  @override
  void initState() {
    _unapproved = null;
    _unapproved = _getUnapprovedMembers();
    _invitation = null;
    _invitation = _getInvitation();
    super.initState();
  }

  void callback() {
    setState(() {
      _unapproved = null;
      _unapproved = _getUnapprovedMembers();
      _invitation = null;
      _invitation = _getInvitation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: <Widget>[
            Text(
              'invitation'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(
              height: 10,
            ),
            Center(
              child: Text(
                'invite_friends'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            FutureBuilder(
              future: _invitation,
              builder: (context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    return Column(
                      children: [
                        Center(
                          child: Column(
                            children: [
                              GradientButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return ShareGroupDialog(
                                          inviteCode: snapshot.data,
                                        );
                                      });
                                },
                                child: Icon(Icons.share),
                              ),
                              Visibility(
                                visible: widget.isAdmin!,
                                child: Column(
                                  children: [
                                    SizedBox(height: 10),
                                    Center(
                                      child: Text(
                                        'add_guests_offline'.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    GradientButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              AddGuestDialog(),
                                        );
                                      },
                                      child: Icon(Icons.person_add),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: widget.isAdmin!,
                          child: FutureBuilder(
                            future: _unapproved,
                            builder: (context,
                                AsyncSnapshot<List<Member>> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
                                if (snapshot.hasData) {
                                  return Column(
                                    children: [
                                      SizedBox(
                                        height: 7,
                                      ),
                                      Divider(),
                                      SizedBox(
                                        height: 7,
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            'group_needs_approval'.tr(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Text(
                                            'group_needs_approval_explanation'
                                                .tr(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Text(
                                            'needs_approval'.tr(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface),
                                          ),
                                          Switch(
                                            trackOutlineColor:
                                                MaterialStateProperty.all<
                                                    Color>(Colors.transparent),
                                            value: _needsApproval,
                                            activeColor: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            onChanged: (value) {
                                              setState(() {
                                                _needsApproval = value;
                                              });
                                              showDialog(
                                                  builder: (context) =>
                                                      FutureSuccessDialog(
                                                        future:
                                                            _updateNeedsApproval(),
                                                        onDataTrue: () {
                                                          _onUpdateNeedsApproval();
                                                        },
                                                        onDataFalse: () {
                                                          Navigator.pop(
                                                              context);
                                                          setState(() {
                                                            _needsApproval =
                                                                !_needsApproval;
                                                          });
                                                        },
                                                        onNoData: () {
                                                          Navigator.pop(
                                                              context);
                                                          setState(() {
                                                            _needsApproval =
                                                                !_needsApproval;
                                                          });
                                                        },
                                                      ),
                                                  context: context,
                                                  barrierDismissible: false);
                                            },
                                          ),
                                        ],
                                      ),
                                      Visibility(
                                        visible: snapshot.data!.length != 0,
                                        child: Column(
                                          children: [
                                            SizedBox(height: 5),
                                            Divider(),
                                            SizedBox(height: 5),
                                            Text(
                                              'approve_members'.tr(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge!
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                              'approve_members_explanation'
                                                  .tr(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall!
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface),
                                              textAlign: TextAlign.center,
                                            ),
                                            Column(
                                                children: _generateMembers(
                                                    snapshot.data!)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return ErrorMessage(
                                    error: snapshot.error.toString(),
                                    errorLocation: 'approve_members',
                                    onTap: () {
                                      setState(() {
                                        _unapproved = null;
                                        _unapproved = _getUnapprovedMembers();
                                      });
                                    },
                                  );
                                }
                              }
                              return Container();
                            },
                          ),
                        ),
                      ],
                    );
                  } else {
                    return ErrorMessage(
                      error: snapshot.error.toString(),
                      errorLocation: 'invitation',
                      onTap: () {
                        setState(() {
                          _invitation = null;
                          _invitation = _getInvitation();
                        });
                      },
                    );
                  }
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _generateMembers(List<Member> members) {
    return members.map((member) {
      return Container(
        height: 65,
        margin: EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(15),
          boxShadow: (Theme.of(context).brightness == Brightness.light)
              ? [
                  BoxShadow(
                    color: Colors.grey[500]!,
                    offset: Offset(0.0, 1.5),
                    blurRadius: 1.5,
                  )
                ]
              : [],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => SingleChildScrollView(
                        child: ApproveMember(
                          member: member,
                        ),
                      )).then((value) {
                if (value ?? false) callback();
              });
            },
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Flex(
                direction: Axis.horizontal,
                children: <Widget>[
                  Flexible(
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.account_circle,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Flexible(
                                  child: Text(
                                member.username,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary),
                                overflow: TextOverflow.ellipsis,
                              )),
                              Flexible(
                                  child: Text(
                                member.nickname,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary),
                                overflow: TextOverflow.ellipsis,
                              ))
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class ApproveMember extends StatefulWidget {
  final Member? member;
  ApproveMember({this.member});
  @override
  _ApproveMemberState createState() => _ApproveMemberState();
}

class _ApproveMemberState extends State<ApproveMember> {
  Future<bool> _postApproveMember(int? memberId, bool approve) async {
    try {
      Map<String, dynamic> body = {'member_id': memberId, 'approve': approve};
      await Http.post(
          uri: '/groups/' +
              context.read<UserProvider>().user!.group!.id.toString() +
              '/members/approve_or_deny',
          body: body);
      Future.delayed(delayTime()).then((value) => _onPostApproveMember());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onPostApproveMember() {
    clearGroupCache(context);
    Navigator.pop(context);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          Row(
            children: <Widget>[
              Icon(Icons.account_circle,
                  color: Theme.of(context).colorScheme.secondary),
              Text(' - '),
              Flexible(
                  child: Text(
                widget.member!.username,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
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
              Text(' - '),
              Flexible(
                  child: Text(
                widget.member!.username,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
              )),
            ],
          ),
          SizedBox(
            height: 5,
          ),
          GradientButton.icon(
            onPressed: () {
              showDialog(
                  builder: (context) => FutureSuccessDialog(
                        future: _postApproveMember(widget.member!.id, true),
                      ),
                  context: context);
            },
            icon: Icon(Icons.check),
            label: Text('approve'.tr()),
          ),
          SizedBox(height: 10),
          GradientButton.icon(
            onPressed: () {
              showDialog(
                  builder: (context) => FutureSuccessDialog(
                        future: _postApproveMember(widget.member!.id, false),
                      ),
                  context: context);
            },
            icon: Icon(Icons.clear),
            label: Text('disapprove'.tr()),
          )
        ],
      ),
    );
  }
}
