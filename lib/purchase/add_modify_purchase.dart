import 'dart:convert';
import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/essentials/widgets/category_picker_icon_button.dart';
import 'package:csocsort_szamla/shopping/shopping_list_entry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

import '../config.dart';
import '../essentials/app_theme.dart';
import '../essentials/http_handler.dart';
import '../essentials/models.dart';
import '../essentials/validation_rules.dart';
import '../essentials/widgets/calculator.dart';
import '../essentials/widgets/currency_picker_icon_button.dart';
import '../essentials/widgets/custom_choice_chip.dart';
import '../essentials/widgets/error_message.dart';
import '../essentials/widgets/member_chips.dart';

enum PurchaseType { fromShopping, newPurchase, modifyPurchase }

class AddModifyPurchase {
  TextEditingController amountController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  Future<List<Member>> members;
  Map<Member, bool> membersMap = Map<Member, bool>();
  Map<Member, double> customAmountMap = Map<Member, double>();
  String selectedCurrency = currentGroupCurrency;
  FocusNode focusNode = FocusNode();
  Function(BuildContext context) buttonPush;
  void Function(void Function()) _setState;
  PurchaseType purchaseType;
  ShoppingRequestData shoppingRequest;
  Purchase savedPurchase;
  bool alreadyInitializedSave = false;
  ThemeData theme = AppTheme.themes[currentThemeName];
  CrossFadeState purchaserSelector = CrossFadeState.showFirst;
  int purchaserId;
  Category selectedCategory;

  void initAddModifyPurchase(
    BuildContext context,
    void Function(void Function()) setState, {
    void Function(BuildContext context) buttonPush,
    PurchaseType purchaseType,
    ShoppingRequestData shoppingRequest,
    Purchase savedPurchase,
  }) {
    assert((purchaseType == PurchaseType.fromShopping && shoppingRequest != null) ||
        (purchaseType == PurchaseType.modifyPurchase && savedPurchase != null) ||
        (purchaseType == PurchaseType.newPurchase));
    this.purchaseType = purchaseType;
    this.shoppingRequest = shoppingRequest;
    this.savedPurchase = savedPurchase;
    this.buttonPush = buttonPush ?? (context) {};
    this._setState = setState;
    if (purchaseType == PurchaseType.fromShopping) {
      noteController.text = shoppingRequest.name;
    } else if (purchaseType == PurchaseType.modifyPurchase) {
      selectedCurrency = savedPurchase.originalCurrency;
      noteController.text = savedPurchase.name;
      amountController.text =
          savedPurchase.totalAmountOriginalCurrency.toMoneyString(savedPurchase.originalCurrency);
      purchaserId = savedPurchase.buyerId;
      //Note: the receivers are set after the list of members is received from the server.
    }
    members = getMembers(context);
    focusNode.addListener(() {
      _setState(() {});
    });
    purchaserId = purchaserId ?? currentUserId;
  }

  Map<String, dynamic> generateBody(String name, double amount, List<Member> members) {
    return {
      "name": name,
      "group": currentGroupId,
      "amount": amount,
      "currency": selectedCurrency,
      "category": selectedCategory != null ? selectedCategory.text : null,
      "buyer_id": purchaserId,
      "receivers": members
          .map((member) => {
                "user_id": member.memberId,
                "amount": customAmountMap.containsKey(member) ? customAmountMap[member] : null,
              })
          .toList()
    };
  }

