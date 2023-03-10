import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/widgets/add_reaction_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/past_reaction_container.dart';
import 'package:csocsort_szamla/purchase/add_purchase_page.dart';
import 'package:csocsort_szamla/shopping/shopping_all_info.dart';
import 'package:flutter/material.dart';

import '../purchase/add_modify_purchase.dart';
import 'edit_request_dialog.dart';

class ShoppingRequestData {
  int requestId;
  String name;
  String requesterUsername, requesterNickname;
  int requesterId;
  DateTime updatedAt;
  List<Reaction> reactions;

  ShoppingRequestData(
      {this.updatedAt,
      this.requesterId,
      this.requesterUsername,
      this.name,
      this.requestId,
      this.requesterNickname,
      this.reactions});

  factory ShoppingRequestData.fromJson(Map<String, dynamic> json) {
    return ShoppingRequestData(
        requestId: json['request_id'],
        requesterId: json['requester_id'],
        requesterUsername: json['requester_username'],
        requesterNickname: json['requester_nickname'],
        name: json['name'],
        updatedAt: DateTime.parse(json['updated_at']).toLocal(),
        reactions:
            json['reactions'].map<Reaction>((reaction) => Reaction.fromJson(reaction)).toList());
  }

  @override
  String toString() {
    return name + '; ' + updatedAt.toString() + '; ' + reactions.join(', ');
  }
}

class ShoppingListEntry extends StatefulWidget {
  final ShoppingRequestData data;
  final Function callback;

  const ShoppingListEntry({this.data, this.callback});

  @override
  _ShoppingListEntryState createState() => _ShoppingListEntryState();
}

class _ShoppingListEntryState extends State<ShoppingListEntry> {
  Icon icon;
  TextStyle mainTextStyle;
  TextStyle subTextStyle;
  BoxDecoration boxDecoration;

  String name;
  String user;

  void callbackForReaction(String reaction) {
    //TODO: currentNickname
    Reaction oldReaction = widget.data.reactions
        .firstWhere((element) => element.userId == currentUserId, orElse: () => null);
    bool alreadyReacted = oldReaction != null;
    bool sameReaction = alreadyReacted ? oldReaction.reaction == reaction : false;
    if (sameReaction) {
      widget.data.reactions.remove(oldReaction);
      setState(() {});
    } else if (!alreadyReacted) {
      widget.data.reactions.add(Reaction(
        nickname: currentUsername,
        reaction: reaction,
        userId: currentUserId,
      ));
      setState(() {});
    } else {
      widget.data.reactions
          .add(Reaction(nickname: oldReaction.nickname, reaction: reaction, userId: currentUserId));
      widget.data.reactions.remove(oldReaction);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    name = widget.data.name;
    user = widget.data.requesterUsername;
    mainTextStyle = Theme.of(context)
        .textTheme
        .bodyLarge
        .copyWith(color: Theme.of(context).colorScheme.onSurface);
    subTextStyle = Theme.of(context)
        .textTheme
        .bodySmall
        .copyWith(color: Theme.of(context).colorScheme.onSurface);
    boxDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(20),
    );
    if (widget.data.requesterId == currentUserId) {
      icon = Icon(
        Icons.shopping_cart_outlined,
        color: Theme.of(context).colorScheme.primary,
      );
    } else {
      icon = Icon(Icons.card_giftcard, color: Theme.of(context).colorScheme.secondary);
    }
    return Dismissible(
      key: UniqueKey(),
      secondaryBackground: Container(
        child: Align(
            alignment: Alignment.centerRight,
            child: Icon(
              widget.data.requesterId != currentUserId ? Icons.done : Icons.delete,
              size: 30,
              color: Theme.of(context).textTheme.bodyText1.color,
            )),
      ),
      dismissThresholds: {DismissDirection.startToEnd: 0.6, DismissDirection.endToStart: 0.6},
      background: Align(
          alignment: Alignment.centerLeft,
          child: Icon(
            widget.data.requesterId != currentUserId ? Icons.attach_money : Icons.edit,
            size: 30,
            color: Theme.of(context).textTheme.bodyText1.color,
          )),
      onDismissed: (direction) {
        if (widget.data.requesterId != currentUserId) {
          showDialog(
                  builder: (context) => FutureSuccessDialog(
                        future: _deleteFulfillShoppingRequest(widget.data.requestId, context),
                        dataTrueText: 'fulfill_scf',
                        onDataTrue: () {
                          _onDeleteFulfillShoppingRequest();
                        },
                      ),
                  barrierDismissible: false,
                  context: context)
              .then((value) {
            widget.callback(restoreId: widget.data.requestId);
            if (direction == DismissDirection.startToEnd && value == true) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPurchaseRoute(
                    type: PurchaseType.fromShopping,
                    shoppingData: widget.data,
                  ),
                ),
              );
            }
          });
        } else {
          if (direction == DismissDirection.endToStart) {
            showDialog(
                    builder: (context) => FutureSuccessDialog(
                          future: _deleteFulfillShoppingRequest(widget.data.requestId, context),
                          dataTrueText: 'delete_scf',
                          onDataTrue: () {
                            _onDeleteFulfillShoppingRequest();
                          },
                        ),
                    barrierDismissible: false,
                    context: context)
                .then((value) {
              if (value ?? false) widget.callback(restoreId: widget.data.requestId);
            });
          } else if (direction == DismissDirection.startToEnd) {
            showDialog(
              builder: (context) => EditRequestDialog(
                textBefore: widget.data.name,
                requestId: widget.data.requestId,
              ),
              context: context,
            ).then((value) {
              if (value ?? false) {
                widget.callback();
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
                top: widget.data.reactions.length == 0 ? 5 : 10, bottom: 8, left: 5, right: 5),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onLongPress: () {
                  showDialog(
                      builder: (context) => AddReactionDialog(
                            type: 'requests',
                            reactions: widget.data.reactions,
                            reactToId: widget.data.requestId,
                            callback: this.callbackForReaction,
                          ),
                      context: context);
                },
                onTap: () async {
                  showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) =>
                          SingleChildScrollView(child: ShoppingAllInfo(widget.data))).then((val) {
                    if (val == 'deleted') widget.callback(restoreId: widget.data.requestId);
                    if (val == 'edited') widget.callback();
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Flexible(
                                          child: Text(
                                            name,
                                            style: mainTextStyle,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            widget.data.requesterNickname,
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
            reactions: widget.data.reactions,
            reactedToId: widget.data.requestId,
            isSecondaryColor: widget.data.requesterId == currentUserId,
            type: 'requests',
            callback: this.callbackForReaction,
          ),
        ],
      ),
    );
  }

  Future<bool> _deleteFulfillShoppingRequest(int id, var buildContext) async {
    try {
      await httpDelete(uri: '/requests/' + id.toString(), context: context);
      Future.delayed(delayTime()).then((value) => _onDeleteFulfillShoppingRequest());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onDeleteFulfillShoppingRequest() {
    Navigator.pop(context, true);
  }
}
