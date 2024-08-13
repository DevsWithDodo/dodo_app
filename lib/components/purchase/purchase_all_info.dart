import 'package:csocsort_szamla/components/helpers/confirm_choice_dialog.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/helpers/transaction_receivers.dart';
import 'package:csocsort_szamla/components/purchase/modify_purchase_dialog.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PurchaseAllInfo extends StatefulWidget {
  final Purchase purchase;
  final int? selectedMemberId;

  PurchaseAllInfo(this.purchase, this.selectedMemberId);

  @override
  _PurchaseAllInfoState createState() => _PurchaseAllInfoState();
}

class _PurchaseAllInfoState extends State<PurchaseAllInfo> {
  late Currency displayCurrency;

  @override
  void initState() {
    super.initState();
    displayCurrency = widget.purchase.originalCurrency;
  }

  Future<BoolFutureOutput> _deleteElement(int id) async {
    try {
      await Http.delete(uri: '/purchases/' + id.toString());
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }

  @override
  Widget build(BuildContext context) {
    String note = '';
    if (widget.purchase.name == '') {
      note = 'no_note'.tr();
    } else {
      note = widget.purchase.name[0].toUpperCase() +
          widget.purchase.name.substring(1);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'purchase-info.title'.tr(namedArgs: {
                      'note': note,
                    }),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Visibility(
              visible: widget.purchase.category != null,
              child: Row(
                children: [
                  Text(
                    "${'purchase-info.category'.tr()} - ",
                    style: titleStyle,
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Text(
                        widget.purchase.category?.tr() ?? "",
                      ),
                    ),
                  ),
                  Icon(
                    widget.purchase.category?.icon,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
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
                    DateFormat.yMd(context.locale.languageCode).add_Hm().format(widget.purchase.updatedAt),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "${'purchase-info.total'.tr()} - ",
                  style: titleStyle,
                ),
                Flexible(
                  child: Text(
                    (displayCurrency == widget.purchase.originalCurrency
                            ? widget.purchase.totalAmountOriginalCurrency
                            : widget.purchase.totalAmount)
                        .toMoneyString(
                      displayCurrency,
                      withSymbol: true,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Visibility(
              visible: widget.purchase.originalCurrency != groupCurrency,
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
                              "currency": widget.purchase.originalCurrency.code
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
                                  : widget.purchase.originalCurrency;
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
            Builder(builder: (context) {
              Map<double, List<Member>> groupedReceivers = {};
              widget.purchase.receivers.forEach((receiver) {
                if (!groupedReceivers.containsKey(receiver.balance)) {
                  groupedReceivers[receiver.balance] = [];
                }
                groupedReceivers[receiver.balance]!.add(receiver);
              });
              return TransactionReceivers(
                type: TransactionType.purchase,
                groupedReceivers: groupedReceivers,
                buyerNickname: widget.purchase.buyerNickname,
                displayCurrency: displayCurrency,
              );
            }),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                GradientButton.icon(
                  onPressed: () {
                    showDialog(
                      builder: (context) => ModifyPurchaseDialog(
                        savedPurchase: widget.purchase,
                      ),
                      context: context,
                    ).then((value) {
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
                            context: context)
                        .then((value) {
                      if (value != null && value) {
                        showFutureOutputDialog(
                            context: context,
                            future: _deleteElement(widget.purchase.id),
                            outputCallbacks: {
                              BoolFutureOutput.True: () {
                                Navigator.pop(context);
                                Navigator.pop(context, 'deleted');
                              }
                            });
                      }
                    });
                  },
                  icon: Icon(Icons.delete),
                  label: Text('delete'.tr()),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}