import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models.dart';

List<Payment> necessaryPayments(List<Member> members, BuildContext context) {
  Group currentGroup = context.read<UserNotifier>().currentGroup!;
  List<Payment> payments = <Payment>[];
  List<Member> memberCopy = <Member>[];
  if (members.where((member) => member.balance != 0).isNotEmpty) {
    for (Member member in members) {
      memberCopy.add(Member(
        nickname: member.nickname,
        username: member.username,
        balance: member.balance,
        id: member.id,
      ));
    }
    do {
      memberCopy.sort((member1, member2) => member1.balance.compareTo(member2.balance));
      var minPerson = memberCopy[0];
      var maxPerson = memberCopy[memberCopy.length - 1];
      payments.add(
        Payment(
          note: 'auto_payment'.tr(),
          id: -1,
          reactions: [],
          payerId: minPerson.id,
          payerNickname: minPerson.nickname,
          takerId: maxPerson.id,
          takerNickname: maxPerson.nickname,
          amount: maxPerson.balance > minPerson.balance.abs() ? minPerson.balance.abs() : maxPerson.balance.abs(),
          amountOriginalCurrency: maxPerson.balance > minPerson.balance.abs() ? minPerson.balance.abs() : maxPerson.balance.abs(),
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
    } while (memberCopy.where((member) => member.balance > 0).isNotEmpty && memberCopy.where((member) => member.balance < 0).isNotEmpty);
    return payments;
  } else {
    return payments;
  }
}
