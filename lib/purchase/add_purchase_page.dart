import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/ad_management.dart';
import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/purchase/add_modify_purchase.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../shopping/shopping_list_entry.dart';

class AddPurchaseRoute extends StatefulWidget {
  final PurchaseType type;
  final ShoppingRequestData shoppingData;

  AddPurchaseRoute({@required this.type, this.shoppingData});

  @override
  _AddPurchaseRouteState createState() => _AddPurchaseRouteState();
}

class _AddPurchaseRouteState extends State<AddPurchaseRoute> with AddModifyPurchase {
  _AddPurchaseRouteState() : super();

  var _formKey = GlobalKey<FormState>();
  ExpandableController _expandableController = ExpandableController();

  Future<bool> _postPurchase(
      List<Member> members, double amount, String name, BuildContext context) async {
    bool useGuest = guestNickname != null && guestGroupId == currentGroupId;
    try {
      Map<String, dynamic> body = generateBody(name, amount, members);

      await httpPost(uri: '/purchases', body: body, context: context, useGuest: useGuest);
      Future.delayed(delayTime()).then((value) => _onPostPurchase(context));
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onPostPurchase(BuildContext context) {
    Navigator.pop(context);
    Navigator.pop(context);
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
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: RefreshIndicator(
            onRefresh: () async {
              members = null;
              members = getMembers(context, overwriteCache: true);
            },
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              noteTextField(context),
                              SizedBox(
                                height: 12,
                              ),
                              // Center(
                              //   child: Text(
                              //     'amount_textbox_hint'.tr(),
                              //     textAlign: TextAlign.center,
                              //     style: Theme.of(context)
                              //         .textTheme
                              //         .bodySmall
                              //         .copyWith(color: Theme.of(context).colorScheme.onSurface),
                              //   ),
                              // ),
                              SizedBox(
                                height: 8,
                              ),
                              amountTextField(context),
                              SizedBox(
                                height: 20,
                              ),
                              purchaserChooser(context),
                              SizedBox(
                                height: 10,
                              ),
                              Divider(),
                              SizedBox(
                                height: 10,
                              ),
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
                                        _expandableController.expanded =
                                            !_expandableController.expanded;
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
                              SizedBox(
                                height: 5,
                              ),
                              Expandable(
                                controller: _expandableController,
                                collapsed: Container(),
                                expanded: Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        'add_purchase_explanation'.tr(),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.bodySmall.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'custom_amount_hint'.tr(),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.bodySmall.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              memberChooser(context),
                              SizedBox(
                                height: 20,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      setState(() {
                                        for (Member member in membersMap.keys) {
                                          membersMap[member] = !membersMap[member];
                                        }
                                      });
                                    },
                                    icon: Icon(
                                      Icons.swap_horiz,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Visibility(
                                    visible: amountController.text != "" &&
                                        membersMap.containsValue(true),
                                    child: Center(
                                      child: Text(
                                          'per_person'.tr(args: [
                                            amountForNonCustom()
                                                .toMoneyString(selectedCurrency, withSymbol: true)
                                          ]),
                                          style: Theme.of(context).textTheme.bodySmall.copyWith(
                                                color: Theme.of(context).colorScheme.tertiary,
                                              )),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      setState(() {
                                        for (Member member in membersMap.keys) {
                                          membersMap[member] = false;
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
                    ],
                  ),
                ),
                Visibility(
                  visible: MediaQuery.of(context).viewInsets.bottom == 0,
                  child: AdUnitForSite(site: 'purchase'),
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
    if (_formKey.currentState.validate()) {
      if (!membersMap.containsValue(true)) {
        FToast ft = FToast();
        ft.init(context);
        ft.showToast(
            child: errorToast('person_not_chosen', context),
            toastDuration: Duration(seconds: 2),
            gravity: ToastGravity.BOTTOM);
        return;
      }
      double amount = double.parse(amountController.text);
      String name = noteController.text;
      List<Member> members = [];
      membersMap.forEach((Member key, bool value) {
        if (value) members.add(key);
      });
      showDialog(
          builder: (context) => FutureSuccessDialog(
                future: _postPurchase(members, amount, name, context),
              ),
          barrierDismissible: false,
          context: context);
    }
  }
}
