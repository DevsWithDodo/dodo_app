import 'dart:convert';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:csocsort_szamla/balance/select_balance_currency.dart';
import 'package:csocsort_szamla/essentials/payments_needed.dart';
import 'package:csocsort_szamla/essentials/widgets/error_message.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/groups/dialogs/add_guest_dialog.dart';
import 'package:csocsort_szamla/groups/dialogs/share_group_dialog.dart';
import 'package:csocsort_szamla/payment/payment_entry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../essentials/app_theme.dart';
import '../essentials/currencies.dart';
import '../essentials/models.dart';
import '../essentials/http_handler.dart';
import '../essentials/widgets/gradient_button.dart';

class Balances extends StatefulWidget {
  final Function? callback;
  final bool? bigScreen;
  Balances({this.callback, this.bigScreen});
  @override
  _BalancesState createState() => _BalancesState();
}

class _BalancesState extends State<Balances> {
  Future<List<Member>>? _members;
  String? _selectedCurrency = currentGroupCurrency;

  Future<bool> _postPayment(double amount, String note, int? takerId) async {
    try {
      Map<String, dynamic> body = {
        'group': currentGroupId,
        'amount': amount,
        'note': note,
        'taker_id': takerId
      };

      await httpPost(uri: '/payments', body: body, context: context);
      return true;
    } catch (_) {
      throw _;
    }
  }

  Future<bool> _postPayments(List<Payment> payments) async {
    for (Payment payment in payments) {
      if (await _postPayment(payment.amount! * 1.0, '\$\$auto_payment\$\$'.tr(),
          payment.takerId)) {
        continue;
      }
    }
    Future.delayed(delayTime()).then((value) => _onPostPayments());
    return true;
  }

  void _onPostPayments() {
    Navigator.pop(context);
    Navigator.pop(context);
    widget.callback!();
  }

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
        members.add(Member(
            nickname: member['nickname'],
            balance: (member['balance'] * 1.0),
            username: member['username'],
            memberId: member['user_id']));
      }
      members.sort(
          (member1, member2) => member2.balance!.compareTo(member1.balance!));
      return members;
    } catch (_) {
      throw _;
    }
  }

  @override
  void initState() {
    super.initState();
    _members = null;
    _members = _getMembers();
    _selectedCurrency = currentGroupCurrency;
  }

  @override
  void didUpdateWidget(Balances oldWidget) {
    super.didUpdateWidget(oldWidget);
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
                            (element) => element.memberId == currentUserId);
                        print(currentGroupCurrency);
                        double currencyThreshold =
                            threshold(currentGroupCurrency);
                        return Column(
                          children: [
                            // SizedBox(
                            //   height: 10,
                            // ),
                            Column(children: _generateBalances(snapshot.data!)),
                            Visibility(
                                visible: snapshot.data!.length < 2,
                                child: _oneMemberWidget()),
                            Visibility(
                              visible: currentMember == null
                                  ? false
                                  : (currentMember.balance! <
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
                                          builder: (BuildContext context) {
                                            return Dialog(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15)),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'payments_needed'.tr(),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleLarge!
                                                          .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurface),
                                                    ),
                                                    SizedBox(
                                                      height: 10,
                                                    ),
                                                    _generatePaymentsNeeded(
                                                        payments),
                                                    SizedBox(
                                                      height: 10,
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          payments.length > 0
                                                              ? MainAxisAlignment
                                                                  .spaceAround
                                                              : MainAxisAlignment
                                                                  .center,
                                                      children: [
                                                        GradientButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Text(
                                                            'back'.tr(),
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .labelLarge!
                                                                .copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onPrimary),
                                                          ),
                                                        ),
                                                        Visibility(
                                                          maintainSize: false,
                                                          maintainState: false,
                                                          maintainAnimation:
                                                              false,
                                                          maintainSemantics:
                                                              false,
                                                          replacement: SizedBox(
                                                            height: 0,
                                                          ),
                                                          visible:
                                                              payments.length >
                                                                  0,
                                                          child: GradientButton(
                                                            onPressed:
                                                                () async {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                barrierDismissible:
                                                                    true,
                                                                builder:
                                                                    (context) {
                                                                  return FutureSuccessDialog(
                                                                    future: _postPayments(
                                                                        payments),
                                                                    dataTrueText:
                                                                        'payment_scf',
                                                                    onDataTrue:
                                                                        () {
                                                                      _onPostPayments();
                                                                    },
                                                                  );
                                                                },
                                                              );
                                                            },
                                                            child: Text(
                                                              'pay'.tr(),
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .labelLarge!
                                                                  .copyWith(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .onPrimary),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              ),
                                            );
                                          });
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

  Widget _generatePaymentsNeeded(List<Payment> payments) {
    return ListView(
      shrinkWrap: true,
      children: payments.map<Widget>((Payment payment) {
        return PaymentEntry(
          payment: payment,
          isTappable: false,
        );
      }).toList(),
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
          color: member.memberId == currentUserId
              ? currentThemeName!.contains('Gradient')
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSecondary
              : Theme.of(context).colorScheme.onSurface);
      return Container(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
          decoration: member.memberId == currentUserId
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
                member.nickname!,
                style: textStyle,
              ),
              AnimatedCrossFade(
                duration: Duration(milliseconds: 300),
                firstChild: Container(),
                secondChild: Text(
                  member.balance
                      .exchange(currentGroupCurrency, _selectedCurrency)
                      .toMoneyString(_selectedCurrency),
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
                        child: Icon(
                          Icons.share,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
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
              child: Icon(
                Icons.person_add,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
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
