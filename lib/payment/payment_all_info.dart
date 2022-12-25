import 'package:csocsort_szamla/essentials/widgets/confirm_choice_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/payment/add_payment_page.dart';
import 'package:csocsort_szamla/payment/modify_payment_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:csocsort_szamla/payment/payment_entry.dart';
import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/currencies.dart';

class PaymentAllInfo extends StatefulWidget {
  final PaymentData data;

  PaymentAllInfo(this.data);

  @override
  _PaymentAllInfoState createState() => _PaymentAllInfoState();
}

class _PaymentAllInfoState extends State<PaymentAllInfo> {
  Future<bool> _deletePayment(int id) async {
    try {
      bool useGuest = guestNickname != null && guestGroupId == currentGroupId;
      await httpDelete(uri: '/payments/' + id.toString(), context: context, useGuest: useGuest);
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
    if (widget.data.note == '' || widget.data.note == null) {
      note = 'no_note'.tr();
    } else {
      note = widget.data.note[0].toUpperCase() + widget.data.note.substring(1);
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
                    .bodyLarge
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
              )),
            ],
          ),
          SizedBox(
            height: 5,
          ),
          Row(
            children: <Widget>[
              Icon(Icons.account_circle, color: Theme.of(context).colorScheme.secondary),
              Flexible(
                  child: Text(
                ' - ' + widget.data.payerNickname,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
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
              Icon(Icons.account_box, color: Theme.of(context).colorScheme.secondary),
              Flexible(
                  child: Text(
                ' - ' + widget.data.takerNickname,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
              )),
            ],
          ),
          SizedBox(
            height: 5,
          ),
          Row(
            children: <Widget>[
              Icon(Icons.attach_money, color: Theme.of(context).colorScheme.secondary),
              Flexible(
                  child: Text(
                      ' - ' +
                          widget.data.amount.toMoneyString(currentGroupCurrency, withSymbol: true),
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          .copyWith(color: Theme.of(context).colorScheme.onSurface))),
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
                      ' - ' + DateFormat('yyyy/MM/dd - HH:mm').format(widget.data.updatedAt),
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          .copyWith(color: Theme.of(context).colorScheme.onSurface))),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Visibility(
            visible: widget.data.payerId == idToUse(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                GradientButton(
                    onPressed: () {
                      showDialog(
                              builder: (context) => ModifyPaymentDialog(
                                    savedPayment: SavedPayment(
                                        amount: widget.data.amount,
                                        note: widget.data.note,
                                        payerId: widget.data.payerId,
                                        takerId: widget.data.takerId,
                                        paymentId: widget.data.paymentId),
                                  ),
                              context: context)
                          .then((value) {
                        if (value ?? false) {
                          Navigator.pop(context, 'deleted');
                        }
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: Theme.of(context).colorScheme.onPrimary),
                        SizedBox(
                          width: 3,
                        ),
                        Flexible(
                          child: Text(
                            'modify'.tr(),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                .copyWith(color: Theme.of(context).colorScheme.onPrimary),
                            overflow: TextOverflow.clip,
                          ),
                        ),
                      ],
                    )),
                GradientButton(
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
                                  future: _deletePayment(widget.data.paymentId),
                                  dataTrueText: 'delete_scf',
                                  onDataTrue: () {
                                    _onDeletePayment();
                                  },
                                ),
                            barrierDismissible: false,
                            context: context);
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Theme.of(context).colorScheme.onPrimary),
                      SizedBox(
                        width: 3,
                      ),
                      Text(
                        'revoke'.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            .copyWith(color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
