import 'dart:io' show Platform;

import 'package:collection/collection.dart' show IterableExtension;
import 'package:csocsort_szamla/essentials/app_theme.dart';
import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/event_bus.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/add_reaction_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/past_reaction_container.dart';
import 'package:csocsort_szamla/purchase/purchase_all_info.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PurchaseEntry extends StatefulWidget {
  final Purchase purchase;
  final int selectedMemberId;
  const PurchaseEntry({
    required this.purchase,
    required this.selectedMemberId,
  });

  @override
  _PurchaseEntryState createState() => _PurchaseEntryState();
}

class _PurchaseEntryState extends State<PurchaseEntry> {
  late Icon leadingIcon;
  TextStyle? mainTextStyle;
  TextStyle? subTextStyle;
  BoxDecoration? boxDecoration;
  late String note;
  String? names;
  String? amountOriginal = '';
  String? amountToSelfOriginal = '';

  void handleSendReaction(String reaction) {
    User user = context.read<AppStateProvider>().user!;
    Reaction? oldReaction = widget.purchase.reactions!
        .firstWhereOrNull((element) => element.userId == user.id);
    bool alreadyReacted = oldReaction != null;
    bool sameReaction =
        alreadyReacted ? oldReaction.reaction == reaction : false;
    if (sameReaction) {
      widget.purchase.reactions!.remove(oldReaction);
      setState(() {});
    } else if (!alreadyReacted) {
      widget.purchase.reactions!.add(Reaction(
        nickname: user.username,
        reaction: reaction,
        userId: user.id,
      ));
      setState(() {});
    } else {
      widget.purchase.reactions!.add(Reaction(
        nickname: oldReaction.nickname,
        reaction: reaction,
        userId: user.id,
      ));
      widget.purchase.reactions!.remove(oldReaction);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    String themeName = context.watch<AppStateProvider>().themeName;
    int? selectedMemberId = widget.selectedMemberId;
    note = (widget.purchase.name == '')
        ? 'no_note'.tr()
        : widget.purchase.name[0].toUpperCase() +
            widget.purchase.name.substring(1);
    bool bought = widget.purchase.buyerId == selectedMemberId;
    bool received = widget.purchase.receivers
        .where((element) => element.id == selectedMemberId)
        .isNotEmpty;
    /* Set icon, amount and names */
    if (bought && received) {
      leadingIcon = Icon(Icons.swap_horiz,
          color: themeName.contains('Gradient')
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSecondaryContainer);
      amountOriginal = widget.purchase.totalAmountOriginalCurrency
          .toMoneyString(widget.purchase.originalCurrency, withSymbol: true);
      amountToSelfOriginal = (-widget.purchase.receivers
              .firstWhere((element) => element.id == selectedMemberId)
              .balanceOriginalCurrency)
          .toMoneyString(widget.purchase.originalCurrency, withSymbol: true);
      if (widget.purchase.receivers.length > 1) {
        names = widget.purchase.receivers.join(', ');
      } else {
        names = widget.purchase.receivers[0].nickname;
      }
      mainTextStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: themeName.contains('Gradient')
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSecondaryContainer);
      subTextStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: themeName.contains('Gradient')
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSecondaryContainer);
      boxDecoration = BoxDecoration(
        gradient:
            AppTheme.gradientFromTheme(themeName, useSecondaryContainer: true),
        borderRadius: BorderRadius.circular(15),
      );
    } else if (bought) {
      leadingIcon = Icon(Icons.call_made,
          color: themeName.contains('Gradient')
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onPrimaryContainer);
      amountOriginal = widget.purchase.totalAmountOriginalCurrency
          .toMoneyString(widget.purchase.originalCurrency, withSymbol: true);
      if (widget.purchase.receivers.length > 1) {
        names = widget.purchase.receivers.join(', ');
      } else {
        names = widget.purchase.receivers[0].nickname;
      }
      mainTextStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: themeName.contains('Gradient')
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onPrimaryContainer);
      subTextStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: themeName.contains('Gradient')
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onPrimaryContainer);
      boxDecoration = BoxDecoration(
        gradient:
            AppTheme.gradientFromTheme(themeName, usePrimaryContainer: true),
        borderRadius: BorderRadius.circular(15),
      );
    } else if (received) {
      leadingIcon = Icon(Icons.call_received,
          color: Theme.of(context).colorScheme.onSurfaceVariant);
      names = widget.purchase.buyerNickname;
      amountOriginal = (-widget.purchase.receivers
              .firstWhere((element) => element.id == selectedMemberId)
              .balanceOriginalCurrency)
          .toMoneyString(widget.purchase.originalCurrency, withSymbol: true);
      subTextStyle = Theme.of(context)
          .textTheme
          .bodySmall!
          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
      mainTextStyle = Theme.of(context)
          .textTheme
          .bodyLarge!
          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
      boxDecoration = BoxDecoration();
    }
    return Selector<AppStateProvider, User>(
        selector: (context, userProvider) => userProvider.user!,
        builder: (context, user, _) {
          return Stack(
            children: [
              Container(
                height: !kIsWeb && Platform.isWindows ? 85 : 80,
                width: MediaQuery.of(context).size.width,
                decoration: boxDecoration,
                margin: EdgeInsets.only(
                    top: widget.purchase.reactions!.length == 0 ? 0 : 14,
                    bottom: 4,
                    left: 4,
                    right: 4),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onLongPress: selectedMemberId != user.id
                        ? null
                        : () {
                            showDialog(
                                builder: (context) => AddReactionDialog(
                                      type: 'purchases',
                                      reactions: widget.purchase.reactions!,
                                      reactToId: widget.purchase.id,
                                      onSend: this.handleSendReaction,
                                    ),
                                context: context);
                          },
                    onTap: () async {
                      showModalBottomSheet<String>(
                        isScrollControlled: true,
                        context: context,
                        backgroundColor: Theme.of(context).cardTheme.color,
                        builder: (context) => SingleChildScrollView(
                          child: PurchaseAllInfo(
                              widget.purchase, widget.selectedMemberId),
                        ),
                      ).then((val) {
                        if (val == 'deleted') {
                          EventBus bus = EventBus.instance;
                          bus.fire(EventBus.refreshPurchases);
                          bus.fire(EventBus.refreshBalances);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Flexible(
                            child: Row(
                              children: <Widget>[
                                leadingIcon,
                                SizedBox(
                                  width: 20,
                                ),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Flexible(
                                        child: Text(
                                          note,
                                          style: mainTextStyle,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          names!,
                                          style: subTextStyle,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    amountOriginal!,
                                    style: mainTextStyle,
                                  ),
                                  Visibility(
                                    visible: received && bought,
                                    child: Text(
                                      amountToSelfOriginal!,
                                      style: mainTextStyle,
                                    ),
                                  ),
                                ],
                              ),
                              Visibility(
                                visible: widget.purchase.category != null,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Icon(
                                    widget.purchase.category != null
                                        ? widget.purchase.category!.icon
                                        : Icons.not_interested,
                                    color: widget.purchase.category != null
                                        ? mainTextStyle!.color
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: selectedMemberId == user.id,
                child: PastReactionContainer(
                  reactions: widget.purchase.reactions!,
                  reactedToId: widget.purchase.id,
                  isSecondaryColor: bought,
                  type: 'purchases',
                  onSendReaction: this.handleSendReaction,
                ),
              ),
            ],
          );
        });
  }
}
