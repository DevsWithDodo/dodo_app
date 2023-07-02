import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/confirm_choice_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/payment/modify_payment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:provider/provider.dart';

import '../essentials/models.dart';

class PaymentAllInfo extends StatefulWidget {
  final Payment? data;

  PaymentAllInfo(this.data);

  @override
  _PaymentAllInfoState createState() => _PaymentAllInfoState();
}

class _PaymentAllInfoState extends State<PaymentAllInfo> {
  Future<bool> _deletePayment(int? id) async {
    try {
      await Http.delete(uri: '/payments/' + id.toString());
      Future.delayed(delayTime()).then((value) => _onDeletePayment());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onDeletePayment() {
    Navigator.pop(context);
    Navigator.pop(context, 'deleted');
  }

  @override
  Widget build(BuildContext context) {
    String note = '';
    if (widget.data!.note == '') {
      note = 'no_note'.tr();
    } else {
      note =
          widget.data!.note[0].toUpperCase() + widget.data!.note.substring(1);
    }
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.note, color: Theme.of(context).colorScheme.secondary),
              Flexible(
                  child: Text(
                ' - ' + note,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
              )),
            ],
          ),
          SizedBox(
            height: 5,
          ),
          Row(
            children: <Widget>[
              Icon(Icons.account_circle,
                  color: Theme.of(context).colorScheme.secondary),
              Flexible(
                  child: Text(
                ' - ' + widget.data!.payerNickname,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
              )),
            ],
          ),
          SizedBox(
            height: 5,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.account_box,
                  color: Theme.of(context).colorScheme.secondary),
              Flexible(
                  child: Text(
                ' - ' + widget.data!.takerNickname,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
              )),
            ],
          ),
          SizedBox(
            height: 5,
          ),
          Row(
            children: <Widget>[
              Icon(Icons.attach_money,
                  color: Theme.of(context).colorScheme.secondary),
              Flexible(
                  child: Selector<AppStateProvider, String>(
                    selector: (context, userProvider) => userProvider.currentGroup!.currency,
                    builder: (context, currentGroupCurrency, _) {
                      return Text(
                          ' - ' +
                              widget.data!.amount.toMoneyString(
                                  currentGroupCurrency,
                                  withSymbol: true) +
                              (widget.data!.originalCurrency != currentGroupCurrency
                                  ? (' (' +
                                      widget.data!.amountOriginalCurrency
                                          .toMoneyString(
                                              widget.data!.originalCurrency,
                                              withSymbol: true) +
                                      ')')
                                  : ''),
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface));
                    }
                  )),
            ],
          ),
          SizedBox(
            height: 5,
          ),
          Row(
            children: <Widget>[
              Icon(
                Icons.date_range,
                color: Theme.of(context).colorScheme.secondary,
              ),
              Flexible(
                  child: Text(
                      ' - ' +
                          DateFormat('yyyy/MM/dd - HH:mm')
                              .format(widget.data!.updatedAt),
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface))),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              GradientButton.icon(
                onPressed: () {
                  showDialog(
                          builder: (context) => ModifyPaymentDialog(
                                savedPayment: widget.data,
                              ),
                          context: context)
                      .then((value) {
                    if (value ?? false) {
                      Navigator.pop(context, 'deleted');
                    }
                  });
                },
                icon: Icon(Icons.edit),
                label: Text('modify'.tr()),
              ),
              GradientButton.icon(
                onPressed: () {
                  showDialog(
                    builder: (context) => ConfirmChoiceDialog(
                      choice: 'want_delete',
                    ),
                    context: context,
                  ).then((value) {
                    if (value != null && value) {
                      showDialog(
                          builder: (context) => FutureSuccessDialog(
                                future: _deletePayment(widget.data!.id),
                              ),
                          barrierDismissible: false,
                          context: context);
                    }
                  });
                },
                icon: Icon(Icons.delete),
                label: Text('delete'.tr()),
              )
            ],
          ),
        ],
      ),
    );
  }
}
