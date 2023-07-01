import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/purchase/add_modify_purchase.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ModifyPurchaseDialog extends StatefulWidget {
  final Purchase? savedPurchase;
  ModifyPurchaseDialog({required this.savedPurchase});
  @override
  _ModifyPurchaseDialogState createState() => _ModifyPurchaseDialogState();
}

class _ModifyPurchaseDialogState extends State<ModifyPurchaseDialog>
    with AddModifyPurchase {
  var _formKey = GlobalKey<FormState>();

  int _index = 0;

  Future<bool> _updatePurchase(List<Member> members, double amount, String name,
      int? purchaseId, BuildContext context) async {
    try {
      Map<String, dynamic> body = generateBody(name, amount, members, context);

      await Http.put(
        uri: '/purchases/' + purchaseId.toString(),
        body: body,
      );
      Future.delayed(delayTime()).then((value) => _onUpdatePurchase());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onUpdatePurchase() {
    Navigator.pop(context);
    Navigator.pop(context, true);
  }

  @override
  void initState() {
    super.initState();
    initAddModifyPurchase(
      context,
      setState,
      purchaseType: PurchaseType.modifyPurchase,
      savedPurchase: widget.savedPurchase,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                  child: Text(
                'modify_purchase'.tr(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              )),
              SizedBox(
                height: 10,
              ),
              Center(
                  child: Text(
                'modify_purchase_explanation'.tr(),
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              )),
              SizedBox(
                height: 20,
              ),
              Visibility(
                visible: _index == 0,
                child: noteTextField(context),
              ),
              Visibility(
                visible: _index == 1,
                child: amountTextField(context),
              ),
              Visibility(
                visible: _index == 2,
                child: purchaserChooser(),
              ),
              Visibility(
                visible: _index == 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'to_who'.plural(2),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    SizedBox(width: 10),
                    Expanded(child: receiverChooser()),
                  ],
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Visibility(
                    visible: _index != 0,
                    child: GradientButton(
                      onPressed: () {
                        setState(() {
                          _index--;
                        });
                      },
                      child: Icon(Icons.navigate_before),
                    ),
                  ),
                  GradientButton(
                    onPressed: () {
                      if (_index != 3) {
                        if (_formKey.currentState!.validate()) {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _index++;
                          });
                        }
                      } else {
                        if (_formKey.currentState!.validate()) {
                          FocusScope.of(context).unfocus();
                          if (!membersMap.containsValue(true)) {
                            FToast ft = FToast();
                            ft.init(context);
                            ft.showToast(
                                child: errorToast('person_not_chosen', context),
                                toastDuration: Duration(seconds: 2),
                                gravity: ToastGravity.BOTTOM);
                            return;
                          }
                          double amount = double.parse(
                              amountController.text.replaceAll(',', '.'));
                          String name = noteController.text;
                          List<Member> members = <Member>[];
                          membersMap.forEach((Member key, bool value) {
                            if (value) members.add(key);
                          });
                          showDialog(
                              builder: (context) => FutureSuccessDialog(
                                    future: _updatePurchase(
                                        members,
                                        amount,
                                        name,
                                        widget.savedPurchase!.id,
                                        context),
                                  ),
                              context: context);
                        }
                      }
                    },
                    child:
                        Icon(_index == 3 ? Icons.check : Icons.navigate_next),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
