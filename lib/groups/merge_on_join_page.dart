import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/essentials/widgets/member_chips.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../essentials/models.dart';

class MergeOnJoinPage extends StatefulWidget {
  final List<Member> guests;
  MergeOnJoinPage({required this.guests});
  @override
  State<MergeOnJoinPage> createState() => _MergeOnJoinPageState();
}

class _MergeOnJoinPageState extends State<MergeOnJoinPage> {
  Member? _selectedMember;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('merge_with_guest'.tr()),
      ),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(35),
          children: [
            Text(
              'merge_with_guest_explanation'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 15),
            Text(
              'guests_in_group'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge!
                  .copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            SizedBox(height: 10),
            MemberChips(
              showAnimation: false,
              allowMultipleSelected: false,
              allMembers: widget.guests,
              chosenMembersChanged: (newMembers) {
                setState(() {
                  _selectedMember =
                      newMembers.isEmpty ? null : newMembers.first;
                });
              },
              chosenMembers: _selectedMember == null ? [] : [_selectedMember!],
            ),
            SizedBox(height: 35),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GradientButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('skip'.tr()),
                ),
                GradientButton(
                  disabled: _selectedMember == null,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return FutureSuccessDialog(future: _mergeWithGuest());
                      },
                    );
                  },
                  child: Text('merge'.tr()),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<bool> _mergeWithGuest() async {
    try {
      Map<String, dynamic> body = {
        'member_id': context.read<AppStateProvider>().user!.id,
        'guest_id': _selectedMember!.id
      };
      await Http.post(
            uri: '/groups/' + context.read<AppStateProvider>().currentGroup!.id.toString() + '/merge_guest',
            body: body,
          );
      Future.delayed(delayTime()).then((value) => _onMergeGuest());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onMergeGuest() {
    Navigator.pop(context);
    Navigator.pop(context);
  }
}
