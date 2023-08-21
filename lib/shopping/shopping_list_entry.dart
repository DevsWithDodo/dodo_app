import 'package:collection/collection.dart' show IterableExtension;
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/add_reaction_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/past_reaction_container.dart';
import 'package:csocsort_szamla/purchase/add_purchase_page.dart';
import 'package:csocsort_szamla/shopping/shopping_all_info.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../purchase/add_modify_purchase.dart';
import 'edit_request_dialog.dart';

class ShoppingListEntry extends StatefulWidget {
  final ShoppingRequest shoppingRequest;
  final Function(int) onDeleteRequest;
  final Function(ShoppingRequest) onEditRequest;

  const ShoppingListEntry({
    required this.shoppingRequest,
    required this.onDeleteRequest,
    required this.onEditRequest,
  });

  @override
  _ShoppingListEntryState createState() => _ShoppingListEntryState();
}

class _ShoppingListEntryState extends State<ShoppingListEntry> {
  late Icon icon;
  late TextStyle mainTextStyle;
  late TextStyle subTextStyle;
  late BoxDecoration boxDecoration;

  String? name;
  late User user;

  @override
  void initState() {
    super.initState();
    user = context.read<AppStateProvider>().user!;
  }

  void handleSendReaction(String reaction) {
    Reaction? oldReaction = widget.shoppingRequest.reactions!
        .firstWhereOrNull((element) => element.userId == user.id);
    bool alreadyReacted = oldReaction != null;
    bool sameReaction =
        alreadyReacted ? oldReaction.reaction == reaction : false;
    if (sameReaction) {
      widget.shoppingRequest.reactions!.remove(oldReaction);
      setState(() {});
    } else if (!alreadyReacted) {
      widget.shoppingRequest.reactions!.add(Reaction(
        nickname: context.read<AppStateProvider>().user!.username,
        reaction: reaction,
        userId: user.id,
      ));
      setState(() {});
    } else {
      widget.shoppingRequest.reactions!.add(Reaction(
        nickname: oldReaction.nickname,
        reaction: reaction,
        userId: user.id,
      ));
      widget.shoppingRequest.reactions!.remove(oldReaction);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    name = widget.shoppingRequest.name;
    mainTextStyle = Theme.of(context)
        .textTheme
        .bodyLarge!
        .copyWith(color: Theme.of(context).colorScheme.onSurface);
    subTextStyle = Theme.of(context)
        .textTheme
        .bodySmall!
        .copyWith(color: Theme.of(context).colorScheme.onSurface);
    boxDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(20),
    );
    if (widget.shoppingRequest.requesterId == user.id) {
      icon = Icon(
        Icons.shopping_cart_outlined,
        color: Theme.of(context).colorScheme.primary,
      );
    } else {
      icon = Icon(Icons.card_giftcard,
          color: Theme.of(context).colorScheme.secondary);
    }
    return Dismissible(
      key: UniqueKey(),
      secondaryBackground: Container(
        child: Align(
            alignment: Alignment.centerRight,
            child: Icon(
              widget.shoppingRequest.requesterId != user.id
                  ? Icons.done
                  : Icons.delete,
              size: 30,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            )),
      ),
      dismissThresholds: {
        DismissDirection.startToEnd: 0.6,
        DismissDirection.endToStart: 0.6
      },
      background: Align(
          alignment: Alignment.centerLeft,
          child: Icon(
            widget.shoppingRequest.requesterId != user.id
                ? Icons.attach_money
                : Icons.edit,
            size: 30,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          )),
      onDismissed: (direction) {
        // If requester is not the current user, the request has to be deleted either way
        if (widget.shoppingRequest.requesterId != user.id) {
          showFutureOutputDialog(
            context: context,
            future: _deleteFulfillShoppingRequest(widget.shoppingRequest.id),
            outputCallbacks: {
              BoolFutureOutput.True: () => Navigator.of(context).pop(true),
            },
          ).then((value) {
            widget.onDeleteRequest(widget.shoppingRequest.id);
            // But if the direction is startToEnd, the AddPurchase site has to be called
            if (direction == DismissDirection.startToEnd && value == true) {
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
        } else {
          // If the requester is the current user, then on one swipe the request is deleted, on the other it is edited
          if (direction == DismissDirection.endToStart) {
            showFutureOutputDialog(
              barrierDismissible: false,
              context: context,
              future: _deleteFulfillShoppingRequest(widget.shoppingRequest.id),
              outputCallbacks: {
                BoolFutureOutput.True: () => Navigator.of(context).pop(true),
              },
            ).then((value) {
              if (value ?? false)
                widget.onDeleteRequest(widget.shoppingRequest.id);
            });
          } else if (direction == DismissDirection.startToEnd) {
            showDialog<ShoppingRequest>(
              builder: (context) => EditRequestDialog(
                textBefore: widget.shoppingRequest.name,
                requestId: widget.shoppingRequest.id,
              ),
              context: context,
            ).then((value) {
              print(value);
              if (value != null) {
                widget.onEditRequest(value);
              }
            });
          }
        }
      },
      child: Stack(
        children: [
          Container(
            height: 75,
            width: MediaQuery.of(context).size.width,
            decoration: boxDecoration,
            margin: EdgeInsets.only(
                top: widget.shoppingRequest.reactions!.length == 0 ? 5 : 10,
                bottom: 8,
                left: 5,
                right: 5),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onLongPress: () {
                  showDialog(
                      builder: (context) => AddReactionDialog(
                            type: 'requests',
                            reactions: widget.shoppingRequest.reactions!,
                            reactToId: widget.shoppingRequest.id,
                            onSend: this.handleSendReaction,
                          ),
                      context: context);
                },
                onTap: () async {
                  showModalBottomSheet<Map<String, dynamic>>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => SingleChildScrollView(
                        child: ShoppingAllInfo(widget.shoppingRequest)),
                  ).then((value) {
                    if (value != null) {
                      if (value['type'] == 'deleted') {
                        widget.onDeleteRequest(widget.shoppingRequest.id);
                      } else {
                        widget.onEditRequest(value['request']);
                      }
                    }
                  });
                },
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Flex(
                    direction: Axis.horizontal,
                    children: <Widget>[
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Flexible(
                              child: Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 10,
                                  ),
                                  icon,
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Flexible(
                                          child: Text(
                                            name!,
                                            style: mainTextStyle,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            widget.shoppingRequest
                                                .requesterNickname,
                                            style: subTextStyle,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PastReactionContainer(
            reactions: widget.shoppingRequest.reactions!,
            reactedToId: widget.shoppingRequest.id,
            isSecondaryColor: widget.shoppingRequest.requesterId == user.id,
            type: 'requests',
            onSendReaction: this.handleSendReaction,
          ),
        ],
      ),
    );
  }

  Future<BoolFutureOutput> _deleteFulfillShoppingRequest(int id) async {
    try {
      await Http.delete(uri: '/requests/' + id.toString());
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }
}
