import 'package:csocsort_szamla/essentials/ad_unit.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/event_bus.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/payment/add_modify_payment.dart';
import 'package:csocsort_szamla/payment/recommended_payments.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddPaymentPage extends StatefulWidget {
  @override
  _AddPaymentPageState createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage>
    with AddModifyPayment {
  var _formKey = GlobalKey<FormState>();

  Future<BoolFutureOutput> _postPayment(
      double amount, String note, Member toMember, BuildContext context) async {
    try {
      Map<String, dynamic> body = generateBody(note, amount, toMember, context);

      await Http.post(uri: '/payments', body: body);
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FutureBuilder(
                      future: members,
                      builder: (context, AsyncSnapshot<List<Member>> snapshot) {
                        if (snapshot.hasData) {
                          return RecommendedPayments(
                            members: snapshot.data!,
                            onChange: (payment, selected) {
                              setState(() {
                                if (selected) {
                                  amountController.text =
                                      payment.amount.toString();
                                  selectedMember = snapshot.data!.firstWhere(
                                      (member) => member.id == payment.takerId);
                                } else {
                                  amountController.text = "";
                                  selectedMember = null;
                                }
                              });
                            },
                          );
                        }
                        return LinearProgressIndicator();
                      }),
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
                              warningText(context),
                              noteTextField(context),
                              SizedBox(
                                height: 20,
                              ),
                              amountTextField(context),
                              SizedBox(
                                height: 20,
                              ),
                              payerChooser(),
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
                  child: AdUnit(site: 'payment'),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          child:
              Icon(Icons.send, color: Theme.of(context).colorScheme.onTertiary),
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
      showFutureOutputDialog(
        future: _postPayment(amount, note, selectedMember!, context),
        context: context,
        outputCallbacks: {
          BoolFutureOutput.True: () {
            Navigator.pop(context);
            Navigator.pop(context);
            final bus = EventBus.instance;
            bus.fire(EventBus.refreshBalances);
            bus.fire(EventBus.refreshPayments);
          }
        }
      );
    }
  }
}
