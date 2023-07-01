import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/shopping/edit_request_dialog.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:csocsort_szamla/purchase/add_purchase_page.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:provider/provider.dart';

import '../purchase/add_modify_purchase.dart';

class ShoppingAllInfo extends StatefulWidget {
  final ShoppingRequest shoppingRequest;

  ShoppingAllInfo(this.shoppingRequest);

  @override
  _ShoppingAllInfoState createState() => _ShoppingAllInfoState();
}

class _ShoppingAllInfoState extends State<ShoppingAllInfo> {

  Future<bool> _fulfillShoppingRequest(int id) async {
    try {
      await Http.delete(uri: '/requests/' + id.toString());
      Future.delayed(delayTime()).then((value) => _onFulfillShoppingRequest());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onFulfillShoppingRequest() {
    Navigator.pop(context, true);
    Navigator.pop(context, {'type': 'deleted'});
  }

  Future<bool> _deleteShoppingRequest(int id) async {
    try {
      await Http.delete(uri: '/requests/' + id.toString());
      Future.delayed(delayTime()).then((value) => _onDeleteShoppingRequest());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onDeleteShoppingRequest() {
    Navigator.pop(context);
    Navigator.pop(context, {'type': 'deleted'});
  }

  @override
  void initState() {
    super.initState();
    
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<User>(
      builder: (context, user, _) {
        return Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.account_circle,
                      color: Theme.of(context).colorScheme.secondary),
                  Flexible(
                    child: Text(
                      ' - ' + widget.shoppingRequest.requesterNickname,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 5,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.receipt_long,
                      color: Theme.of(context).colorScheme.secondary),
                  Flexible(
                    child: Text(
                      ' - ' + widget.shoppingRequest.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
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
                              .format(widget.shoppingRequest.updatedAt),
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Visibility(
                visible: widget.shoppingRequest.requesterId == user.id,
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GradientButton.icon(
                            onPressed: () {
                              showDialog<ShoppingRequest>(
                                builder: (context) => EditRequestDialog(
                                  requestId: widget.shoppingRequest.id,
                                  textBefore: widget.shoppingRequest.name,
                                ),
                                context: context,
                              ).then((value) {
                                if (value != null) {
                                  Navigator.pop(context, {
                                    'type': 'modified',
                                    'request': value,
                                  });
                                }
                              });
                            },
                            icon: Icon(Icons.edit),
                            label: Text('modify'.tr()),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GradientButton.icon(
                            onPressed: () {
                              showDialog(
                                builder: (context) => FutureSuccessDialog(
                                  future: _deleteShoppingRequest(
                                      widget.shoppingRequest.id),
                                ),
                                barrierDismissible: false,
                                context: context,
                              );
                            },
                            icon: Icon(Icons.delete),
                            label: Text('delete'.tr()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: widget.shoppingRequest.requesterId != user.id,
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GradientButton.icon(
                            onPressed: () {
                              showDialog(
                                builder: (context) => FutureSuccessDialog(
                                  future: _fulfillShoppingRequest(
                                    widget.shoppingRequest.id,
                                  ),
                                ),
                                barrierDismissible: false,
                                context: context,
                              );
                            },
                            icon: Icon(Icons.check),
                            label: Text('remove_from_list'.tr()),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GradientButton.icon(
                            onPressed: () {
                              showDialog<bool>(
                                builder: (context) => FutureSuccessDialog(
                                  future: _fulfillShoppingRequest(
                                      widget.shoppingRequest.id),
                                ),
                                barrierDismissible: false,
                                context: context,
                              ).then((value) {
                                if (value == true) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddPurchasePage(
                                        type: PurchaseType.fromShopping,
                                        shoppingData: widget.shoppingRequest,
                                      ),
                                    ),
                                  );
                                }
                              });
                            },
                            icon: Icon(Icons.attach_money),
                            label: Text('add_as_expense'.tr()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      }
    );
  }
}
