import 'dart:convert';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/providers/app_state_provider.dart';
import 'package:csocsort_szamla/components/helpers/custom_choice_chip.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import '../../helpers/http.dart';
import '../../helpers/models.dart';
import '../../helpers/validation_rules.dart';
import '../helpers/calculator.dart';
import '../helpers/currency_picker_icon_button.dart';
import '../helpers/error_message.dart';
import '../helpers/member_chips.dart';

enum PaymentType { newPayment, modifyPayment }

mixin AddModifyPayment {
  Member? selectedMember;
  TextEditingController amountController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  Future<List<Member>>? members;
  late String selectedCurrency;
  late Function(BuildContext context) _buttonPush;
  late void Function(void Function()) _setState;
  PaymentType? _paymentType;
  Payment? _savedPayment;
  bool _alreadyInitializedSave = false;
  int? payerId;
  CrossFadeState purchaserSelector = CrossFadeState.showFirst;
  late User user;

  void initAddModifyPayment(
    BuildContext context,
    void Function(void Function()) setState, {
    void Function(BuildContext context)? buttonPush,
    PaymentType? paymentType,
    Payment? savedPayment,
  }) {
    assert(
        (paymentType == PaymentType.newPayment) || (paymentType == PaymentType.modifyPayment && savedPayment != null));
    this._setState = setState;
    this._paymentType = paymentType;
    this._buttonPush = buttonPush ?? (context) {};
    this.user = context.read<AppStateProvider>().user!;
    this.selectedCurrency = context.read<AppStateProvider>().currentGroup!.currency;
    if (_paymentType == PaymentType.modifyPayment) {
      this._savedPayment = savedPayment;
      selectedCurrency = savedPayment!.originalCurrency;
      noteController.text = savedPayment.note;
      amountController.text = savedPayment.amountOriginalCurrency.toMoneyString(savedPayment.originalCurrency);
      payerId = savedPayment.payerId;
    }
    members = getMembers(context);
    payerId = payerId ?? user.id;
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
        members.add(Member.fromJson(member));
      }
      return members;
    } catch (_) {
      throw _;
    }
  }

  Map<String, dynamic> generateBody(String note, double amount, Member toMember, BuildContext context) {
    return {
      'group': context.read<AppStateProvider>().currentGroup!.id,
      'currency': selectedCurrency,
      'amount': amount,
      'note': note,
      'taker_id': toMember.id,
      'payer_id': payerId,
    };
  }

  TextFormField noteTextField(BuildContext context) => TextFormField(
        decoration: InputDecoration(
          hintText: 'note'.tr(),
          prefixIcon: Icon(
            Icons.note,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        inputFormatters: [LengthLimitingTextInputFormatter(50)],
        controller: noteController,
        onFieldSubmitted: (value) => _buttonPush(context),
      );

  Widget amountTextField(BuildContext context) => Row(
        children: [
          Padding(
            padding: EdgeInsets.only(right: 5),
            child: CurrencyPickerIconButton(
              selectedCurrency: selectedCurrency,
              onCurrencyChanged: (newCurrency) {
                _setState(() {
                  selectedCurrency = newCurrency ?? selectedCurrency;
                });
              },
            ),
          ),
          Expanded(
            child: TextFormField(
              validator: (value) => validateTextField([
                isEmpty(value!.trim()),
                notValidNumber(value.replaceAll(',', '.')),
              ]),
              controller: amountController,
              decoration: InputDecoration(
                hintText: 'amount'.tr(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9\\.\\,]'))],
              onFieldSubmitted: (value) => _buttonPush(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: IconButton.filledTonal(
              isSelected: false,
              icon: Icon(
                Icons.calculate,
              ),
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
                            amountController.text = fromCalc;
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );

  Center payerChooser() => Center(
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
                              member: snapshot.data!.firstWhere((element) => element.id == payerId),
                              onSelected: (chosen) {},
                            ),
                          ),
                          secondChild: MemberChips(
                            allMembers: snapshot.data!,
                            multiple: false,
                            showAnimation: false,
                            chosenMembers: snapshot.data!.where((element) => element.id == payerId).toList(),
                            setChosenMembers: (newMembers) {
                              _setState(() {
                                purchaserSelector = CrossFadeState.showFirst;
                                if (newMembers.isNotEmpty) {
                                  payerId = newMembers.first.id;
                                  if (selectedMember != null && selectedMember!.id == payerId) {
                                    selectedMember = null;
                                  }
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
                errorLocation: 'add_payment',
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

  Center memberChooser(BuildContext context) => Center(
        child: FutureBuilder(
          future: members,
          builder: (context, AsyncSnapshot<List<Member>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                if (_savedPayment != null && !_alreadyInitializedSave) {
                  Member? selectedMember =
                      snapshot.data!.firstWhereOrNull((element) => element.id == _savedPayment!.takerId);
                  if (selectedMember != null) this.selectedMember = selectedMember;
                  _alreadyInitializedSave = true;
                }
                return MemberChips(
                  multiple: false,
                  allMembers: snapshot.data!.where((element) => element.id != payerId).toList(),
                  setChosenMembers: (members) {
                    _setState(() {
                      selectedMember = members.isEmpty ? null : members[0];
                    });
                  },
                  chosenMembers: selectedMember == null ? [] : [selectedMember!],
                );
              } else {
                return ErrorMessage(
                  error: snapshot.error.toString(),
                  errorLocation: 'add_payment',
                  onTap: () {
                    _setState(() {
                      members = null;
                      members = getMembers(context);
                    });
                  },
                );
              }
            }

            return Center(child: CircularProgressIndicator());
          },
        ),
      );
}
