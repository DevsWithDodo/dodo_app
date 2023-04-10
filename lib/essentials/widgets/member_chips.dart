import 'package:csocsort_szamla/essentials/widgets/custom_choice_chip.dart';
import 'package:csocsort_szamla/essentials/widgets/custom_amount_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../models.dart';

class MemberChips extends StatefulWidget {
  final bool allowMultipleSelected;
  final List<Member> allMembers;
  final List<Member> chosenMembers;
  final ValueChanged<List<Member>> chosenMembersChanged;
  final bool allowCustomAmounts;
  final Map<Member, double>? customAmounts;
  final ValueChanged<Map<Member, double>>? customAmountsChanged;
  final double Function()? getMaxAmount;
  final String? selectedCurrency;
  final bool showAnimation;
  const MemberChips({
    required this.allowMultipleSelected,
    required this.allMembers,
    required this.chosenMembers,
    required this.chosenMembersChanged,
    this.allowCustomAmounts = false,
    this.customAmounts,
    this.customAmountsChanged,
    this.getMaxAmount,
    this.showAnimation = true,
    this.selectedCurrency,
  });

  @override
  State<MemberChips> createState() => _MemberChipsState();
}

class _MemberChipsState extends State<MemberChips> {
  List<Member> membersChosen = [];
  Map<Member, double> customAmounts = {};

  double getInitialAmount(Member member, double maxMoney) {
    if (customAmounts.containsKey(member)) {
      return customAmounts[member]!;
    } else {
      double sumCustom = 0;
      customAmounts.values.forEach((element) => sumCustom += element);
      return (maxMoney - sumCustom) /
          (membersChosen.length - customAmounts.length);
    }
  }

  double getMaxAmountWithoutCustom(Member member, double maxMoney) {
    double sumCustom = 0;
    customAmounts.values.forEach((element) => sumCustom += element);
    if (customAmounts.containsKey(member)) {
      return maxMoney - sumCustom + customAmounts[member]!;
    }
    return maxMoney - sumCustom;
  }

  @override
  void initState() {
    super.initState();
    membersChosen = widget.chosenMembers;
    customAmounts = widget.customAmounts ?? {};
  }

  @override
  void didUpdateWidget(covariant MemberChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    membersChosen = widget.chosenMembers;
    customAmounts = widget.customAmounts ?? {};
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allowCustomAmounts) {
      if (membersChosen.length == 0) {
        customAmounts.clear();
      }
      double maxMoney = widget.getMaxAmount!() * 1.0;
      bool customAmountRemoved = false;
      for (Member? member in membersChosen) {
        if (customAmounts.containsKey(member) &&
            customAmounts[member]! > maxMoney) {
          customAmounts.remove(member);
          customAmountRemoved = true;
        }
      }
      if (customAmountRemoved) {
        Fluttertoast.showToast(msg: 'custom_above_amount_toast'.tr());
      }
      double sumCustom = 0;
      customAmounts.values.forEach((element) => sumCustom += element);
      if (sumCustom > maxMoney) {
        customAmounts.clear();
        Fluttertoast.showToast(msg: 'sum_above_amount_toast'.tr());
      }
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: widget.allMembers.map<Widget>(
        (Member member) {
          double chipFillRatio;
          Color selectedColor =
              Theme.of(context).colorScheme.secondaryContainer;
          Color selectedFontColor =
              Theme.of(context).colorScheme.onSecondaryContainer;
          if (widget.allowCustomAmounts) {
            if (!membersChosen.contains(member)) {
              chipFillRatio = 0;
            } else {
              double maxAmount = widget.getMaxAmount!();
              if (maxAmount == 0) {
                chipFillRatio =
                    1 / (membersChosen.length == 0 ? 1 : membersChosen.length);
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
            chipFillRatio = membersChosen.contains(member) ? 1 : 0;
          }
          return CustomChoiceChip(
            member: member,
            selected: membersChosen.contains(member),
            selectedColor: selectedColor,
            selectedFontColor: selectedFontColor,
            notSelectedColor: Theme.of(context).colorScheme.surface,
            notSelectedFontColor: Theme.of(context).colorScheme.onSurface,
            fillRatio: chipFillRatio * 1.0,
            showAnimation: widget.showAnimation,
            onChipClicked: (selected) {
              setState(() {
                if (widget.allowMultipleSelected) {
                  if (selected) {
                    membersChosen.add(member);
                  } else {
                    membersChosen.remove(member);
                    customAmounts.remove(member);
                    if (customAmounts.length == membersChosen.length) {
                      customAmounts.clear();
                    }
                  }
                } else {
                  if (selected) {
                    membersChosen.clear();
                    membersChosen.add(member);
                  } else {
                    membersChosen.clear();
                    customAmounts.clear();
                  }
                }
                widget.chosenMembersChanged(membersChosen);
              });
              if (widget.customAmountsChanged != null) {
                widget.customAmountsChanged!(customAmounts);
              }
            },
            onLongPress: widget.allowCustomAmounts
                ? () {
                    if (!membersChosen.contains(member)) {
                      setState(() {
                        membersChosen.add(member);
                        widget.chosenMembersChanged(membersChosen);
                      });
                    }
                    double maxMoney = widget.getMaxAmount!() * 1.0;
                    if (maxMoney == 0) {
                      Fluttertoast.showToast(
                          msg: 'first_give_amount_toast'.tr());
                      return;
                    }
                    if (!customAmounts.containsKey(member) &&
                        membersChosen.length - customAmounts.length == 1) {
                      Fluttertoast.showToast(
                          msg: 'cant_add_custom_amount_toast'.tr());
                      return;
                    }
                    double? initialValue = getInitialAmount(member, maxMoney);
                    double maxValue =
                        getMaxAmountWithoutCustom(member, maxMoney);
                    if (maxValue == 0) {
                      Fluttertoast.showToast(msg: 'no_money_left_toast'.tr());
                      return;
                    }
                    showDialog(
                      context: context,
                      builder: (context) {
                        return CustomAmountDialog(
                          currency: widget.selectedCurrency,
                          alreadyCustom: customAmounts.containsKey(member),
                          maxMoney: maxMoney,
                          initialValue: initialValue,
                          maxValue: maxValue,
                        );
                      },
                    ).then((value) {
                      setState(() {
                        if (value != null) {
                          if (value == -1) {
                            customAmounts.remove(member);
                            return;
                          }
                          customAmounts[member] = value;
                        }
                      });
                      widget.customAmountsChanged!(customAmounts);
                    });
                    widget.customAmountsChanged!(customAmounts);
                  }
                : null,
          );
        },
      ).toList(),
    );
  }
}