  Future<List<Member>> getMembers(BuildContext context, {bool overwriteCache = false}) async {
    try {
      http.Response response = await httpGet(
        uri: generateUri(GetUriKeys.groupCurrent),
        context: context,
        overwriteCache: overwriteCache,
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
      return members;
    } catch (_) {
      throw _;
    }
  }

  double amountForNonCustom() {
    double sumCustom = 0;
    customAmountMap.values.forEach((element) => sumCustom += element);
    double amount = (double.tryParse(amountController.text) ?? 0.0) - sumCustom;
    int membersChosen = 0;
    for (bool isChosen in membersMap.values) {
      if (isChosen) {
        membersChosen++;
      }
    }
    return amount / (membersChosen - customAmountMap.length);
  }

  TextFormField noteTextField(BuildContext context) => TextFormField(
        validator: (value) => validateTextField({
          isEmpty: [value],
          minimalLength: [value, 3],
        }),
        decoration: InputDecoration(
          hintText: 'note'.tr(),
          prefixIcon: Icon(
            Icons.note,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: GestureDetector(
            onDoubleTap: () {
              _setState(() {
                selectedCategory = null;
              });
            },
            child: CategoryPickerIconButton(
              selectedCategory: selectedCategory,
              onCategoryChanged: (newCategory) {
                _setState(() {
                  selectedCategory = newCategory ?? selectedCategory;
                });
              },
            ),
          ),
        ),
        inputFormatters: [LengthLimitingTextInputFormatter(50)],
        controller: noteController,
        onFieldSubmitted: (value) => buttonPush(context),
      );
  TextFormField amountTextField(BuildContext context) => TextFormField(
        validator: (value) => validateTextField({
          isEmpty: [value],
          notValidNumber: [
            value.replaceAll(',', '.'),
          ]
        }),
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: 'full_amount'.tr(),
          prefixIcon: GestureDetector(
            onDoubleTap: () {
              _setState(() {
                selectedCurrency = currentGroupCurrency;
              });
            },
            child: CurrencyPickerIconButton(
              selectedCurrency: selectedCurrency,
              onCurrencyChanged: (newCurrency) {
                _setState(() {
                  selectedCurrency = newCurrency ?? selectedCurrency;
                });
              },
            ),
          ),
          suffixIcon: IconButton(
            onPressed: () {
              showModalBottomSheet(
                isScrollControlled: true,
                context: context,
                builder: (context) {
                  return SingleChildScrollView(
                    child: Calculator(
                      initialNumber: amountController.text,
                      onCalculationReady: (String fromCalc) {
                        _setState(() {
                          amountController.text =
                              (double.tryParse(fromCalc) ?? 0.0).toMoneyString(selectedCurrency);
                        });
                      },
                    ),
                  );
                },
              );
            },
            icon: Icon(
              Icons.calculate,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        controller: amountController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9\\.\\,]'))],
        onFieldSubmitted: (value) => buttonPush(context),
      );

  Center purchaserChooser(BuildContext context) => Center(
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
                              noAnimation: true,
                              selectedColor: Theme.of(context).colorScheme.secondaryContainer,
                              selectedFontColor: Theme.of(context).colorScheme.onSecondaryContainer,
                              notSelectedColor: Theme.of(context).colorScheme.surface,
                              notSelectedFontColor: Theme.of(context).colorScheme.onSurface,
                              fillRatio: 1,
                              member: snapshot.data
                                  .firstWhere((element) => element.memberId == purchaserId),
                              onMemberChosen: (chosen) {},
                            ),
                          ),
                          secondChild: MemberChips(
                            allMembers: snapshot.data,
                            allowMultiple: false,
                            noAnimation: true,
                            membersChosen: snapshot.data
                                .where((element) => element.memberId == purchaserId)
                                .toList(),
                            membersChanged: (newMembers) {
                              _setState(() {
                                purchaserSelector = CrossFadeState.showFirst;
                                if (newMembers.isNotEmpty) {
                                  purchaserId = newMembers.first.memberId;
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
                          purchaserSelector == CrossFadeState.showSecond
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: purchaserSelector == CrossFadeState.showSecond
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                  ],
                );
              }
              return ErrorMessage(
                error: snapshot.error.toString(),
                locationOfError: 'add_purchase',
                callback: () {
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

  Center memberChooser(BuildContext context) => Center(
        child: FutureBuilder(
          future: members,
          builder: (context, AsyncSnapshot<List<Member>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                for (Member member in snapshot.data) {
                  if (!membersMap.containsKey(member)) {
                    membersMap[member] = false;
                  }
                }
                if (purchaseType == PurchaseType.fromShopping) {
                  membersMap[snapshot.data
                          .firstWhere((member) => member.memberId == shoppingRequest.requesterId)] =
                      true;
                } else if (purchaseType == PurchaseType.modifyPurchase && !alreadyInitializedSave) {
                  for (Member member in savedPurchase.receivers) {
                    Member memberInMap = membersMap.keys
                        .firstWhere((element) => element.memberId == member.memberId);
                    membersMap[memberInMap] = true;
                    if (member.isCustomAmount) {
                      customAmountMap[memberInMap] = member.balanceOriginalCurrency;
                    }
                  }
                  alreadyInitializedSave = true;
                }
                return MemberChips(
                  selectedCurrency: selectedCurrency,
                  allowMultiple: true,
                  allMembers: snapshot.data,
                  membersChosen: snapshot.data.where((member) => membersMap[member]).toList(),
                  customAmounts: customAmountMap,
                  membersChanged: (members) {
                    _setState(() {
                      for (Member member in snapshot.data) {
                        membersMap[member] = members.contains(member);
                      }
                    });
                  },
                  customAmountsChanged: (Map<Member, double> amounts) {
                    _setState(() {
                      customAmountMap = amounts;
                    });
                  },
                  showDivisionDialog: true,
                  getMaxAmount: () => double.tryParse(amountController.text) ?? 0.0,
                );
              } else {
                return ErrorMessage(
                  error: snapshot.error.toString(),
                  locationOfError: 'add_purchase',
                  callback: () {
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
