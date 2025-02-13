import 'dart:convert';

import 'package:csocsort_szamla/components/balance/necessary_payments_button.dart';
import 'package:csocsort_szamla/components/balance/select_balance_currency.dart';
import 'package:csocsort_szamla/components/groups/member_all_info.dart';
import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/add_member_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../helpers/app_theme.dart';
import '../../helpers/currencies.dart';
import '../../helpers/http.dart';
import '../../helpers/models.dart';

class Balances extends StatefulWidget {
  @override
  _BalancesState createState() => _BalancesState();
}

class _BalancesState extends State<Balances> with AutomaticKeepAliveClientMixin {
  @override
  get wantKeepAlive => true;

  Future<List<Member>>? _members;
  late Currency _selectedCurrency;
  bool showAll = false;

  Future<List<Member>> _getMembers() async {
    Response response = await Http.get(
      uri: generateUri(
        GetUriKeys.groupCurrent,
        context,
        params: [
          context.read<UserState>().user!.group!.id.toString(),
        ],
      ),
    );
    Map<String, dynamic> decoded = jsonDecode(response.body);
    List<Member> members = [];
    print(decoded);
    for (var member in decoded['data']['members']) {
      members.add(Member.fromJson(member));
    }
    members.sort((member1, member2) => member2.balance.compareTo(member1.balance));
    return members;
  }

  void onRefreshBalancesEvent() {
    setState(() {
      _members = null;
      _members = _getMembers();
      _selectedCurrency = context.read<UserState>().user!.group!.currency;
    });
  }

  @override
  void initState() {
    super.initState();
    EventBus.instance.register(
      EventBus.refreshBalances,
      onRefreshBalancesEvent,
    );
    _members = null;
    _members = _getMembers();
    _selectedCurrency = context.read<UserState>().user!.group!.currency;
  }

  @override
  void dispose() {
    EventBus.instance.unregister(
      EventBus.refreshBalances,
      onRefreshBalancesEvent,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Card(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Text(
                    'balances'.tr(),
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                SizedBox(height: 15),
                FutureBuilder(
                  future: _members,
                  builder: (context, AsyncSnapshot<List<Member>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        final isCurrentUserAdmin = snapshot.data!.firstWhere((member) => member.id == context.read<UserState>().user!.id).isAdmin ?? false;
                        return Column(
                          children: [
                            NecessaryPaymentsButton(members: snapshot.data!),
                            ..._generateBalances(snapshot.data!),
                            if (isCurrentUserAdmin)
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddMemberPage(),
                                    ),
                                  );
                                  setState(() {
                                    showAll = true;
                                  });
                                },
                                child: Ink(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add, color: Theme.of(context).colorScheme.onSurface),
                                        SizedBox(width: 5),
                                        Text(
                                          'balances.add-member'.tr(),
                                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (snapshot.data!.length > 7)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Center(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                    onPressed: () => setState(() => showAll = !showAll),
                                    label: Text(showAll ? 'balances.collapse' : 'balances.expand').tr(),
                                    icon: Icon(showAll ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                                  ),
                                ),
                              ),
                          ],
                        );
                      } else {
                        return ErrorMessage(
                          error: snapshot.error.toString(),
                          errorLocation: 'balances',
                          onTap: () {
                            setState(() {
                              _members = null;
                              _members = _getMembers();
                            });
                          },
                        );
                      }
                    }
                    return Center(child: CircularProgressIndicator());
                  },
                )
              ],
            ),
          ),
          Positioned(
            child: Container(
              width: 70,
              child: SelectBalanceCurrency(
                selectedCurrency: _selectedCurrency,
                onCurrencyChanged: (currency) => setState(() => _selectedCurrency = currency),
              ),
            ),
            right: 10,
            top: 10,
          )
        ],
      ),
    );
  }

  List<Widget> _generateBalances(List<Member> members) {
    int currentMemberIndex = members.indexWhere((member) => member.id == context.read<UserState>().user!.id);
    final isCurrentUserAdmin = members[currentMemberIndex].isAdmin ?? false;
    if (members.length > 7 && !showAll) {
      List<Member> membersToShow = [];
      if (currentMemberIndex < 3 || currentMemberIndex > members.length - 3) {
        membersToShow.addAll(members.sublist(0, 3));
        membersToShow.addAll(members.sublist(members.length - 2));
      } else {
        membersToShow.addAll(members.sublist(0, 2));
        membersToShow.add(members[currentMemberIndex]);
        membersToShow.addAll(members.sublist(members.length - 2));
      }
      return membersToShow
          .map<Widget>((Member member) => BalanceMemberEntry(
                member: member,
                selectedCurrency: _selectedCurrency,
                isCurrentUserAdmin: isCurrentUserAdmin,
              ))
          .toList();
    }
    return members
        .map<Widget>((Member member) => BalanceMemberEntry(
              member: member,
              selectedCurrency: _selectedCurrency,
              isCurrentUserAdmin: isCurrentUserAdmin,
            ))
        .toList();
  }
}

class BalanceMemberEntry extends StatelessWidget {
  const BalanceMemberEntry({
    super.key,
    required this.member,
    required this.selectedCurrency,
    this.isCurrentUserAdmin = false,
  });

  final Member member;
  final Currency selectedCurrency;
  final bool isCurrentUserAdmin;

  @override
  Widget build(BuildContext context) {
    final themeName = context.watch<AppThemeState>().themeName;
    TextStyle textStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
        color: member.id == context.read<UserState>().user!.id
            ? themeName.type == ThemeType.gradient
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSecondary
            : Theme.of(context).colorScheme.onSurface);
    return Container(
      margin: EdgeInsets.only(bottom: 7),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => SingleChildScrollView(
                    child: MemberAllInfo(
                      member: member,
                      isCurrentUserAdmin: isCurrentUserAdmin,
                    ),
                  )).then((val) {
            // if (val == 'madeAdmin') onChangedMember();
          });
        },
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 12),
          height: 48,
          decoration: member.id == context.read<UserState>().user!.id
              ? BoxDecoration(
                  gradient: AppTheme.gradientFromTheme(themeName, useSecondary: true),
                  borderRadius: BorderRadius.circular(12),
                )
              : BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                member.nickname,
                style: textStyle,
              ),
              AnimatedCrossFade(
                duration: Duration(milliseconds: 300),
                firstChild: Container(),
                secondChild: Text(
                  member.balance.exchange(context.watch<UserState>().currentGroup!.currency, selectedCurrency).toMoneyString(selectedCurrency),
                  style: textStyle,
                ),
                crossFadeState: CrossFadeState.showSecond,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
