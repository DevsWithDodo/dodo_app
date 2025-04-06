import 'dart:convert';

import 'package:csocsort_szamla/components/helpers/ad_unit.dart';
import 'package:csocsort_szamla/components/helpers/currency_picker_icon_button.dart';
import 'package:csocsort_szamla/components/helpers/custom_choice_chip.dart';
import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/member_chips.dart';
import 'package:csocsort_szamla/components/payment/recommended_payments.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_usage_provider.dart';
import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class PaymentPage extends StatefulWidget {
  final Payment? payment;
  final bool fromNecessaryPayments;

  const PaymentPage({super.key, this.payment, this.fromNecessaryPayments = false});
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  int? selectedMemberId;
  TextEditingController amountController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  late Future<List<Member>> members;
  late Currency selectedCurrency;
  int? payerId;
  CrossFadeState purchaserSelector = CrossFadeState.showFirst;

  bool usesAutomaticSettleUp = false;

  Future<List<Member>> getMembers({bool overwriteCache = false}) async {
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
      rethrow;
    }
  }

  Future<BoolFutureOutput> _postPayment(double amount, String note) async {
    try {
      Map<String, dynamic> body = {
        'group': context.read<UserNotifier>().currentGroup!.id,
        'currency': selectedCurrency,
        'amount': amount,
        'note': note,
        'taker_id': selectedMemberId,
        'payer_id': payerId,
      };
      if (widget.payment != null) {
        await Http.put(uri: '/payments/${widget.payment!.id}', body: body);
      } else {
        await Http.post(uri: '/payments', body: body);
      }
      context.read<UserUsageNotifier>().incrementExpenseCount();
      context.read<UserUsageNotifier>().setUsedAutomaticSettleUpFlag(usesAutomaticSettleUp);
      return BoolFutureOutput.True;
    } catch (_) {
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();

    members = getMembers();
    selectedCurrency = context.read<UserNotifier>().currentGroup!.currency;
    payerId = context.read<UserNotifier>().user!.id;
    if (widget.payment != null) {
      amountController.text = widget.payment!.amount.toMoneyString(selectedCurrency);
      noteController.text = widget.payment!.note;
      selectedMemberId = widget.payment!.takerId;
      payerId = widget.payment!.payerId;
      selectedCurrency = widget.payment!.originalCurrency;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.payment == null ? 'payment' : 'payment.modify',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ).tr(),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              members = getMembers(overwriteCache: true);
            });
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Column(
              children: [
                if (widget.payment == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FutureBuilder(
                      future: members,
                      builder: (context, AsyncSnapshot<List<Member>> snapshot) {
                        if (snapshot.hasData) {
                          return RecommendedPayments(
                            payerId: payerId,
                            members: snapshot.data!,
                            autoSelectFirst: widget.fromNecessaryPayments,
                            onChange: (payment, selected) => setState(() {
                              usesAutomaticSettleUp = selected;
                              if (selected) {
                                amountController.text = payment.amount.toString();
                                selectedMemberId = snapshot.data!.firstWhere((member) => member.id == payment.takerId).id;
                              } else {
                                amountController.text = "";
                                selectedMemberId = null;
                              }
                            }),
                          );
                        }
                        return LinearProgressIndicator();
                      },
                    ),
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 500,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'note'.tr(),
                                  prefixIcon: Icon(
                                    Icons.note,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                inputFormatters: [LengthLimitingTextInputFormatter(50)],
                                controller: noteController,
                                onFieldSubmitted: (value) => submit(context),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(right: 5),
                                    child: CurrencyPickerIconButton(
                                      selectedCurrency: selectedCurrency,
                                      onCurrencyChanged: (newCurrency) => setState(() {
                                        selectedCurrency = newCurrency ?? selectedCurrency;
                                      }),
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
                                        labelText: 'amount'.tr(),
                                      ),
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9\\.\\,]'))],
                                      onFieldSubmitted: (value) => submit(context),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 20,
                              ),
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
                                                    chosenMemberIds: snapshot.data!.where((element) => element.id == payerId).map((e) => e.id).toList(),
                                                    setChosenMemberIds: (newMemberIds) => setState(() {
                                                      purchaserSelector = CrossFadeState.showFirst;
                                                      if (newMemberIds.isNotEmpty) {
                                                        payerId = newMemberIds.first;
                                                        if (selectedMemberId == payerId) {
                                                          selectedMemberId = null;
                                                        }
                                                      }
                                                    }),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                                onPressed: () => setState(() {
                                                      if (purchaserSelector == CrossFadeState.showFirst) {
                                                        purchaserSelector = CrossFadeState.showSecond;
                                                      } else {
                                                        purchaserSelector = CrossFadeState.showFirst;
                                                      }
                                                    }),
                                                icon: Icon(
                                                  purchaserSelector == CrossFadeState.showSecond ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                                  color: purchaserSelector == CrossFadeState.showSecond ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                                                )),
                                          ],
                                        );
                                      }
                                      return ErrorMessage(
                                        error: snapshot.error.toString(),
                                        errorLocation: 'add_payment',
                                        onTap: () => setState(() {
                                          members = getMembers();
                                        }),
                                      );
                                    }
                                    return CircularProgressIndicator();
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Text(
                                'to_who'.plural(1),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Center(
                                child: FutureBuilder(
                                  future: members,
                                  builder: (context, AsyncSnapshot<List<Member>> snapshot) {
                                    if (snapshot.connectionState == ConnectionState.done) {
                                      if (snapshot.hasData) {
                                        return MemberChips(
                                          multiple: false,
                                          allMembers: snapshot.data!.where((element) => element.id != payerId).toList(),
                                          setChosenMemberIds: (newMemberIds) {
                                            setState(() {
                                              selectedMemberId = newMemberIds.first;
                                            });
                                          },
                                          chosenMemberIds: selectedMemberId == null ? [] : [selectedMemberId!],
                                        );
                                      } else {
                                        return ErrorMessage(
                                          error: snapshot.error.toString(),
                                          errorLocation: 'add_payment',
                                          onTap: () {
                                            setState(() {
                                              members = getMembers();
                                            });
                                          },
                                        );
                                      }
                                    }

                                    return Center(child: CircularProgressIndicator());
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: MediaQuery.of(context).viewInsets.bottom == 0,
                  child: AdUnit(site: 'payment'),
                ),
              ],
            ),
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
    if (_formKey.currentState!.validate()) {
      if (selectedMemberId == null) {
        FToast ft = FToast();
        ft.init(context);
        ft.showToast(child: errorToast('person_not_chosen', context), toastDuration: Duration(seconds: 2), gravity: ToastGravity.BOTTOM);
        return;
      }
      double amount = double.parse(amountController.text.replaceAll(',', '.'));
      String note = noteController.text;
      showFutureOutputDialog(future: _postPayment(amount, note), context: context, outputCallbacks: {
        BoolFutureOutput.True: () {
          Navigator.pop(context);
          Navigator.pop(context, true); // True: Created/updated payment
          final bus = EventBus.instance;
          bus.fire(EventBus.refreshBalances);
          bus.fire(EventBus.refreshPayments);
        }
      });
    }
  }
}
