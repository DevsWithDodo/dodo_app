import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/payment/add_modify_payment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ModifyPaymentDialog extends StatefulWidget {
  final Payment? savedPayment;
  ModifyPaymentDialog({required this.savedPayment});
  @override
  _ModifyPaymentDialogState createState() => _ModifyPaymentDialogState();
}

class _ModifyPaymentDialogState extends State<ModifyPaymentDialog>
    with AddModifyPayment {
  var _formKey = GlobalKey<FormState>();

  int _index = 0;

  Future<bool> _updatePayment(
      double amount, String note, Member toMember, int? paymentId) async {
    try {
      Map<String, dynamic> body = generateBody(note, amount, toMember);

      await httpPut(
          uri: '/payments/' + paymentId.toString(),
          body: body,
          context: context);
      Future.delayed(delayTime()).then((value) => _onUpdatePayment());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onUpdatePayment() {
    Navigator.pop(context);
    Navigator.pop(context, true);
  }

  @override
  void initState() {
    super.initState();
    initAddModifyPayment(context, setState,
        paymentType: PaymentType.modifyPayment,
        savedPayment: widget.savedPayment);
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
                'modify_payment'.tr(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              )),
              SizedBox(
                height: 15,
              ),
              Center(
                  child: Text(
                'modify_payment_explanation'.tr(),
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              )),
              SizedBox(
                height: 10,
              ),
              warningText(),
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
                child: payerChooser(context),
              ),
              Visibility(
                visible: _index == 3,
                child: Row(
                  children: [
                    Text(
                      'to_who'.plural(1),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    SizedBox(width: 10),
                    Expanded(child: memberChooser(context)),
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
                          if (selectedMember == null) {
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
                          String note = noteController.text;
                          showDialog(
                              builder: (context) => FutureSuccessDialog(
                                    future: _updatePayment(
                                        amount,
                                        note,
                                        selectedMember!,
                                        widget.savedPayment!.id),
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
