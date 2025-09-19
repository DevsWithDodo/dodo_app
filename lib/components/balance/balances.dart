import 'dart:convert';

import 'package:csocsort_szamla/components/balance/necessary_payments_button.dart';
import 'package:csocsort_szamla/components/balance/select_balance_currency.dart';
import 'package:csocsort_szamla/components/groups/member_all_info.dart';
import 'package:csocsort_szamla/components/helpers/background_paint.dart';
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

class _BalancesState extends State<Balances> with AutomaticKeepAliveClientMixin {
  @override
  get wantKeepAlive => true;

  Future<List<Member>>? _members;
  late Currency _selectedCurrency;

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
    members.sort((member1, member2) => member2.balance.compareTo(member1.balance));
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
    return CardWithBackground(
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
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                SizedBox(height: 15),
                FutureBuilder(
                  future: _members,
                  builder: (context, AsyncSnapshot<List<Member>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        final isCurrentUserAdmin = snapshot.data!
                                .firstWhere((member) => member.id == context.read<UserNotifier>().user!.id)
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
                                    .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            SizedBox(height: 4),
                            Wrap(
                              alignment: WrapAlignment.center,
                              runSpacing: 6,
                              spacing: 6,
                              children: _generateBalances(snapshot.data!),
                            ),
                            if (isCurrentUserAdmin)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: TextButton.icon(
                                    icon: Icon(Icons.add),
                                    label: Text('balances.add-member'.tr()),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddMemberPage(),
                                        ),
                                      );
                                    }),
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
            right: 10,
            top: 10,
            child: SizedBox(
              width: 70,
              child: SelectBalanceCurrency(
                selectedCurrency: _selectedCurrency,
                onCurrencyChanged: (currency) => setState(() => _selectedCurrency = currency),
              ),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _generateBalances(List<Member> members) {
    int currentMemberIndex = members.indexWhere((member) => member.id == context.read<UserNotifier>().user!.id);
    final isCurrentUserAdmin = members[currentMemberIndex].isAdmin ?? false;
    return members
        .map<Widget>((Member member) => BalanceMemberEntry(
              member: member,
              selectedCurrency: _selectedCurrency,
              isCurrentUserAdmin: isCurrentUserAdmin,
              contracted: members.length > 6,
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
    this.contracted = false,
  });

  final Member member;
  final Currency selectedCurrency;
  final bool isCurrentUserAdmin;
  final bool contracted;
  @override
  Widget build(BuildContext context) {
    final themeName = context.watch<AppThemeState>().themeName;
    TextStyle textStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
        color: member.id == context.read<UserNotifier>().user!.id
            ? AppTheme.textColorOnGradient(themeName, useSecondary: true)
            : Theme.of(context).colorScheme.onSurface);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showModalBottomSheet(
              useSafeArea: true,
              context: context,
              isScrollControlled: true,
              builder: (context) => SafeArea(
                    child: SingleChildScrollView(
                      child: MemberAllInfo(
                        member: member,
                        isCurrentUserAdmin: isCurrentUserAdmin,
                      ),
                    ),
                  ));
        },
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 12),
          height: 40,
          decoration: member.id == context.read<UserNotifier>().user!.id
              ? BoxDecoration(
                  gradient: AppTheme.gradientFromTheme(themeName, useSecondary: true),
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
            mainAxisSize: contracted ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                member.nickname,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(width: 10),
              AnimatedCrossFade(
                duration: Duration(milliseconds: 300),
                firstChild: Container(),
                secondChild: Text(
                  member.balance
                      .exchange(context.watch<UserNotifier>().currentGroup!.currency, selectedCurrency)
                      .toMoneyString(selectedCurrency),
                  style: textStyle.copyWith(fontWeight: FontWeight.w500),
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
