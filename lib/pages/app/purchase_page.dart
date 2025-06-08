import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/components/helpers/ad_unit.dart';
import 'package:csocsort_szamla/components/helpers/calculator.dart';
import 'package:csocsort_szamla/components/helpers/category_picker_icon_button.dart';
import 'package:csocsort_szamla/components/helpers/currency_picker_icon_button.dart';
import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/helpers/member_chips.dart';
import 'package:csocsort_szamla/components/purchase/custom_amount_field.dart';
import 'package:csocsort_szamla/components/purchase/purchaser_selection.dart';
import 'package:csocsort_szamla/helpers/amount_division.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_usage_provider.dart';
import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:csocsort_szamla/pages/app/receipt_scanner_page.dart';
import 'package:customized_keyboard/customized_keyboard.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class PurchasePage extends StatefulHookWidget {
  final ShoppingRequest? shoppingData;
  final Purchase? purchase;

  const PurchasePage({super.key, this.purchase, this.shoppingData});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  _PurchasePageState() : super();

  final _formKey = GlobalKey<FormState>();
  final ExpandableController _expandableController = ExpandableController();
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

  ReceiptInformation? receiptInformation;

  final calculatorKeyboard = CalculatorKeyboard();
  final calculatorFocusNode = FocusNode();

  Future<BoolFutureOutput> _postPurchase() async {
    try {
      Map<String, dynamic> body = {
        "name": noteController.text,
        "group": context.read<UserNotifier>().currentGroup!.id,
        "amount": amountDivision.totalAmount,
        "currency": selectedCurrency,
        "category": selectedCategory?.text,
        "buyer_id": purchaserId,
        "receivers": amountDivision.generateReceivers(useCustomAmounts),
      };
      if (widget.purchase != null) {
        await Http.put(uri: '/purchases/${widget.purchase!.id}', body: body);
      } else {
        await Http.post(uri: '/purchases', body: body);
      }
      context.read<UserUsageNotifier>().incrementExpenseCount();
      if (receiptInformation != null) {
        context.read<UserUsageNotifier>().incrementReceiptScannerCount();
        context.read<UserUsageNotifier>().setReceiptScannedFlag(true);
      }
      return BoolFutureOutput.True;
    } catch (_) {
      rethrow;
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
        members.add(Member(
            nickname: member['nickname'],
            balance: (member['balance'] * 1.0),
            username: member['username'],
            id: member['user_id']));
      }
      return members.sorted(
        (a, b) => a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase()),
      );
    } catch (_) {
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<UserNotifier>().user!;
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
      amountController.text =
          widget.purchase!.totalAmountOriginalCurrency.toMoneyString(widget.purchase!.originalCurrency);
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

    // This is necessary because the focus is not a state in itself, so PopScope will not update based on it
    calculatorFocusNode.addListener(() => setState(() {}));
  }

  void Function(ReceiptInformation) receiptInformationReady(
    AsyncSnapshot<List<Member>> membersSnapshot,
  ) =>
      (ReceiptInformation information) {
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
            membersSnapshot.data!,
            () => setState(() {}),
          );
          useCustomAmounts = true;
          receiptInformation = information;
        });
        Navigator.pop(context);
      };

  void onDeleteReceipt() => setState(() {
        receiptInformation = null;
        amountDivision = AmountDivision(
          amounts: [],
          currency: selectedCurrency,
          setState: () => setState(() {}),
        );
        noteController.text = "";
        amountController.text = "";
        selectedCurrency = context.read<UserNotifier>().user!.group!.currency;
        useCustomAmounts = false;
      });

  @override
  Widget build(BuildContext context) {
    final membersSnapshot = useFuture(members);

    return PopScope(
      canPop: !calculatorFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (calculatorFocusNode.hasFocus) {
          calculatorFocusNode.unfocus();
        }
      },
      child: KeyboardWrapper(
        keyboards: [calculatorKeyboard],
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
                            switch (membersSnapshot.hasData) {
                              false => Container(),
                              true => Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GradientButton.icon(
                                      icon: Icon(Icons.receipt),
                                      label: Text(
                                        'purchase.scan-receipt.${receiptInformation == null ? 'new' : 'modify'}'.tr(),
                                      ),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReceiptScannerPage(
                                            initialInformation: receiptInformation,
                                            members: membersSnapshot.data!,
                                            onReceiptInformationReady: receiptInformationReady(
                                              membersSnapshot,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (receiptInformation != null)
                                      Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: IconButton.outlined(
                                          onPressed: onDeleteReceipt,
                                          icon: Icon(Icons.delete),
                                        ),
                                      )
                                  ],
                                ),
                            },
                            SizedBox(height: 20),
                            Form(
                              key: _formKey,
                              child: Row(
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
                                  Padding(
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
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: CalculatorTextField(
                                    focusNode: calculatorFocusNode,
                                    controller: amountController,
                                    selectedCurrency: selectedCurrency,
                                    onChanged: (value) => setState(
                                      () => amountDivision.setTotal(value),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: CurrencyPickerIconButton(
                                    selectedCurrency: selectedCurrency,
                                    onCurrencyChanged: (newCurrency) => setState(() {
                                      selectedCurrency = newCurrency ?? selectedCurrency;
                                      amountDivision.setCurrency(selectedCurrency);
                                    }),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Center(
                                child: switch (membersSnapshot.connectionState) {
                              ConnectionState.done => switch (membersSnapshot.hasData) {
                                  false => ErrorMessage(
                                      error: membersSnapshot.error.toString(),
                                      errorLocation: 'add_purchase',
                                      onTap: () => setState(() => members = getMembers()),
                                    ),
                                  true => PurchaserSelection(
                                      members: membersSnapshot.data!,
                                      purchaserId: purchaserId,
                                      onPurchaserChanged: (newPurchaserId) => setState(() {
                                        purchaserId = newPurchaserId;
                                      }),
                                    ),
                                },
                              _ => CircularProgressIndicator(),
                            }),
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
                                    color: _expandableController.expanded
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
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
