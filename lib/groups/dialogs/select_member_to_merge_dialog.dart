import 'dart:convert';

import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/widgets/confirm_choice_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/error_message.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/essentials/widgets/member_chips.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import '../main_group_page.dart';

class MergeGuestDialog extends StatefulWidget {
  final int guestId;
  MergeGuestDialog({@required this.guestId});
  @override
  _MergeGuestDialogState createState() => _MergeGuestDialogState();
}

class _MergeGuestDialogState extends State<MergeGuestDialog> {
  Future<List<Member>> _allMembers;
  Member _selectedMember;

  Future<bool> _mergeGuest() async {
    Map<String, dynamic> body = {'member_id': _selectedMember.memberId, 'guest_id': widget.guestId};
    await httpPost(
        context: context, uri: '/groups/' + currentGroupId.toString() + '/merge_guest', body: body);
    Future.delayed(delayTime()).then((value) => _onMergeGuest());
    return true;
  }

  void _onMergeGuest() {
    clearGroupCache();
    deleteCache(uri: generateUri(GetUriKeys.userBalanceSum));
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (context) => MainPage()), (r) => false);
  }

  Future<List<Member>> _getAllMembers() async {
    try {
      http.Response response = await httpGet(
          uri: generateUri(GetUriKeys.groupCurrent), context: context, useCache: false);
      Map<String, dynamic> decoded = jsonDecode(response.body);
      List<Member> members = [];
      print(decoded['data']['members']);
      for (var member in decoded['data']['members']) {
        members.add(Member(
          apiToken: member['api_token'],
          nickname: member['nickname'],
          memberId: member['user_id'],
          isGuest: member['is_guest'] == 1,
        ));
      }
      return members;
    } catch (_) {
      throw _;
    }
  }

  @override
  void initState() {
    super.initState();
    _allMembers = null;
    _allMembers = _getAllMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                'merge_guest'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            FutureBuilder(
              future: _allMembers,
              builder: (context, AsyncSnapshot<List<Member>> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'member_to_merge_into'.tr(),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Center(
                          child: MemberChips(
                            allowMultiple: false,
                            allMembers: snapshot.data.where((element) => !element.isGuest).toList(),
                            membersChanged: (newMembers) {
                              _selectedMember = newMembers[0];
                            },
                            membersChosen: _selectedMember != null ? [_selectedMember] : [],
                          ),
                        ),
                      ],
                    );
                  }
                  return ErrorMessage(
                    onTap: () {
                      _allMembers = null;
                      _allMembers = _getAllMembers();
                    },
                    error: snapshot.error,
                    errorLocation: 'merge_guest',
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                );
              },
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GradientButton(
                  child: Icon(
                    Icons.done,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    if (_selectedMember != null) {
                      showDialog(
                        builder: (context) => ConfirmChoiceDialog(
                          choice: 'sure_merge_guest',
                        ),
                        context: context,
                      ).then(
                        (value) {
                          if (value ?? false == true) {
                            showDialog(
                              builder: (context) => FutureSuccessDialog(
                                future: _mergeGuest(),
                                dataTrueText: 'merge_scf',
                                onDataTrue: () {
                                  _onMergeGuest();
                                },
                              ),
                              context: context,
                            );
                          }
                        },
                      );
                    } else {
                      FToast ft = FToast();
                      ft.init(context);
                      ft.showToast(child: errorToast('needs_member'.tr(), context));
                    }
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
