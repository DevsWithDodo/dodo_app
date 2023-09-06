import 'package:csocsort_szamla/essentials/ad_unit.dart';
import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/event_bus.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/purchase/add_modify_purchase.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class AddPurchasePage extends StatefulWidget {
  final PurchaseType type;
  final ShoppingRequest? shoppingData;

  AddPurchasePage({required this.type, this.shoppingData});

  @override
  _AddPurchasePageState createState() => _AddPurchasePageState();
}

class _AddPurchasePageState extends State<AddPurchasePage> with AddModifyPurchase {
  _AddPurchasePageState() : super();

  var _formKey = GlobalKey<FormState>();
  ExpandableController _expandableController = ExpandableController();

  GlobalKey _noteKey = GlobalKey();
  GlobalKey _currencyKey = GlobalKey();
  GlobalKey _calculatorKey = GlobalKey();
  GlobalKey _receiversKey = GlobalKey();

  Future<BoolFutureOutput> _postPurchase(List<Member> members, double amount, String name, BuildContext context) async {
    try {
      Map<String, dynamic> body = generateBody(name, amount, members, context);

      await Http.post(uri: '/purchases', body: body);
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }

  @override
  void initState() {
    super.initState();
    initAddModifyPurchase(
      context,
      setState,
      buttonPush: _buttonPush,
      purchaseType: widget.type,
      shoppingRequest: widget.shoppingData,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('showcase_add_purchase') && prefs.getBool('showcase_add_purchase')!) {
        return;
      }
      ShowCaseWidget.of(context).startShowCase([_noteKey, _currencyKey, _calculatorKey, _receiversKey]);
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
            'purchase'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: RefreshIndicator(
            onRefresh: () async {
              members = null;
              members = getMembers(context, overwriteCache: true);
            },
            child: Column(
              children: [
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
                              noteTextField(context, showcaseKey: _noteKey),
                              SizedBox(height: 20),
                              amountTextField(context, calculatorKey: _calculatorKey, currencyKey: _currencyKey),
                              SizedBox(height: 20),
                              purchaserChooser(),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'to_who'.plural(2),
                                    style: Theme.of(context).textTheme.labelLarge,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _expandableController.expanded = !_expandableController.expanded;
                                      });
                                    },
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
                              Center(
                                child: Text(
                                  'purchase.page.custom-amount-hint'.tr(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                ),
                              ),
                              SizedBox(height: 15),
                              receiverChooser(showcaseKey: _receiversKey),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      setState(() {
                                        for (Member member in membersMap.keys) {
                                          membersMap[member] = !membersMap[member]!;
                                          customAmountMap[member] = 0;
                                        }
                                      });
                                    },
                                    icon: Icon(
                                      Icons.swap_horiz,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Visibility(
                                    visible: amountController.text != "" && membersMap.containsValue(true),
                                    child: Column(
                                      children: [
                                        Text(
                                          'per_person'.tr(args: [
                                            amountForNonCustom().toMoneyString(selectedCurrency, withSymbol: true)
                                          ]),
                                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                                color: Theme.of(context).colorScheme.tertiary,
                                              ),
                                        ),
                                        ...(customAmountMap.keys.map<Widget>((member) {
                                          return Text(
                                            member.nickname +
                                                ': ' +
                                                customAmountMap[member]
                                                    .toMoneyString(selectedCurrency, withSymbol: true),
                                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                                  color: Theme.of(context).colorScheme.tertiary,
                                                ),
                                          );
                                        }).toList())
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      setState(() {
                                        for (Member member in membersMap.keys) {
                                          membersMap[member] = false;
                                          customAmountMap[member] = 0;
                                        }
                                      });
                                    },
                                    icon: Icon(
                                      Icons.delete,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
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
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          child: Icon(Icons.send, color: Theme.of(context).colorScheme.onTertiary),
          onPressed: () => buttonPush(context),
        ),
      ),
    );
  }

  void _buttonPush(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      if (!membersMap.containsValue(true)) {
        FToast ft = FToast();
        ft.init(context);
        ft.showToast(
            child: errorToast('person_not_chosen', context),
            toastDuration: Duration(seconds: 2),
            gravity: ToastGravity.BOTTOM);
        return;
      }
      double amount = double.parse(amountController.text.replaceAll(',', '.'));
      String name = noteController.text;
      List<Member> members = [];
      membersMap.forEach((Member key, bool value) {
        if (value) members.add(key);
      });
      showFutureOutputDialog(
        context: context,
        future: _postPurchase(members, amount, name, context),
        outputCallbacks: {
          BoolFutureOutput.True: () {
            Navigator.pop(context);
            Navigator.pop(context);
            final bus = EventBus.instance;
            bus.fire(EventBus.refreshBalances);
            bus.fire(EventBus.refreshPurchases);
          }
        },
      );
    }
  }
}
