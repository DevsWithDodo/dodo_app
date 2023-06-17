import 'dart:convert';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:csocsort_szamla/balance/payments_needed_dialog.dart';
import 'package:csocsort_szamla/balance/select_balance_currency.dart';
import 'package:csocsort_szamla/essentials/payments_needed.dart';
import 'package:csocsort_szamla/essentials/providers/EventBusProvider.dart';
import 'package:csocsort_szamla/essentials/widgets/error_message.dart';
import 'package:csocsort_szamla/groups/dialogs/add_guest_dialog.dart';
import 'package:csocsort_szamla/groups/dialogs/share_group_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:event_bus_plus/event_bus_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config.dart';
import '../essentials/app_theme.dart';
import '../essentials/currencies.dart';
import '../essentials/http_handler.dart';
import '../essentials/models.dart';
import '../essentials/widgets/gradient_button.dart';

class Balances extends StatefulWidget {
  @override
  _BalancesState createState() => _BalancesState();
}

class _BalancesState extends State<Balances> {
  Future<List<Member>>? _members;
  String? _selectedCurrency = currentGroupCurrency;

  Future<List<Member>> _getMembers() async {
    try {
      http.Response response = await httpGet(
        uri: generateUri(GetUriKeys.groupCurrent,
            params: [currentGroupId.toString()]),
        context: context,
      );

      Map<String, dynamic> decoded = jsonDecode(response.body);
      List<Member> members = [];
      for (var member in decoded['data']['members']) {
        members.add(Member.fromJson(member));
      }
      members.sort(
          (member1, member2) => member2.balance.compareTo(member1.balance));
      return members;
    } catch (_) {
      throw _;
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<EventBus>().on<RefreshBalances>().listen((_) {
      if (mounted) {
        setState(() {
          _members = null;
          _members = _getMembers();
        });
      }
    });
    _members = null;
    _members = _getMembers();
    _selectedCurrency = currentGroupCurrency;
  }

  @override
  Widget build(BuildContext context) {
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
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                SizedBox(height: 40),
                FutureBuilder(
                  future: _members,
                  builder: (context, AsyncSnapshot<List<Member>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        Member? currentMember = snapshot.data!.firstWhereOrNull(
                            (element) => element.id == currentUserId);
                        double currencyThreshold =
                            threshold(currentGroupCurrency!);
                        return Column(
                          children: [
                            Column(children: _generateBalances(snapshot.data!)),
                            Visibility(
                                visible: snapshot.data!.length < 2,
                                child: _oneMemberWidget()),
                            Visibility(
                              visible: currentMember == null
                                  ? false
                                  : (currentMember.balance <
                                      -currencyThreshold),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 10,
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      List<Payment> payments = paymentsNeeded(
                                              snapshot.data!)
                                          .where((payment) =>
                                              payment.payerId == currentUserId)
                                          .toList();
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (BuildContext context) =>
                                            PaymentsNeededDialog(
                                                payments: payments),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'who_to_pay'.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
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
            SelectBalanceCurrency(
              selectedCurrency: _selectedCurrency,
              onCurrencyChange: (selectedCurrency) {
                setState(() {
                  _selectedCurrency = selectedCurrency;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getInvitation() async {
    try {
      http.Response response = await httpGet(
        uri: generateUri(GetUriKeys.groupCurrent,
            params: [currentGroupId.toString()]),
        context: context,
      );
      Map<String, dynamic> decoded = jsonDecode(response.body);
      return decoded['data']['invitation'];
    } catch (_) {
      throw _;
    }
  }

  List<Widget> _generateBalances(List<Member> members) {
    return members.map<Widget>((Member member) {
      TextStyle textStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: member.id == currentUserId
              ? currentThemeName.contains('Gradient')
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSecondary
              : Theme.of(context).colorScheme.onSurface);
      return Container(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
          decoration: member.id == currentUserId
              ? BoxDecoration(
                  gradient: AppTheme.gradientFromTheme(currentThemeName,
                      useSecondary: true),
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
                      .exchange(currentGroupCurrency!, _selectedCurrency!)
                      .toMoneyString(_selectedCurrency!),
                  style: textStyle,
                ),
                crossFadeState: CrossFadeState.showSecond,
              ),
            ],
          ));
    }).toList();
  }

  Widget _oneMemberWidget() {
    return Column(
      children: [
        SizedBox(height: 20),
        Text(
          'you_seem_lonely'.tr(),
          style: Theme.of(context)
              .textTheme
              .titleLarge!
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        SizedBox(height: 10),
        Text('invite_friends'.tr(),
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.onSurface)),
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
                              builder: (context) {
                                return ShareGroupDialog(
                                    inviteCode: snapshot.data!);
                              });
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
                  onTap: () {
                    setState(() {});
                  },
                );
              }
            }
            return Center(child: CircularProgressIndicator());
          },
        ),
        SizedBox(height: 10),
        Text('add_guests_offline'.tr(),
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.onSurface)),
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
                    });
              },
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          'you_seem_lonely_explanation'.tr(),
          style: Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}
