import 'dart:convert';

import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/group_objects.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/widgets/bottom_sheet_custom.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../essentials/app_theme.dart';
import 'member_all_info.dart';

class GroupMembers extends StatefulWidget {
  @override
  _GroupMembersState createState() => _GroupMembersState();
}

class _GroupMembersState extends State<GroupMembers> {
  Future<List<Member>> _members;

  Member currentMember;

  Future<List<Member>> _getMembers() async {
    try {
      http.Response response = await httpGet(
          uri: generateUri(GetUriKeys.groupCurrent,
              args: [currentGroupId.toString()]),
          context: context,
          useCache: false);
      Map<String, dynamic> decoded = jsonDecode(response.body);
      List<Member> members = [];
      for (var member in decoded['data']['members']) {
        members.add(Member.fromJson(member));
      }
      currentMember =
          members.firstWhere((member) => member.memberId == currentUserId);
      members.remove(currentMember);
      members.insert(0, currentMember);
      return members;
    } catch (_) {
      throw _;
    }
  }

  @override
  void initState() {
    _members = null;
    _members = _getMembers();
    super.initState();
  }

  void callback() {
    setState(() {
      _members = null;
      _members = _getMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
                child: Text(
              'members'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
            )),
            FutureBuilder(
              future: _members,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Visibility(
                            visible: !currentMember.isAdmin,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 10,
                                ),
                                Center(
                                    child: Text(
                                  'members_explanation'.tr(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface),
                                  textAlign: TextAlign.center,
                                )),
                              ],
                            )),
                        Visibility(
                            visible: currentMember.isAdmin,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 10,
                                ),
                                Center(
                                    child: Text(
                                  'members_explanation_admin'.tr(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface),
                                  textAlign: TextAlign.center,
                                )),
                              ],
                            )),
                        SizedBox(
                          height: 40,
                        ),
                        Column(children: _generateMembers(snapshot.data)),
                      ],
                    );
                  } else {
                    return InkWell(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(snapshot.error.toString()),
                        ),
                        onTap: () {
                          setState(() {
                            _members = null;
                            _members = _getMembers();
                          });
                        });
                  }
                }
                return Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      CircularProgressIndicator(),
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _generateMembers(List<Member> members) {
    return members.map((member) {
      return MemberEntry(
        member: member,
        isCurrentUserAdmin: currentMember.isAdmin,
        callback: this.callback,
      );
    }).toList();
  }
}

class MemberEntry extends StatefulWidget {
  final Function callback;
  final Member member;
  final bool isCurrentUserAdmin;

  MemberEntry({this.member, this.isCurrentUserAdmin, this.callback});

  @override
  _MemberEntryState createState() => _MemberEntryState();
}

class _MemberEntryState extends State<MemberEntry> {
  TextStyle mainTextStyle;
  TextStyle subTextStyle;
  BoxDecoration boxDecoration;
  Color iconColor;

  @override
  Widget build(BuildContext context) {
    if (widget.member.memberId == currentUserId) {
      mainTextStyle = Theme.of(context)
          .textTheme
          .bodyLarge
          .copyWith(color: Theme.of(context).colorScheme.onSecondary);
      subTextStyle = Theme.of(context)
          .textTheme
          .bodySmall
          .copyWith(color: Theme.of(context).colorScheme.onSecondary);
      iconColor = Theme.of(context).colorScheme.onSecondary;
      boxDecoration = BoxDecoration(
        gradient:
            AppTheme.gradientFromTheme(currentThemeName, useSecondary: true),
        // color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
      );
    } else {
      mainTextStyle = Theme.of(context)
          .textTheme
          .bodyLarge
          .copyWith(color: Theme.of(context).colorScheme.onSurface);
      subTextStyle = Theme.of(context)
          .textTheme
          .bodySmall
          .copyWith(color: Theme.of(context).colorScheme.onSurface);
      iconColor = Theme.of(context).colorScheme.onSurface;
      boxDecoration = BoxDecoration();
    }
    return Container(
      height: 65,
      width: MediaQuery.of(context).size.width,
      decoration: boxDecoration,
      margin: EdgeInsets.only(bottom: 4),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            showModalBottomSheetCustom(
                context: context,
                backgroundColor: Theme.of(context).cardTheme.color,
                builder: (context) => SingleChildScrollView(
                      child: MemberAllInfo(
                        member: widget.member,
                        isCurrentUserAdmin: widget.isCurrentUserAdmin,
                      ),
                    )).then((val) {
              if (val == 'madeAdmin') widget.callback();
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.account_box,
                              color: iconColor,
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
                                    widget.member.username,
                                    style: mainTextStyle,
                                    overflow: TextOverflow.ellipsis,
                                  )),
                                  Flexible(
                                      child: Text(
                                    widget.member.nickname,
                                    style: subTextStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ))
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Visibility(
                            visible: widget.member.isAdmin,
                            child: Text(
                              '👑  ', //itt van egy korona emoji lol
                              style: mainTextStyle,
                            )),
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
  }
}
