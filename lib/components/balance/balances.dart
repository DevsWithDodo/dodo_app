import 'dart:convert';

import 'package:csocsort_szamla/components/balance/necessary_payments_button.dart';
import 'package:csocsort_szamla/components/balance/select_balance_currency.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/providers/app_state_provider.dart';
import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/components/groups/dialogs/add_guest_dialog.dart';
import 'package:csocsort_szamla/components/groups/dialogs/share_group_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../helpers/app_theme.dart';
import '../../helpers/currencies.dart';
import '../../helpers/http.dart';
import '../../helpers/models.dart';
import '../helpers/gradient_button.dart';

class Balances extends StatefulWidget {
  @override
  _BalancesState createState() => _BalancesState();
}

class _BalancesState extends State<Balances> with AutomaticKeepAliveClientMixin {
  @override
  get wantKeepAlive => true;

  Future<List<Member>>? _members;
  late String _selectedCurrency;

  Future<List<Member>> _getMembers() async {
    try {
      Response response = await Http.get(
          uri: generateUri(GetUriKeys.groupCurrent, context,
              params: [context.read<AppStateProvider>().user!.group!.id.toString()]));
      Map<String, dynamic> decoded = jsonDecode(response.body);
      List<Member> members = [];
      for (var member in decoded['data']['members']) {
        members.add(Member.fromJson(member));
      }
      members.sort((member1, member2) => member2.balance.compareTo(member1.balance));
      return members;
    } catch (_) {
      throw _;
    }
  }

  void onRefreshBalancesEvent() {
    setState(() {
      _members = null;
      _members = _getMembers();
      _selectedCurrency = context.read<AppStateProvider>().user!.group!.currency;
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
    _selectedCurrency = context.read<AppStateProvider>().user!.group!.currency;
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
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                SizedBox(height: 40),
                FutureBuilder(
                  future: _members,
                  builder: (context, AsyncSnapshot<List<Member>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        return Column(
                          children: [
                            ..._generateBalances(snapshot.data!),
                            Visibility(
                              visible: snapshot.data!.length < 2,
                              child: _oneMemberWidget(),
                            ),
                            NecessaryPaymentsButton(members: snapshot.data!)
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
            Positioned(
              right: 0,
              width: 90,
              child: SelectBalanceCurrency(
                selectedCurrency: _selectedCurrency,
                onCurrencyChange: (selectedCurrency) {
                  setState(() {
                    _selectedCurrency = selectedCurrency;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getInvitation() async {
    try {
      Response response = await Http.get(
        uri: generateUri(
          GetUriKeys.groupCurrent,
          context,
          params: [context.read<AppStateProvider>().user!.group!.id.toString()],
        ),
      );
      Map<String, dynamic> decoded = jsonDecode(response.body);
      return decoded['data']['invitation'];
    } catch (_) {
      throw _;
    }
  }

  List<Widget> _generateBalances(List<Member> members) {
    ThemeName themeName = context.watch<AppStateProvider>().themeName;
    return members.map<Widget>((Member member) {
      TextStyle textStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: member.id == context.read<AppStateProvider>().user!.id
              ? themeName.type == ThemeType.gradient
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSecondary
              : Theme.of(context).colorScheme.onSurface);
      return Container(
        padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: member.id == context.read<AppStateProvider>().user!.id
            ? BoxDecoration(
                gradient: AppTheme.gradientFromTheme(themeName, useSecondary: true),
                borderRadius: BorderRadius.circular(15),
              )
            : null,
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
                member.balance
                    .exchange(context.watch<AppStateProvider>().currentGroup!.currency, _selectedCurrency)
                    .toMoneyString(_selectedCurrency),
                style: textStyle,
              ),
              crossFadeState: CrossFadeState.showSecond,
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _oneMemberWidget() {
    return Column(
      children: [
        SizedBox(height: 20),
        Text(
          'you_seem_lonely'.tr(),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        SizedBox(height: 10),
        Text(
          'invite_friends'.tr(),
          style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        SizedBox(height: 5),
        FutureBuilder(
          future: _getInvitation(),
          builder: (context, AsyncSnapshot<String> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                return Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GradientButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => ShareGroupDialog(inviteCode: snapshot.data!),
                          );
                        },
                        child: Icon(Icons.share),
                      ),
                    ],
                  ),
                );
              } else {
                return ErrorMessage(
                  error: snapshot.error.toString(),
                  errorLocation: 'invitation',
                  onTap: () => setState(() {}),
                );
              }
            }
            return Center(child: CircularProgressIndicator());
          },
        ),
        SizedBox(height: 10),
        Text('add_guests_offline'.tr(),
            style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurface)),
        SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GradientButton(
              child: Icon(Icons.person_add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AddGuestDialog();
                  },
                );
              },
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          'you_seem_lonely_explanation'.tr(),
          style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurface),
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}
