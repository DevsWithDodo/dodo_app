import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:csocsort_szamla/components/helpers/confirm_choice_dialog.dart';
import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/helpers/member_chips.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class MergeGuestDialog extends StatefulWidget {
  final int guestId;
  MergeGuestDialog({required this.guestId});
  @override
  _MergeGuestDialogState createState() => _MergeGuestDialogState();
}

class _MergeGuestDialogState extends State<MergeGuestDialog> {
  Future<List<Member>>? _allMembers;
  Member? _selectedMember;

  Future<BoolFutureOutput> _mergeGuest() async {
    Map<String, dynamic> body = {'member_id': _selectedMember!.id, 'guest_id': widget.guestId};
    await Http.post(uri: '/groups/' + context.read<UserState>().currentGroup!.id.toString() + '/merge_guest', body: body);
    return BoolFutureOutput.True;
  }

  Future<List<Member>> _getAllMembers() async {
    try {
      Response response = await Http.get(uri: generateUri(GetUriKeys.groupCurrent, context), useCache: false);
      Map<String, dynamic> decoded = jsonDecode(response.body);
      List<Member> members = [];
      for (var memberJson in decoded['data']['members']) {
        members.add(Member.fromJson(memberJson));
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
                style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
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
                            multiple: false,
                            allMembers: snapshot.data!.where((element) => !element.isGuest!).toList(),
                            setChosenMemberIds: (newMemberIds) {
                              setState(() {
                                _selectedMember = snapshot.data!.firstWhereOrNull(
                                  (element) => element.id == newMemberIds.firstOrNull,
                                );
                              });
                            },
                            chosenMemberIds: _selectedMember == null ? [] : [_selectedMember!.id],
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
                    error: snapshot.error as String?,
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
                  child: Icon(Icons.done),
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
                            showFutureOutputDialog(
                              context: context,
                              future: _mergeGuest(),
                              outputCallbacks: {
                                BoolFutureOutput.True: () async {
                                  EventBus.instance.fire(EventBus.refreshBalances);
                                  EventBus.instance.fire(EventBus.refreshPurchases);
                                  EventBus.instance.fire(EventBus.refreshPayments);
                                  EventBus.instance.fire(EventBus.refreshShopping);
                                  EventBus.instance.fire(EventBus.refreshGroupMembers);
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                }
                              },
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
