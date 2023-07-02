import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';

List<Payment> paymentsNeeded(List<Member> members, BuildContext context) {
  Group currentGroup = context.read<AppStateProvider>().currentGroup!;
  List<Payment> payments = <Payment>[];
  List<Member> memberCopy = <Member>[];
  if (members.where((member) => member.balance != 0).length > 0) {
    for (Member member in members) {
      memberCopy.add(new Member(
        nickname: member.nickname,
        username: member.username,
        balance: member.balance,
        id: member.id,
      ));
    }
    do {
      memberCopy.sort(
          (member1, member2) => member1.balance.compareTo(member2.balance));
      var minPerson = memberCopy[0];
      var maxPerson = memberCopy[memberCopy.length - 1];
      payments.add(
        new Payment(
          note: 'auto_payment'.tr(),
          id: -1,
          reactions: [],
          payerId: minPerson.id,
          payerUsername: minPerson.username,
          payerNickname: minPerson.nickname,
          takerId: maxPerson.id,
          takerUsername: maxPerson.username,
          takerNickname: maxPerson.nickname,
          amount: maxPerson.balance > minPerson.balance.abs()
              ? minPerson.balance.abs()
              : maxPerson.balance.abs(),
          amountOriginalCurrency: maxPerson.balance > minPerson.balance.abs()
              ? minPerson.balance.abs()
              : maxPerson.balance.abs(),
          originalCurrency: currentGroup.currency,
          updatedAt: DateTime.now(),
        ),
      );
      if (maxPerson.balance > minPerson.balance.abs()) {
        maxPerson.balance = maxPerson.balance - minPerson.balance.abs();
        minPerson.balance = 0;
      } else {
        minPerson.balance = minPerson.balance + maxPerson.balance;
        maxPerson.balance = 0;
      }
    } while (memberCopy.where((member) => member.balance > 0).length > 0 &&
        memberCopy.where((member) => member.balance < 0).length > 0);
    return payments;
  } else {
    return payments;
  }
}
