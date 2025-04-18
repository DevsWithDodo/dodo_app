import 'package:collection/collection.dart' show IterableExtension;
import 'package:csocsort_szamla/components/helpers/add_reaction_dialog.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/past_reaction_container.dart';
import 'package:csocsort_szamla/components/shopping/shopping_all_info.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/purchase_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'edit_request_dialog.dart';

class ShoppingListEntry extends StatefulWidget {
  final ShoppingRequest shoppingRequest;
  final Function(int) onDeleteRequest;
  final Function(ShoppingRequest) onEditRequest;

  const ShoppingListEntry({
    super.key,
    required this.shoppingRequest,
    required this.onDeleteRequest,
    required this.onEditRequest,
  });

  @override
  State<ShoppingListEntry> createState() => _ShoppingListEntryState();
}

class _ShoppingListEntryState extends State<ShoppingListEntry> {
  late List<Reaction> reactions;

  @override
  void initState() {
    super.initState();
    reactions = widget.shoppingRequest.reactions!;
  }

  void handleSendReaction(String reaction) {
    setState(() {
      User user = context.read<UserNotifier>().user!;
      Reaction? oldReaction = reactions.firstWhereOrNull((element) => element.userId == user.id);
      bool alreadyReacted = oldReaction != null;
      bool sameReaction = alreadyReacted ? oldReaction.reaction == reaction : false;
      if (sameReaction) {
        reactions.remove(oldReaction);
      } else if (!alreadyReacted) {
        reactions.add(Reaction(
          nickname: 'you'.tr(),
          reaction: reaction,
          userId: user.id,
        ));
      } else {
        reactions.add(Reaction(
          nickname: oldReaction.nickname,
          reaction: reaction,
          userId: user.id,
        ));
        reactions.remove(oldReaction);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.shoppingRequest.name;
    User user = context.watch<UserNotifier>().user!;
    TextStyle mainTextStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface);
    TextStyle subTextStyle = Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onSurface);
    BoxDecoration boxDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surfaceContainer,
    );
    Icon icon = Icon(
      Icons.check_box_outlined,
      color: widget.shoppingRequest.requesterId == user.id ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
    );
    return Dismissible(
      key: UniqueKey(),
      secondaryBackground: Align(
        alignment: Alignment.centerRight,
        child: Icon(
          widget.shoppingRequest.requesterId != user.id ? Icons.done : Icons.delete,
        ),
      ),
      dismissThresholds: {DismissDirection.startToEnd: 0.6, DismissDirection.endToStart: 0.6},
      background: Align(
        alignment: Alignment.centerLeft,
        child: Icon(
          widget.shoppingRequest.requesterId != user.id ? Icons.attach_money : Icons.edit,
        ),
      ),
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
            if (direction == DismissDirection.startToEnd && (value == true)) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PurchasePage(
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
              if (value ?? false) widget.onDeleteRequest(widget.shoppingRequest.id);
            });
          } else if (direction == DismissDirection.startToEnd) {
            showDialog<ShoppingRequest>(
              builder: (context) => EditRequestDialog(
                textBefore: widget.shoppingRequest.name,
                requestId: widget.shoppingRequest.id,
              ),
              context: context,
            ).then((value) {
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
            decoration: boxDecoration,
            margin: EdgeInsets.only(top: widget.shoppingRequest.reactions!.isEmpty ? 2 : 8, bottom: 5, left: 12, right: 12),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () async {
                  final value = await showModalBottomSheet<Map<String, dynamic>?>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => SingleChildScrollView(
                      child: ShoppingAllInfo(
                        widget.shoppingRequest,
                        handleSendReaction,
                      ),
                    ),
                  );
                  if (value != null) {
                    if (value['type'] == 'deleted') {
                      widget.onDeleteRequest(widget.shoppingRequest.id);
                    } else {
                      widget.onEditRequest(value['request']);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 20),
                        child: icon,
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
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
                                'shopping-list.entry.wish'.tr(namedArgs: {'name': widget.shoppingRequest.requesterNickname}),
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
              ),
            ),
          ),
          PastReactionContainer(
            reactions: reactions,
            reactedToId: widget.shoppingRequest.id,
            isSecondaryColor: widget.shoppingRequest.requesterId == user.id,
            type: ReactionType.request,
            onSendReaction: handleSendReaction,
          ),
        ],
      ),
    );
  }

  Future<BoolFutureOutput> _deleteFulfillShoppingRequest(int id) async {
    try {
      await Http.delete(uri: '/requests/$id');
      return BoolFutureOutput.True;
    } catch (_) {
      rethrow;
    }
  }
}
