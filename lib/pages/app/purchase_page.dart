import 'dart:async';
import 'dart:convert';

import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/components/helpers/ad_unit.dart';
import 'package:csocsort_szamla/components/helpers/calculator.dart';
import 'package:csocsort_szamla/components/helpers/category_picker_icon_button.dart';
import 'package:csocsort_szamla/components/helpers/currency_picker_icon_button.dart';
import 'package:csocsort_szamla/components/helpers/custom_choice_chip.dart';
import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/helpers/member_chips.dart';
import 'package:csocsort_szamla/components/purchase/custom_amount_field.dart';
import 'package:csocsort_szamla/helpers/amount_division.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:csocsort_szamla/pages/app/receipt_scanner_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class PurchasePage extends StatefulWidget {
  final ShoppingRequest? shoppingData;
  final Purchase? purchase;

  PurchasePage({this.purchase, this.shoppingData});

  @override
  _PurchasePageState createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  _PurchasePageState() : super();

  var _formKey = GlobalKey<FormState>();
  ExpandableController _expandableController = ExpandableController();
  bool useCustomAmounts = false;

  late Future<List<Member>> members;
  TextEditingController amountController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  late AmountDivision amountDivision;
  late Currency selectedCurrency;
  Category? selectedCategory;
  late int purchaserId;
  CrossFadeState purchaserCrossFadeState = CrossFadeState.showFirst;
  bool saveInitialized = false;

  GlobalKey _noteKey = GlobalKey();
  GlobalKey _currencyKey = GlobalKey();
  GlobalKey _calculatorKey = GlobalKey();

  ReceiptInformation? receiptInformation;

  Future<BoolFutureOutput> _postPurchase() async {
    try {
      Map<String, dynamic> body = {
        "name": noteController.text,
        "group": context.read<UserState>().currentGroup!.id,
        "amount": amountDivision.totalAmount,
        "currency": selectedCurrency,
        "category": selectedCategory != null ? selectedCategory!.text : null,
        "buyer_id": purchaserId,
        "receivers": amountDivision.generateReceivers(useCustomAmounts),
      };
      if (widget.purchase != null) {
        await Http.put(uri: '/purchases/${widget.purchase!.id}', body: body);
      } else {
        await Http.post(uri: '/purchases', body: body);
      }
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }

  Future<List<Member>> getMembers({bool overwriteCache = false}) async {
    try {
      Response response = await Http.get(
        uri: generateUri(GetUriKeys.groupCurrent, context),
        overwriteCache: overwriteCache,
      );

      Map<String, dynamic> decoded = jsonDecode(response.body);
      List<Member> members = [];
      for (var member in decoded['data']['members']) {
        members.add(Member(nickname: member['nickname'], balance: (member['balance'] * 1.0), username: member['username'], id: member['user_id']));
      }
      return members;
    } catch (_) {
      throw _;
    }
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<UserState>().user!;
    selectedCurrency = user.group!.currency;
    amountDivision = AmountDivision(
      amounts: [],
      currency: selectedCurrency,
      setState: () => setState(() {}),
    );
    members = getMembers();
    purchaserId = user.id;

    if (widget.purchase != null) {
      noteController.text = widget.purchase!.name;
      amountController.text = widget.purchase!.totalAmountOriginalCurrency.toMoneyString(widget.purchase!.originalCurrency);
      selectedCurrency = widget.purchase!.originalCurrency;
      selectedCategory = widget.purchase!.category;
      purchaserId = widget.purchase!.buyerId;
      amountDivision = AmountDivision.fromPurchase(widget.purchase!, () => setState(() {}));
      if (widget.purchase!.receivers.every((element) => element.balance == widget.purchase!.receivers.first.balance)) {
        useCustomAmounts = false;
      } else {
        useCustomAmounts = true;
      }
    } else if (widget.shoppingData != null) {
      noteController.text = widget.shoppingData!.name;
      amountDivision.addMember(
        widget.shoppingData!.requesterId,
        widget.shoppingData!.requesterNickname,
        false,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('showcase_add_purchase') && prefs.getBool('showcase_add_purchase')!) {
        return;
      }
      ShowCaseWidget.of(context).startShowCase([_noteKey, _currencyKey, _calculatorKey]);
      prefs.setBool('showcase_add_purchase', true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.purchase != null ? 'purchase.modify' : 'purchase',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ).tr(),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      constraints: BoxConstraints(maxWidth: 500),
                      child: Column(
                        children: <Widget>[
                          FutureBuilder(
                            future: members,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container();
                              }
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GradientButton.icon(
                                    icon: Icon(Icons.receipt),
                                    label: Text('purchase.scan-receipt.${receiptInformation == null ? 'new' : 'modify'}'.tr()),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReceiptScannerPage(
                                          initialInformation: receiptInformation,
                                          members: snapshot.data!,
                                          onReceiptInformationReady: (information) {
                                            setState(() {
                                              selectedCurrency = information.currency;
                                              noteController.text = information.storeName;
                                              amountController.text = information.items
                                                  .where(
                                                    (element) => element.assignedAmounts.isNotEmpty,
                                                  )
                                                  .map((e) => e.cost)
                                                  .fold(0.0, (previousValue, element) => previousValue + element)
                                                  .toMoneyString(selectedCurrency);
                                              amountDivision = AmountDivision.fromReceiptInformation(
                                                information,
                                                snapshot.data!,
                                                () => setState(() {}),
                                              );
                                              useCustomAmounts = true;
                                              receiptInformation = information;
                                            });
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (receiptInformation != null)
                                    Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: IconButton.outlined(
                                        onPressed: () => setState(() {
                                          receiptInformation = null;
                                          amountDivision = AmountDivision(
                                            amounts: [],
                                            currency: selectedCurrency,
                                            setState: () => setState(() {}),
                                          );
                                          noteController.text = "";
                                          amountController.text = "";
                                          selectedCurrency = context.read<UserState>().user!.group!.currency;
                                          useCustomAmounts = false;
                                        }),
                                        icon: Icon(Icons.delete),
                                      ),
                                    )
                                ],
                              );
                            },
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  validator: (value) => validateTextField([
                                    isEmpty(value),
                                  ]),
                                  decoration: InputDecoration(
                                    labelText: 'note'.tr(),
                                    prefixIcon: Icon(
                                      Icons.note,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  inputFormatters: [LengthLimitingTextInputFormatter(50)],
                                  controller: noteController,
                                  onFieldSubmitted: (value) => submit(context),
                                ),
                              ),
                              Showcase(
                                key: _noteKey,
                                showArrow: false,
                                targetBorderRadius: BorderRadius.circular(10),
                                targetPadding: EdgeInsets.all(0),
                                description: "pick_category".tr(),
                                child: Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: CategoryPickerIconButton(
                                    selectedCategory: selectedCategory,
                                    onCategoryChanged: (newCategory) {
                                      setState(() {
                                        if (selectedCategory?.type == newCategory?.type) {
                                          selectedCategory = null;
                                        } else {
                                          selectedCategory = newCategory;
                                        }
                                      });
                                    },
                                  ),
                                ),
                                scaleAnimationDuration: Duration(milliseconds: 200),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Showcase(
                                key: _currencyKey,
                                showArrow: false,
                                targetBorderRadius: BorderRadius.circular(10),
                                targetPadding: EdgeInsets.all(0),
                                description: "pick_currency".tr(),
                                child: Padding(
                                  padding: EdgeInsets.only(right: 5),
                                  child: CurrencyPickerIconButton(
                                    selectedCurrency: selectedCurrency,
                                    onCurrencyChanged: (newCurrency) => setState(() {
                                      selectedCurrency = newCurrency ?? selectedCurrency;
                                      amountDivision.setCurrency(selectedCurrency);
                                    }),
                                  ),
                                ),
                                scaleAnimationDuration: Duration(milliseconds: 200),
                              ),
                              Expanded(
                                child: TextFormField(
                                  validator: (value) => validateTextField([
                                    isEmpty(value),
                                    notValidNumber(value!.replaceAll(',', '.')),
                                  ]),
                                  decoration: InputDecoration(labelText: 'full_amount'.tr()),
                                  controller: amountController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9\\.\\,]'))],
                                  onFieldSubmitted: (value) => submit(context),
                                  onChanged: (value) => setState(() {
                                    double? parsedTotal = double.tryParse(value.replaceAll(',', '.'));
                                    if (parsedTotal != null && parsedTotal > 0) {
                                      amountDivision.setTotal(parsedTotal);
                                    }
                                  }),
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
                                              setState(() {
                                                double? value = double.tryParse(fromCalc);
                                                amountController.text = (value ?? 0.0).toMoneyString(
                                                  selectedCurrency,
                                                );
                                                if (value != null && value > 0) {
                                                  amountDivision.setTotal(value);
                                                }
                                              });
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  icon: Showcase(
                                    key: _calculatorKey,
                                    showArrow: false,
                                    targetBorderRadius: BorderRadius.circular(10),
                                    targetPadding: EdgeInsets.all(10),
                                    description: "use_calculator".tr(),
                                    child: Icon(Icons.calculate),
                                    scaleAnimationDuration: Duration(milliseconds: 200),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Center(
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
                                              crossFadeState: purchaserCrossFadeState,
                                              firstChild: Visibility(
                                                visible: purchaserCrossFadeState == CrossFadeState.showFirst,
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
                                                chosenMemberIds: snapshot.data!
                                                    .where(
                                                      (element) => element.id == purchaserId,
                                                    )
                                                    .map((e) => e.id)
                                                    .toList(),
                                                setChosenMemberIds: (newMemberIds) => setState(() {
                                                  purchaserCrossFadeState = CrossFadeState.showFirst;
                                                  if (newMemberIds.isNotEmpty) {
                                                    purchaserId = newMemberIds.first;
                                                  }
                                                }),
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => setState(() {
                                            if (purchaserCrossFadeState == CrossFadeState.showFirst) {
                                              purchaserCrossFadeState = CrossFadeState.showSecond;
                                            } else {
                                              purchaserCrossFadeState = CrossFadeState.showFirst;
                                            }
                                          }),
                                          icon: Icon(
                                            purchaserCrossFadeState == CrossFadeState.showSecond ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                            color: purchaserCrossFadeState == CrossFadeState.showSecond ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return ErrorMessage(
                                    error: snapshot.error.toString(),
                                    errorLocation: 'add_purchase',
                                    onTap: () => setState(() => members = getMembers()),
                                  );
                                }
                                return CircularProgressIndicator();
                              },
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'to_who'.plural(2),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              IconButton(
                                onPressed: () => setState(() {
                                  _expandableController.expanded = !_expandableController.expanded;
                                }),
                                icon: Icon(
                                  Icons.info_outline,
                                  color: _expandableController.expanded ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Expandable(
                            controller: _expandableController,
                            collapsed: Container(),
                            expanded: Center(
                              child: Column(
                                children: [
                                  Text(
                                    'add_purchase_explanation'.tr(),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          FutureBuilder(
                              future: members,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState != ConnectionState.done) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}'));
                                }
                                return MemberChips(
                                  multiple: true,
                                  allMembers: snapshot.data!,
                                  chosenMemberIds: amountDivision.memberIds,
                                  setChosenMemberIds: (memberIds) => setState(
                                    () => amountDivision.setMembers(
                                      snapshot.data!.where((element) => memberIds.contains(element.id)).toList(),
                                    ),
                                  ),
                                  allowCustomAmounts: true,
                                  fullAmount: amountDivision.totalAmount,
                                  customAmounts: useCustomAmounts
                                      ? Map.fromEntries(amountDivision.amounts.map(
                                          (e) => MapEntry(
                                            e.memberId,
                                            e.parsedAmount ?? 0,
                                          ),
                                        ))
                                      : {},
                                );
                              }),
                          SizedBox(height: 10),
                          if (!useCustomAmounts && amountDivision.amounts.isNotEmpty)
                            Center(
                              child: Text(
                                'per_person'.tr(
                                  args: [
                                    (amountDivision.totalAmount / amountDivision.amounts.length).toMoneyString(
                                      selectedCurrency,
                                      withSymbol: true,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'purchase.page.custom-amount.switch'.tr(),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              Switch(
                                value: useCustomAmounts,
                                onChanged: (value) {
                                  double? totalAmount = double.tryParse(amountController.text.replaceAll(',', '.'));
                                  if (totalAmount == null || totalAmount <= 0) {
                                    showToast('purchase.page.custom-amount.toast.no-amount-given'.tr());
                                    setState(() => useCustomAmounts = false);
                                    return;
                                  }
                                  setState(() => useCustomAmounts = value);
                                },
                              ),
                            ],
                          ),
                          if (useCustomAmounts)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 10, bottom: 20),
                                child: Text(
                                  'purchase.page.custom-amount.hint'.tr(),
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ),
                          AnimatedCrossFade(
                            crossFadeState: !useCustomAmounts ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                            duration: Duration(milliseconds: 300),
                            firstChild: Container(),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: amountDivision.amounts.map((PurchaseReceiver amount) {
                                return CustomAmountField(
                                  amount: amount,
                                  currency: selectedCurrency,
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: MediaQuery.of(context).viewInsets.bottom == 0,
                child: AdUnit(site: 'purchase'),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          child: Icon(Icons.send, color: Theme.of(context).colorScheme.onTertiary),
          onPressed: () => submit(context),
        ),
      ),
    );
  }

  void submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate() && (!useCustomAmounts || amountDivision.isValid(true))) {
      if (amountDivision.amounts.isEmpty) {
        FToast ft = FToast();
        ft.init(context);
        ft.showToast(
          child: errorToast('person_not_chosen', context),
          toastDuration: Duration(seconds: 2),
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }
      showFutureOutputDialog(
        context: context,
        future: _postPurchase(),
        outputCallbacks: {
          BoolFutureOutput.True: () {
            Navigator.pop(context);
            Navigator.pop(context, true); // True: Created/modified purchase
            final bus = EventBus.instance;
            bus.fire(EventBus.refreshBalances);
            bus.fire(EventBus.refreshPurchases);
          }
        },
      );
    }
  }
}
