import 'dart:convert';

import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../essentials/app_theme.dart';
import 'member_all_info.dart';

class GroupMembers extends StatefulWidget {
  @override
  _GroupMembersState createState() => _GroupMembersState();
}

class _GroupMembersState extends State<GroupMembers> {
  Future<List<Member>>? _members;

  Member? currentMember;

  Future<List<Member>> _getMembers() async {
    try {
      http.Response response = await Http.get(
            uri: generateUri(GetUriKeys.groupCurrent, context,
                params: [context.read<UserProvider>().user!.group!.id.toString()]),
            useCache: false,
          );
      Map<String, dynamic> decoded = jsonDecode(response.body);
      List<Member> members = [];
      for (var member in decoded['data']['members']) {
        members.add(Member.fromJson(member));
      }
      members.sort(
          (member1, member2) => member1.nickname.compareTo(member2.nickname));
      currentMember =
          members.firstWhere((member) => member.id == context.read<UserProvider>().user!.id);
      members.remove(currentMember);
      members.insert(0, currentMember!);
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
                  .titleLarge!
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
            )),
            FutureBuilder(
              future: _members,
              builder: (context, AsyncSnapshot<List<Member>> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Visibility(
                            visible: !currentMember!.isAdmin!,
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
                                      .titleSmall!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface),
                                  textAlign: TextAlign.center,
                                )),
                              ],
                            )),
                        Visibility(
                            visible: currentMember!.isAdmin!,
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
                                      .titleSmall!
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
                        Column(children: _generateMembers(snapshot.data!)),
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
        isCurrentUserAdmin: currentMember!.isAdmin,
        callback: this.callback,
      );
    }).toList();
  }
}

class MemberEntry extends StatefulWidget {
  final Function? callback;
  final Member member;
  final bool? isCurrentUserAdmin;

  MemberEntry({
    required this.member,
    this.isCurrentUserAdmin,
    this.callback,
  });

  @override
  _MemberEntryState createState() => _MemberEntryState();
}

class _MemberEntryState extends State<MemberEntry> {
  TextStyle? mainTextStyle;
  TextStyle? subTextStyle;
  BoxDecoration? boxDecoration;
  Color? iconColor;

  @override
  Widget build(BuildContext context) {
    User user = context.watch<UserProvider>().user!;
    String themeName = user.themeName;
    if (widget.member.id == user.id) {
      mainTextStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: themeName.contains('Gradient')
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onTertiaryContainer);
      subTextStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: themeName.contains('Gradient')
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onTertiaryContainer);
      iconColor = themeName.contains('Gradient')
          ? Theme.of(context).colorScheme.onPrimary
          : Theme.of(context).colorScheme.onTertiaryContainer;
      boxDecoration = BoxDecoration(
        gradient: AppTheme.gradientFromTheme(themeName,
            useTertiaryContainer: true),
        // color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
      );
    } else {
      mainTextStyle = Theme.of(context)
          .textTheme
          .bodyLarge!
          .copyWith(color: Theme.of(context).colorScheme.onSurface);
      subTextStyle = Theme.of(context)
          .textTheme
          .bodySmall!
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
            showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => SingleChildScrollView(
                      child: MemberAllInfo(
                        member: widget.member,
                        isCurrentUserAdmin: widget.isCurrentUserAdmin,
                      ),
                    )).then((val) {
              if (val == 'madeAdmin') widget.callback!();
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
                          visible: widget.member.isAdmin!,
                          child: Text(
                            '👑  ', //itt van egy korona emoji lol
                            style: mainTextStyle,
                          ),
                        ),
                      ),
                      Center(
                        child: Visibility(
                          visible: widget.member.isGuest!,
                          child: Text(
                            'guest'.tr(),
                            style: mainTextStyle,
                          ),
                        ),
                      )
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
