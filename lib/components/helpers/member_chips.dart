import 'package:collection/collection.dart';
import 'package:csocsort_szamla/components/helpers/custom_choice_chip.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:flutter/material.dart';

import '../../helpers/models.dart';

class MemberChips extends StatelessWidget {
  final bool multiple;
  final List<Member> allMembers;
  final List<int> chosenMemberIds;
  final ValueChanged<List<int>> setChosenMemberIds;
  final bool allowCustomAmounts;
  final Map<int, double>? customAmounts;
  final double? fullAmount;
  final Currency? selectedCurrency;
  final bool showAnimation;

  MemberChips({
    required this.multiple,
    required this.allMembers,
    required this.chosenMemberIds,
    required this.setChosenMemberIds,
    this.allowCustomAmounts = false,
    this.customAmounts,
    this.fullAmount,
    this.showAnimation = true,
    this.selectedCurrency,
  }) {
    assert(!allowCustomAmounts || (fullAmount != null && customAmounts != null));
  }



  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: allMembers.map<Widget>(
        (Member member) {
          double chipFillRatio;
          Color selectedColor = Theme.of(context).colorScheme.secondaryContainer;
          Color selectedFontColor = Theme.of(context).colorScheme.onSecondaryContainer;
          if (allowCustomAmounts) {
            if (!chosenMemberIds.contains(member.id)) {
              chipFillRatio = 0;
            } else {
              double maxAmount = fullAmount!;
              if (maxAmount == 0) {
                chipFillRatio = 1 / (chosenMemberIds.length == 0 ? 1 : chosenMemberIds.length);
              } else {
                double memberAmount;
                if (customAmounts!.containsKey(member.id)) {
                  memberAmount = customAmounts![member.id]!;
                } else {
                  double sumCustom = customAmounts!.values.fold(0, (previousValue, element) => previousValue + element);
                  memberAmount =(maxAmount - sumCustom) / (chosenMemberIds.length - customAmounts!.length);
                }
                chipFillRatio = memberAmount / maxAmount;
              }
              if (chipFillRatio > 1) {
                chipFillRatio = 1;
              }
            }
          } else {
            chipFillRatio = chosenMemberIds.contains(member.id) ? 1 : 0;
          }
          return CustomChoiceChip(
            member: member,
            selected: chosenMemberIds.contains(member.id),
            selectedColor: selectedColor,
            selectedFontColor: selectedFontColor,
            notSelectedColor: Theme.of(context).colorScheme.surface,
            notSelectedFontColor: Theme.of(context).colorScheme.onSurface,
            fillRatio: chipFillRatio * 1.0,
            showAnimation: showAnimation,
            onSelected: (selected) {
              if (multiple) {
                if (selected) {
                  setChosenMemberIds([...chosenMemberIds, member.id]);
                } else {
                  setChosenMemberIds(chosenMemberIds.whereNot((id) => id == member.id).toList());
                }
              } else {
                if (selected) {
                  setChosenMemberIds([member.id]);
                } else {
                  setChosenMemberIds([]);
                }
              }
            },
          );
        },
      ).toList(),
    );
  }

}
