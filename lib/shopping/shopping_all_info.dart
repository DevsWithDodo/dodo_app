import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:csocsort_szamla/shopping/shopping_list.dart';
import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/transaction/add_transaction_page.dart';
import 'package:csocsort_szamla/future_success_dialog.dart';
import 'package:csocsort_szamla/http_handler.dart';

class ShoppingAllInfo extends StatefulWidget {
  final ShoppingRequestData data;

  ShoppingAllInfo(this.data);

  @override
  _ShoppingAllInfoState createState() => _ShoppingAllInfoState();
}

class _ShoppingAllInfoState extends State<ShoppingAllInfo> {
  Future<bool> _fulfillShoppingRequest(int id) async {
    try {
      await httpPut(uri: '/requests/' + id.toString(), context: context, body: {});
      return true;

    } catch (_) {
      throw _;
    }
  }

  Future<bool> _deleteShoppingRequest(int id) async {
    try {
      await httpDelete(uri: '/requests/' + id.toString(), context: context);
      return true;
    } catch (_) {
      throw _;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.account_circle,
                    color: Theme.of(context).colorScheme.primary),
                Text(' - '),
                Flexible(
                    child: Text(
                  widget.data.requesterNickname,
                  style: Theme.of(context).textTheme.bodyText1,
                )),
              ],
            ),
            SizedBox(
              height: 5,
            ),
            Row(
              children: <Widget>[
                Icon(Icons.receipt, color: Theme.of(context).colorScheme.primary),
                Text(' - '),
                Flexible(
                    child: Text(widget.data.name,
                        style: Theme.of(context).textTheme.bodyText1)),
              ],
            ),
            SizedBox(
              height: 5,
            ),
            Row(
              children: <Widget>[
                Icon(
                  Icons.date_range,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Text(' - '),
                Flexible(
                    child: Text(
                        DateFormat('yyyy/MM/dd - kk:mm')
                            .format(widget.data.updatedAt),
                        style: Theme.of(context).textTheme.bodyText1)),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Visibility(
              visible: widget.data.requesterId == currentUserId,
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    FlatButton.icon(
                        onPressed: () {
                          showDialog(
                              barrierDismissible: false,
                              context: context,
                              child: FutureSuccessDialog(
                                future:
                                _deleteShoppingRequest(
                                    widget
                                        .data.requestId),
                                dataTrueText: 'delete_scf',
                                onDataTrue: () {
                                  Navigator.pop(context);
                                  Navigator.pop(
                                      context, 'deleted');
                                },
                              )
                          );
                        },
                        color: Theme.of(context).colorScheme.secondary,
                        label: Text(
                          'delete'.tr(),
                          style: Theme.of(context).textTheme.button,
                        ),
                        icon: Icon(Icons.delete,
                            color: Theme.of(context).textTheme.button.color)),
                  ],
                ),
              ),
            ),
            Visibility(
              visible: widget.data.requesterId != currentUserId,
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FlatButton.icon(
                      onPressed: () {
                        showDialog(
                            barrierDismissible: false,
                            context: context,
                            child: FutureSuccessDialog(
                              future: _fulfillShoppingRequest(widget.data.requestId),
                              dataTrueText: 'fulfill_scf',
                              onDataTrue: () {
                                Navigator.pop(context);
                                Navigator.pop(context, 'deleted');
                              },
                            )
                        );
                      },
                      color: Theme.of(context).colorScheme.secondary,
                      label: Text('remove_from_list'.tr(),
                          style: Theme.of(context).textTheme.button),
                      icon: Icon(Icons.check,
                          color: Theme.of(context).textTheme.button.color),
                    ),
                    FlatButton.icon(
                      onPressed: () {
                        showDialog(
                            barrierDismissible: false,
                            context: context,
                            child: FutureSuccessDialog(
                              future: _fulfillShoppingRequest(widget.data.requestId),
                              dataTrueText: 'fulfill_scf',
                              onDataTrue: () {
                                Navigator.pop(context);
                                Navigator.pop(context, 'deleted');
                              },
                            )
                        ).then((value) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      AddTransactionRoute(
                                        type: TransactionType
                                            .fromShopping,
                                        shoppingData:
                                        widget
                                            .data,
                                      )
                              )
                          );
                        });
                      },
                      color: Theme.of(context).colorScheme.secondary,
                      label: Text('add_as_expense'.tr(),
                          style: Theme.of(context).textTheme.button),
                      icon: Icon(Icons.attach_money,
                          color: Theme.of(context).textTheme.button.color),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      )
    );
  }
}
