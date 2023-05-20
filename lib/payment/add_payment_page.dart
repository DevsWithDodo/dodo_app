import 'package:csocsort_szamla/essentials/ad_management.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/payment/add_modify_payment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddPaymentRoute extends StatefulWidget {
  @override
  _AddPaymentRouteState createState() => _AddPaymentRouteState();
}

class _AddPaymentRouteState extends State<AddPaymentRoute> with AddModifyPayment {
  var _formKey = GlobalKey<FormState>();

  Future<bool> _postPayment(
      double amount, String note, Member toMember, BuildContext context) async {
    try {
      Map<String, dynamic> body = generateBody(note, amount, toMember);

      await httpPost(uri: '/payments', body: body, context: context);
      Future.delayed(delayTime()).then((value) => _onPostPayment(context));
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onPostPayment(BuildContext context) {
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    initAddModifyPayment(context, setState,
        paymentType: PaymentType.newPayment, buttonPush: _buttonPush);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'payment'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              members = getMembers(context, overwriteCache: true);
            });
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(context).unfocus();
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
                              warningText(),
                              noteTextField(context),
                              SizedBox(
                                height: 20,
                              ),
                              amountTextField(context),
                              SizedBox(
                                height: 20,
                              ),
                              payerChooser(context),
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
                              memberChooser(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: MediaQuery.of(context).viewInsets.bottom == 0,
                  child: AdUnitForSite(site: 'payment'),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          child: Icon(Icons.send, color: Theme.of(context).colorScheme.onTertiary),
          onPressed: () => _buttonPush(context),
        ),
      ),
    );
  }

  void _buttonPush(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      if (selectedMember == null) {
        FToast ft = FToast();
        ft.init(context);
        ft.showToast(
            child: errorToast('person_not_chosen', context),
            toastDuration: Duration(seconds: 2),
            gravity: ToastGravity.BOTTOM);
        return;
      }
      double amount = double.parse(amountController.text.replaceAll(',', '.'));
      String note = noteController.text;
      showDialog(
          builder: (context) => FutureSuccessDialog(
                future: _postPayment(amount, note, selectedMember!, context),
              ),
          barrierDismissible: false,
          context: context);
    }
  }
}
