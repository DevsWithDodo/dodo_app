import 'package:csocsort_szamla/components/helpers/add_reaction_dialog.dart';
import 'package:csocsort_szamla/components/helpers/background_paint.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/helpers/reaction_row.dart';
import 'package:csocsort_szamla/components/shopping/edit_request_dialog.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/purchase_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShoppingAllInfo extends StatefulWidget {
  final ShoppingRequest shoppingRequest;
  final Function(String reaction) onSendReaction;

  const ShoppingAllInfo(this.shoppingRequest, this.onSendReaction, {super.key});

  @override
  State<ShoppingAllInfo> createState() => _ShoppingAllInfoState();
}

class _ShoppingAllInfoState extends State<ShoppingAllInfo> {
  Future<BoolFutureOutput> _fulfillShoppingRequest(int id) async {
    try {
      await Http.delete(uri: '/requests/$id');
      return BoolFutureOutput.True;
    } catch (_) {
      rethrow;
    }
  }

  Future<BoolFutureOutput> _deleteShoppingRequest(int id) async {
    try {
      await Http.delete(uri: '/requests/$id');
      return BoolFutureOutput.True;
    } catch (_) {
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<UserNotifier, User>(
        selector: (context, provider) => provider.user!,
        builder: (context, user, _) {
          return BackgroundPaint(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ReactionRow(
                    type: ReactionType.request,
                    reactToId: widget.shoppingRequest.id,
                    onSendReaction: widget.onSendReaction,
                    reactions: widget.shoppingRequest.reactions!,
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Icon(Icons.account_circle, color: Theme.of(context).colorScheme.secondary),
                      Flexible(
                        child: Text(
                          ' - ${widget.shoppingRequest.requesterNickname}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.secondary),
                      Flexible(
                        child: Text(
                          ' - ${widget.shoppingRequest.name}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.date_range,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      Flexible(
                        child: Text(
                          ' - ${DateFormat('yyyy/MM/dd - HH:mm').format(widget.shoppingRequest.updatedAt)}',
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
                                onPressed: () async {
                                  final value = await showDialog<ShoppingRequest>(
                                    builder: (context) => EditRequestDialog(
                                      requestId: widget.shoppingRequest.id,
                                      textBefore: widget.shoppingRequest.name,
                                    ),
                                    context: context,
                                  );
                                  if (value != null) {
                                    Navigator.pop(context, {
                                      'type': 'modified',
                                      'request': value,
                                    });
                                  }
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
                                  showFutureOutputDialog(
                                    context: context,
                                    future: _deleteShoppingRequest(widget.shoppingRequest.id),
                                    outputCallbacks: {
                                      BoolFutureOutput.True: () {
                                        Navigator.pop(context);
                                        Navigator.pop(context, {'type': 'deleted'});
                                      }
                                    },
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
                                  showFutureOutputDialog(
                                    context: context,
                                    future: _fulfillShoppingRequest(
                                      widget.shoppingRequest.id,
                                    ),
                                    outputCallbacks: {
                                      BoolFutureOutput.True: () {
                                        Navigator.pop(context, true);
                                        Navigator.pop(context, {'type': 'deleted'});
                                      }
                                    },
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
                                onPressed: () async {
                                  final value = await showFutureOutputDialog<bool, BoolFutureOutput>(
                                    context: context,
                                    future: _fulfillShoppingRequest(widget.shoppingRequest.id),
                                    outputCallbacks: {
                                      BoolFutureOutput.True: () {
                                        Navigator.pop(context, true);
                                        Navigator.pop(context, {'type': 'deleted'});
                                      }
                                    },
                                  );
                                  if ((value ?? false)) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PurchasePage(
                                          shoppingData: widget.shoppingRequest,
                                        ),
                                      ),
                                    );
                                  }
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
            ),
          );
        });
  }
}
