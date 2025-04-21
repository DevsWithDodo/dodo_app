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
  const Balances({super.key});

  @override
  State<Balances> createState() => _BalancesState();
}

class _BalancesState extends State<Balances>
    with AutomaticKeepAliveClientMixin {
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
          context.read<UserNotifier>().user!.group!.id.toString(),
        ],
      ),
    );
    Map<String, dynamic> decoded = jsonDecode(response.body);
    List<Member> members = [];
    for (var member in decoded['data']['members']) {
      members.add(Member.fromJson(member));
    }
    members
        .sort((member1, member2) => member2.balance.compareTo(member1.balance));
    return members;
  }

  void onRefreshBalancesEvent() {
    setState(() {
      _members = null;
      _members = _getMembers();
      _selectedCurrency = context.read<UserNotifier>().user!.group!.currency;
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
    _selectedCurrency = context.read<UserNotifier>().user!.group!.currency;
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Text(
                    'balances'.tr(),
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                SizedBox(height: 15),
                FutureBuilder(
                  future: _members,
                  builder: (context, AsyncSnapshot<List<Member>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        final isCurrentUserAdmin = snapshot.data!
                                .firstWhere((member) =>
                                    member.id ==
                                    context.read<UserNotifier>().user!.id)
                                .isAdmin ??
                            false;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            NecessaryPaymentsButton(members: snapshot.data!),
                            Text('balances.tap-info'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant)),
                            SizedBox(height: 4),
                            Wrap(
                              alignment: WrapAlignment.center,
                              runSpacing: 8,
                              spacing: 8,
                              children: _generateBalances(snapshot.data!),
                            ),
                            if (isCurrentUserAdmin)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: TextButton.icon(
                                    // usePrimaryContaine r: true,
                                    icon: Icon(Icons.add),
                                    label: Text('balances.add-member'.tr()),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddMemberPage(),
                                        ),
                                      );
                                      setState(() {
                                        showAll = true;
                                      });
                                    }),
                              ),
                            // Padding(
                            //   padding: const EdgeInsets.only(top: 8.0),
                            //   child: InkWell(
                            //     borderRadius: BorderRadius.circular(12),
                            //     onTap: () async {
                            //       await Navigator.push(
                            //         context,
                            //         MaterialPageRoute(
                            //           builder: (context) => AddMemberPage(),
                            //         ),
                            //       );
                            //       setState(() {
                            //         showAll = true;
                            //       });
                            //     },
                            //     child: Ink(
                            //       height: 48,
                            //       decoration: BoxDecoration(
                            //         color: Theme.of(context)
                            //             .colorScheme
                            //             .surfaceContainerHigh,
                            //         borderRadius: BorderRadius.circular(12),
                            //       ),
                            //       child: Padding(
                            //         padding: const EdgeInsets.symmetric(
                            //             horizontal: 12),
                            //         child: Row(
                            //           mainAxisAlignment:
                            //               MainAxisAlignment.center,
                            //           crossAxisAlignment:
                            //               CrossAxisAlignment.center,
                            //           mainAxisSize: MainAxisSize.min,
                            //           children: [
                            //             Icon(Icons.add,
                            //                 color: Theme.of(context)
                            //                     .colorScheme
                            //                     .onSurface),
                            //             SizedBox(width: 5),
                            //             Text(
                            //               'balances.add-member'.tr(),
                            //               style: Theme.of(context)
                            //                   .textTheme
                            //                   .bodyLarge!
                            //                   .copyWith(
                            //                       color: Theme.of(context)
                            //                           .colorScheme
                            //                           .onSurface),
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                            // ),
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
            right: 10,
            top: 10,
            child: SizedBox(
              width: 70,
              child: SelectBalanceCurrency(
                selectedCurrency: _selectedCurrency,
                onCurrencyChanged: (currency) =>
                    setState(() => _selectedCurrency = currency),
              ),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _generateBalances(List<Member> members) {
    int currentMemberIndex = members.indexWhere(
        (member) => member.id == context.read<UserNotifier>().user!.id);
    final isCurrentUserAdmin = members[currentMemberIndex].isAdmin ?? false;
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
        color: member.id == context.read<UserNotifier>().user!.id
            ? themeName.type == ThemeType.gradient
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSecondary
            : Theme.of(context).colorScheme.onSurface);
    return InkWell(
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
        decoration: member.id == context.read<UserNotifier>().user!.id
            ? BoxDecoration(
                gradient:
                    AppTheme.gradientFromTheme(themeName, useSecondary: true),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              )
            : BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  member.nickname,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            SizedBox(width: 10),
            AnimatedCrossFade(
              duration: Duration(milliseconds: 300),
              firstChild: Container(),
              secondChild: Text(
                member.balance
                    .exchange(
                        context.watch<UserNotifier>().currentGroup!.currency,
                        selectedCurrency)
                    .toMoneyString(selectedCurrency),
                style: textStyle,
              ),
              crossFadeState: CrossFadeState.showSecond,
            ),
          ],
        ),
      ),
    );
  }
}
