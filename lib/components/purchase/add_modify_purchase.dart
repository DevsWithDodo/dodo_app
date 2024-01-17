import 'dart:convert';

import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/components/helpers/category_picker_icon_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../helpers/http.dart';
import '../../helpers/models.dart';
import '../../helpers/validation_rules.dart';
import '../helpers/calculator.dart';
import '../helpers/currency_picker_icon_button.dart';
import '../helpers/custom_choice_chip.dart';
import '../helpers/error_message.dart';
import '../helpers/member_chips.dart';

enum PurchaseType { fromShopping, newPurchase, modifyPurchase }

mixin AddModifyPurchase {
  TextEditingController amountController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  Future<List<Member>>? members;
  Map<Member, bool> membersMap = Map<Member, bool>();
  Map<Member, double> customAmountMap = Map<Member, double>();
  late Currency selectedCurrency;
  FocusNode focusNode = FocusNode();
  late Function(BuildContext context) buttonPush;
  late void Function(void Function()) _setState;
  PurchaseType? purchaseType;
  ShoppingRequest? shoppingRequest;
  Purchase? savedPurchase;
  bool alreadyInitializedSave = false;
  CrossFadeState purchaserSelector = CrossFadeState.showFirst;
  int? purchaserId;
  Category? selectedCategory;
  late User user;

  GlobalKey _noteKey = GlobalKey();

  void initAddModifyPurchase(
    BuildContext context,
    void Function(void Function()) setState, {
    void Function(BuildContext context)? buttonPush,
    PurchaseType? purchaseType,
    ShoppingRequest? shoppingRequest,
    Purchase? savedPurchase,
  }) {
    assert((purchaseType == PurchaseType.fromShopping && shoppingRequest != null) ||
        (purchaseType == PurchaseType.modifyPurchase && savedPurchase != null) ||
        (purchaseType == PurchaseType.newPurchase));
    this.purchaseType = purchaseType;
    this.shoppingRequest = shoppingRequest;
    this.savedPurchase = savedPurchase;
    this.buttonPush = buttonPush ?? (context) {};
    this._setState = setState;
    this.user = context.read<UserState>().user!;
    this.selectedCurrency = user.group!.currency;
    if (purchaseType == PurchaseType.fromShopping) {
      noteController.text = shoppingRequest!.name;
    } else if (purchaseType == PurchaseType.modifyPurchase) {
      selectedCategory = savedPurchase!.category;
      selectedCurrency = savedPurchase.originalCurrency;
      noteController.text = savedPurchase.name;
      amountController.text = savedPurchase.totalAmountOriginalCurrency.toMoneyString(savedPurchase.originalCurrency);
      purchaserId = savedPurchase.buyerId;
      //Note: the receivers are set after the list of members is received from the server.
    }
    members = getMembers(context);
    focusNode.addListener(() {
      _setState(() {
        if (membersMap.entries.where((entry) => entry.value).length == 0 && customAmountMap.length != 0) {
          customAmountMap = {};
        }
        double maxAmount = double.tryParse(amountController.text) ?? 0.0;
        int oldLength = customAmountMap.length;
        customAmountMap.removeWhere((key, value) => value > maxAmount);
        if (customAmountMap.length < oldLength) {
          showToast(
            'purchase.page.custom-amount.toast.custom-larger-than-amount'.tr(),
            useWidgetToast: true,
            error: true,
            toastDuration: Duration(seconds: 4),
          );
        }
        double sumCustom = 0;
        customAmountMap.values.forEach((element) => sumCustom += element);
        if (sumCustom > maxAmount) {
          customAmountMap = {};
          showToast(
            'purchase.page.custom-amount.toast.sum-larger-than-amount'.tr(),
            useWidgetToast: true,
            error: true,
            toastDuration: Duration(seconds: 4),
          );
        }
      });
    });
    purchaserId = purchaserId ?? user.id;
  }

  Map<String, dynamic> generateBody(String name, double amount, List<Member> members, BuildContext context) {
    return {
      "name": name,
      "group": context.read<UserState>().currentGroup!.id,
      "amount": amount,
      "currency": selectedCurrency,
      "category": selectedCategory != null ? selectedCategory!.text : null,
      "buyer_id": purchaserId,
      "receivers": members
          .map((member) => {
                "user_id": member.id,
                "amount": customAmountMap.containsKey(member) ? customAmountMap[member] : null,
              })
          .toList()
    };
  }

  Future<List<Member>> getMembers(BuildContext context, {bool overwriteCache = false}) async {
    try {
      Response response = await Http.get(
        uri: generateUri(GetUriKeys.groupCurrent, context),
        overwriteCache: overwriteCache,
      );

      Map<String, dynamic> decoded = jsonDecode(response.body);
      List<Member> members = [];
      for (var member in decoded['data']['members']) {
        members.add(Member(
            nickname: member['nickname'],
            balance: (member['balance'] * 1.0),
            username: member['username'],
            id: member['user_id']));
      }
      return members;
    } catch (_) {
      throw _;
    }
  }

  double amountForNonCustom() {
    double sumCustom = 0;
    customAmountMap.values.forEach((element) => sumCustom += element);
    double amount = (double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0.0) - sumCustom;
    int membersChosen = 0;
    for (bool isChosen in membersMap.values) {
      if (isChosen) {
        membersChosen++;
      }
    }
    return amount / (membersChosen - customAmountMap.length);
  }

  Widget _categoryPickerIconButton() => Padding(
        padding: EdgeInsets.only(left: 5),
        child: CategoryPickerIconButton(
          selectedCategory: selectedCategory,
          onCategoryChanged: (newCategory) {
            _setState(() {
              if (selectedCategory?.type == newCategory?.type) {
                selectedCategory = null;
              } else {
                selectedCategory = newCategory;
              }
            });
          },
        ),
      );

  Widget noteTextField(BuildContext context, {GlobalKey? showcaseKey}) => Row(
        children: [
          Expanded(
            child: TextFormField(
              key: _noteKey,
              validator: (value) => validateTextField([
                isEmpty(value),
              ]),
              decoration: InputDecoration(
                hintText: 'note'.tr(),
                prefixIcon: Icon(
                  Icons.note,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(50)],
              controller: noteController,
              onFieldSubmitted: (value) => buttonPush(context),
            ),
          ),
          if (showcaseKey != null)
            Showcase(
              key: showcaseKey,
              showArrow: false,
              targetBorderRadius: BorderRadius.circular(10),
              targetPadding: EdgeInsets.all(0),
              description: "pick_category".tr(),
              child: _categoryPickerIconButton(),
              scaleAnimationDuration: Duration(milliseconds: 200),
            )
          else
            _categoryPickerIconButton(),
        ],
      );

  Widget _currencyPickerIconButton() => Padding(
        padding: EdgeInsets.only(right: 5),
        child: CurrencyPickerIconButton(
          selectedCurrency: selectedCurrency,
          onCurrencyChanged: (newCurrency) {
            _setState(() {
              selectedCurrency = newCurrency ?? selectedCurrency;
            });
          },
        ),
      );

  Icon _calculatorIcon(BuildContext context) => Icon(
        Icons.calculate,
        // color: Theme.of(context).colorScheme.primary,
      );

  Widget amountTextField(BuildContext context, {GlobalKey? currencyKey = null, GlobalKey? calculatorKey = null}) => Row(
        children: [
          if (currencyKey != null)
            Showcase(
              key: currencyKey,
              showArrow: false,
              targetBorderRadius: BorderRadius.circular(10),
              targetPadding: EdgeInsets.all(0),
              description: "pick_currency".tr(),
              child: _currencyPickerIconButton(),
              scaleAnimationDuration: Duration(milliseconds: 200),
            )
          else
            _currencyPickerIconButton(),
          Expanded(
            child: TextFormField(
              validator: (value) => validateTextField([
                isEmpty(value),
                notValidNumber(value!.replaceAll(',', '.')),
              ]),
              focusNode: focusNode,
              decoration: InputDecoration(hintText: 'full_amount'.tr()),
              controller: amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9\\.\\,]'))],
              onFieldSubmitted: (value) => buttonPush(context),
              onChanged: (value) => _setState(() => amountController.text = value.replaceAll(',', '.')),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 5),
            child: IconButton.filledTonal(
              isSelected: false,
              onPressed: () {
                showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (context) {
                    return SingleChildScrollView(
                      child: Calculator(
                        selectedCurrency: selectedCurrency,
                        initialNumber: amountController.text,
                        onCalculationReady: (String fromCalc) {
                          _setState(() {
                            amountController.text = (double.tryParse(fromCalc) ?? 0.0).toMoneyString(selectedCurrency);
                          });
                        },
                      ),
                    );
                  },
                );
              },
              icon: calculatorKey != null
                  ? Showcase(
                      key: calculatorKey,
                      showArrow: false,
                      targetBorderRadius: BorderRadius.circular(10),
                      targetPadding: EdgeInsets.all(10),
                      description: "use_calculator".tr(),
                      child: _calculatorIcon(context),
                      scaleAnimationDuration: Duration(milliseconds: 200),
                    )
                  : _calculatorIcon(context),
            ),
          ),
        ],
      );

  Center purchaserChooser() => Center(
        child: FutureBuilder(
          future: members,
          builder: (context, AsyncSnapshot<List<Member>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          'from_who'.tr(),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    Expanded(
                      child: Center(
                        child: AnimatedCrossFade(
                          duration: Duration(milliseconds: 300),
                          reverseDuration: Duration(seconds: 0),
                          crossFadeState: purchaserSelector,
                          firstChild: Visibility(
                            visible: purchaserSelector == CrossFadeState.showFirst,
                            child: CustomChoiceChip(
                              enabled: false,
                              selected: true,
                              showCheck: false,
                              showAnimation: true,
                              selectedColor: Theme.of(context).colorScheme.secondaryContainer,
                              selectedFontColor: Theme.of(context).colorScheme.onSecondaryContainer,
                              notSelectedColor: Theme.of(context).colorScheme.surface,
                              notSelectedFontColor: Theme.of(context).colorScheme.onSurface,
                              fillRatio: 1,
                              member: snapshot.data!.firstWhere((element) => element.id == purchaserId),
                              onSelected: (chosen) {},
                            ),
                          ),
                          secondChild: MemberChips(
                            allMembers: snapshot.data!,
                            multiple: false,
                            showAnimation: false,
                            chosenMembers: snapshot.data!.where((element) => element.id == purchaserId).toList(),
                            setChosenMembers: (newMembers) {
                              _setState(() {
                                purchaserSelector = CrossFadeState.showFirst;
                                if (newMembers.isNotEmpty) {
                                  purchaserId = newMembers.first.id;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          _setState(() {
                            if (purchaserSelector == CrossFadeState.showFirst) {
                              purchaserSelector = CrossFadeState.showSecond;
                            } else {
                              purchaserSelector = CrossFadeState.showFirst;
                            }
                          });
                        },
                        icon: Icon(
                          purchaserSelector == CrossFadeState.showSecond ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: purchaserSelector == CrossFadeState.showSecond
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                  ],
                );
              }
              return ErrorMessage(
                error: snapshot.error.toString(),
                errorLocation: 'add_purchase',
                onTap: () {
                  _setState(() {
                    members = null;
                    members = getMembers(context);
                  });
                },
              );
            }
            return CircularProgressIndicator();
          },
        ),
      );

  Center receiverChooser({GlobalKey? showcaseKey = null}) => Center(
        child: FutureBuilder(
          future: members,
          builder: (context, AsyncSnapshot<List<Member>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                for (Member member in snapshot.data!) {
                  if (!membersMap.containsKey(member)) {
                    membersMap[member] = false;
                  }
                }
                if (purchaseType == PurchaseType.fromShopping) {
                  membersMap[snapshot.data!.firstWhere((member) => member.id == shoppingRequest!.requesterId)] = true;
                } else if (purchaseType == PurchaseType.modifyPurchase && !alreadyInitializedSave) {
                  for (Member member in savedPurchase!.receivers) {
                    Member memberInMap = membersMap.keys.firstWhere((element) => element.id == member.id);
                    membersMap[memberInMap] = true;
                    if (member.isCustomAmount ?? false) {
                      customAmountMap[memberInMap] = member.balanceOriginalCurrency;
                    }
                  }
                  alreadyInitializedSave = true;
                }
                Widget memberChips = MemberChips(
                  selectedCurrency: selectedCurrency,
                  multiple: true,
                  allMembers: snapshot.data!,
                  chosenMembers: snapshot.data!.where((member) => membersMap[member]!).toList(),
                  customAmounts: customAmountMap,
                  setChosenMembers: (members) {
                    _setState(() {
                      for (Member member in snapshot.data!) {
                        membersMap[member] = members.contains(member);
                      }
                    });
                  },
                  setCustomAmounts: (Map<Member, double> amounts) {
                    _setState(() {
                      customAmountMap = amounts;
                    });
                  },
                  allowCustomAmounts: true,
                  getFullAmount: () => double.tryParse(amountController.text) ?? 0.0,
                );
                return showcaseKey != null
                    ? Showcase(
                        key: showcaseKey,
                        targetPadding: EdgeInsets.all(10),
                        targetBorderRadius: BorderRadius.circular(10),
                        description: "choose_custom_amount".tr(),
                        showArrow: false,
                        child: memberChips,
                        scaleAnimationDuration: Duration(milliseconds: 200),
                      )
                    : memberChips;
              } else {
                return ErrorMessage(
                  error: snapshot.error.toString(),
                  errorLocation: 'add_purchase',
                  onTap: () {
                    _setState(() {
                      members = null;
                      members = getMembers(context);
                    });
                  },
                );
              }
            }
            return CircularProgressIndicator();
          },
        ),
      );
}
