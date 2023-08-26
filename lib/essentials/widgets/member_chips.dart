import 'package:collection/collection.dart';
import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/essentials/widgets/custom_choice_chip.dart';
import 'package:csocsort_szamla/essentials/widgets/custom_amount_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models.dart';

class MemberChips extends StatelessWidget {
  final bool multiple;
  final List<Member> allMembers;
  final List<Member> chosenMembers;
  final ValueChanged<List<Member>> setChosenMembers;
  final bool allowCustomAmounts;
  final Map<Member, double> customAmounts;
  final ValueChanged<Map<Member, double>>? setCustomAmounts;
  final double Function()? getFullAmount;
  final String? selectedCurrency;
  final bool showAnimation;

  MemberChips({
    required this.multiple,
    required this.allMembers,
    required this.chosenMembers,
    required this.setChosenMembers,
    this.allowCustomAmounts = false,
    this.customAmounts = const {},
    this.setCustomAmounts,
    this.getFullAmount,
    this.showAnimation = true,
    this.selectedCurrency,
  }) {
    assert(!allowCustomAmounts ||
        (setCustomAmounts != null && getFullAmount != null));
  }

  double getInitialAmount(Member member, double maxAmount) {
    if (customAmounts.containsKey(member)) {
      return customAmounts[member]!;
    } else {
      double sumCustom = 0;
      customAmounts.values.forEach((element) => sumCustom += element);
      return (maxAmount - sumCustom) /
          (chosenMembers.length - customAmounts.length);
    }
  }

  double getMaxAmountWithoutCustom(Member member, double maxAmount) {
    double sumCustom = 0;
    customAmounts.values.forEach((element) => sumCustom += element);
    if (customAmounts.containsKey(member)) {
      return maxAmount - sumCustom + customAmounts[member]!;
    }
    return maxAmount - sumCustom;
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
          Color selectedColor =
              Theme.of(context).colorScheme.secondaryContainer;
          Color selectedFontColor =
              Theme.of(context).colorScheme.onSecondaryContainer;
          if (allowCustomAmounts) {
            if (!chosenMembers.contains(member)) {
              chipFillRatio = 0;
            } else {
              double maxAmount = getFullAmount!();
              if (maxAmount == 0) {
                chipFillRatio =
                    1 / (chosenMembers.length == 0 ? 1 : chosenMembers.length);
              } else {
                chipFillRatio = getInitialAmount(member, maxAmount) / maxAmount;
              }
              if (chipFillRatio > 1) {
                chipFillRatio = 1;
              }

              if (customAmounts.containsKey(member)) {
                selectedColor = Theme.of(context).colorScheme.tertiaryContainer;
                selectedFontColor =
                    Theme.of(context).colorScheme.onTertiaryContainer;
              }
            }
          } else {
            chipFillRatio = chosenMembers.contains(member) ? 1 : 0;
          }
          return CustomChoiceChip(
            member: member,
            selected: chosenMembers.contains(member),
            selectedColor: selectedColor,
            selectedFontColor: selectedFontColor,
            notSelectedColor: Theme.of(context).colorScheme.surface,
            notSelectedFontColor: Theme.of(context).colorScheme.onSurface,
            fillRatio: chipFillRatio * 1.0,
            showAnimation: showAnimation,
            onSelected: (selected) {
              if (multiple) {
                if (selected) {
                  setChosenMembers([...chosenMembers, member]);
                } else {
                  setChosenMembers(chosenMembers
                      .whereNot((m) => m.id == member.id)
                      .toList());
                  if (customAmounts.length == 1 && chosenMembers.length == 2) {
                    setCustomAmounts?.call({});
                  } else {
                    setCustomAmounts
                        ?.call(removeFromMap(customAmounts, member));
                  }
                }
              } else {
                if (selected) {
                  setChosenMembers([member]);
                } else {
                  setChosenMembers([]);
                  setCustomAmounts?.call({});
                }
              }
            },
            onLongPress: allowCustomAmounts
                ? () {
                    bool memberAdded = false;
                    if (!chosenMembers.contains(member)) {
                      setChosenMembers([...chosenMembers, member]);
                      memberAdded = true;
                    }
                    double maxMoney = getFullAmount!() * 1.0;
                    if (maxMoney == 0) {
                      showToast(
                          'purchase.page.custom-amount.toast.no-amount-given'
                              .tr(),
                          useWidgetToast: true);
                      return;
                    }
                    if (!customAmounts.containsKey(member) &&
                        ((
                          !memberAdded && 
                          chosenMembers.length - customAmounts.length == 1
                          ) || (
                            memberAdded &&
                            chosenMembers.length == customAmounts.length
                          )
                        )) {
                      showToast(
                        'purchase-page-custom-amount-toast-cannot-customize'
                            .plural(chosenMembers.length + (memberAdded ? 1 : 0)),
                        useWidgetToast: true,
                      );
                      return;
                    }
                    double initialValue = getInitialAmount(member, maxMoney);
                    double maxValue =
                        getMaxAmountWithoutCustom(member, maxMoney);
                    if (maxValue == 0) {
                      showToast(
                          'purchase.page.custom-amount.toast.no-amount-left'
                              .tr(),
                          useWidgetToast: true);
                      return;
                    }
                    showDialog(
                      context: context,
                      builder: (context) {
                        return CustomAmountDialog(
                          currency: selectedCurrency,
                          alreadyCustom: customAmounts.containsKey(member),
                          maxMoney: maxMoney,
                          initialValue: initialValue,
                          maxValue: maxValue,
                        );
                      },
                    ).then((value) {
                      if (value != null) {
                        setCustomAmounts!(value != -1
                            ? {
                                ...customAmounts,
                                member: value,
                              }
                            : removeFromMap(customAmounts, member));
                      }
                    });
                  }
                : null,
          );
        },
      ).toList(),
    );
  }

  Map<T, U> removeFromMap<T, U>(Map<T, U> map, T key) {
    Map<T, U> newMap = Map.from(map);
    newMap.remove(key);
    return newMap;
  }
}
