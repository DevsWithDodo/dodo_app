import 'package:csocsort_szamla/components/helpers/add_reaction_dialog.dart';
import 'package:csocsort_szamla/components/helpers/confirm_choice_dialog.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/helpers/reaction_row.dart';
import 'package:csocsort_szamla/components/helpers/transaction_receivers.dart';
import 'package:csocsort_szamla/components/payment/modify_payment_dialog.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../helpers/models.dart';

class PaymentAllInfo extends StatefulWidget {
  final Payment payment;
  final Function(String reaction) onSendReaction;

  PaymentAllInfo(this.payment, this.onSendReaction);

  @override
  _PaymentAllInfoState createState() => _PaymentAllInfoState();
}

class _PaymentAllInfoState extends State<PaymentAllInfo> {
  late Currency displayCurrency;

  Future<BoolFutureOutput> _deletePayment(int id) async {
    try {
      await Http.delete(uri: '/payments/' + id.toString());
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }

  @override
  void initState() {
    super.initState();
    displayCurrency = widget.payment.originalCurrency;
  }

  @override
  Widget build(BuildContext context) {
    String note = '';
    if (widget.payment.note == '') {
      note = 'no_note'.tr();
    } else {
      note = widget.payment.note[0].toUpperCase() +
          widget.payment.note.substring(1);
    }

    TextStyle titleStyle = Theme.of(context).textTheme.titleMedium!.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    Currency groupCurrency = context.select<UserState, Currency>(
        (provider) => provider.currentGroup!.currency);

    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ReactionRow(
              type: ReactionType.payment,
              reactToId: widget.payment.id,
              onSendReaction: widget.onSendReaction,
              reactions: widget.payment.reactions!,
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                'payment-info.title'.tr(namedArgs: {
                  'note': note,
                }),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "${'info.date'.tr()} - ",
                  style: titleStyle,
                ),
                Flexible(
                  child: Text(
                    DateFormat.yMd(context.locale.languageCode).add_Hm().format(widget.payment.updatedAt),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Visibility(
              visible: widget.payment.originalCurrency != groupCurrency,
              child: Table(
                  columnWidths: {
                    0: FlexColumnWidth(1),
                    1: FixedColumnWidth(60),
                    2: FlexColumnWidth(1),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      children: [
                        Center(
                          child: Text(
                            'info.purchase-currency'.tr(namedArgs: {
                              "currency": widget.payment.originalCurrency.code
                            }),
                            style: titleStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Center(
                          child: Switch(
                            value: displayCurrency == groupCurrency,
                            onChanged: (value) => setState(() {
                              displayCurrency = value
                                  ? groupCurrency
                                  : widget.payment.originalCurrency;
                            }),
                          ),
                        ),
                        Center(
                          child: Text(
                            'info.group-currency'.tr(
                              namedArgs: {"currency": groupCurrency.code},
                            ),
                            style: titleStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ]),
            ),
            SizedBox(height: 15),
            Builder(
              builder: (context) {
                return TransactionReceivers(
                  type: TransactionType.payment,
                  buyerNickname: widget.payment.payerNickname,
                  groupedReceivers: {
                    widget.payment.amount: [
                      Member(
                        id: -1,
                        nickname: widget.payment.takerNickname,
                        username: widget.payment.takerUsername,
                        balance: widget.payment.amount,
                        balanceOriginalCurrency:
                            widget.payment.amountOriginalCurrency,
                      )
                    ]
                  },
                  displayCurrency: displayCurrency,
                );
              },
            ),
            SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GradientButton.icon(
                  onPressed: () {
                    showDialog(
                            builder: (context) => ModifyPaymentDialog(
                                  savedPayment: widget.payment,
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
                      if (value ?? false) {
                        showFutureOutputDialog(
                          context: context,
                          future: _deletePayment(widget.payment.id),
                          outputCallbacks: {
                            BoolFutureOutput.True: () {
                              Navigator.pop(context);
                              Navigator.pop(context, 'deleted');
                            }
                          },
                        );
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
      ),
    );
  }
}
