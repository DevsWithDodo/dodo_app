import 'package:collection/collection.dart' show IterableExtension;
import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/providers/app_state_provider.dart';
import 'package:csocsort_szamla/components/helpers/add_reaction_dialog.dart';
import 'package:csocsort_szamla/components/helpers/past_reaction_container.dart';
import 'package:csocsort_szamla/components/purchase/purchase_all_info.dart';
import 'package:easy_localization/easy_localization.dart';
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
  late List<Reaction> reactions;

  @override
  void initState() {
    super.initState();
    reactions = widget.purchase.reactions!;
  }

  void handleSendReaction(String reaction, int userId) {
    setState(() {
      User user = context.read<AppStateProvider>().user!;
      Reaction? oldReaction = reactions.firstWhereOrNull((element) => element.userId == user.id);
      bool alreadyReacted = oldReaction != null;
      bool sameReaction = alreadyReacted ? oldReaction.reaction == reaction : false;
      if (sameReaction) {
        reactions.remove(oldReaction);
      } else if (!alreadyReacted) {
        reactions.add(Reaction(
          nickname: user.username,
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
    ThemeName themeName = context.watch<AppStateProvider>().themeName;
    int? selectedMemberId = widget.selectedMemberId;
    String note = (widget.purchase.name == '')
        ? 'no_note'.tr()
        : widget.purchase.name[0].toUpperCase() + widget.purchase.name.substring(1);
    bool bought = widget.purchase.buyerId == selectedMemberId;
    bool received = widget.purchase.receivers.where((element) => element.id == selectedMemberId).isNotEmpty;

    Color textColor = bought
        ? themeName.type == ThemeType.gradient
            ? Theme.of(context).colorScheme.onPrimary
            : received
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onSurfaceVariant;

    Widget buyer = Row(
      children: [
        Icon(
          bought
              ? received
                  ? Icons.swap_horiz
                  : Icons.call_made
              : Icons.call_received,
          color: textColor,
          size: 11,
        ),
        SizedBox(width: 2),
        Text(
          bought ? 'purchase-entry.bought'.tr() : 'purchase-entry.received'.tr(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: textColor,
                fontSize: 9.5,
              ),
        ),
      ],
    );
    TextStyle mainTextStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(color: textColor);
    TextStyle subTextStyle = Theme.of(context).textTheme.bodySmall!.copyWith(color: textColor);
    String names = bought ? widget.purchase.receivers.join(', ') : widget.purchase.buyerNickname;

    String amount = (bought
            ? widget.purchase.totalAmountOriginalCurrency
            : (-widget.purchase.receivers
                .firstWhere((element) => element.id == selectedMemberId)
                .balanceOriginalCurrency))
        .toMoneyString(widget.purchase.originalCurrency, withSymbol: true);
    String amountToSelf = bought && received
        ? (-widget.purchase.receivers.firstWhere((element) => element.id == selectedMemberId).balanceOriginalCurrency)
            .toMoneyString(
            widget.purchase.originalCurrency,
            withSymbol: true,
          )
        : '';
    BoxDecoration decoration = bought
        ? received
            ? BoxDecoration(
                gradient: AppTheme.gradientFromTheme(themeName, useSecondaryContainer: true),
                borderRadius: BorderRadius.circular(15),
              )
            : BoxDecoration(
                gradient: AppTheme.gradientFromTheme(themeName, usePrimaryContainer: true),
                borderRadius: BorderRadius.circular(15),
              )
        : BoxDecoration();
    return Selector<AppStateProvider, User>(
        selector: (context, userProvider) => userProvider.user!,
        builder: (context, user, _) {
          return Stack(
            children: [
              Container(
                decoration: decoration,
                margin: EdgeInsets.only(
                  top: widget.purchase.reactions!.length == 0 ? 0 : 14,
                  bottom: 4,
                  left: 4,
                  right: 4,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onLongPress: selectedMemberId != user.id
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (context) => AddReactionDialog(
                                type: ReactionType.purchase,
                                reactions: widget.purchase.reactions!,
                                reactToId: widget.purchase.id,
                                onSend: this.handleSendReaction,
                              ),
                            );
                          },
                    onTap: () async {
                      showModalBottomSheet<String>(
                        isScrollControlled: true,
                        context: context,
                        builder: (context) => SingleChildScrollView(
                          child: PurchaseAllInfo(
                            widget.purchase,
                            widget.selectedMemberId,
                          ),
                        ),
                      ).then(
                        (val) {
                          if (val == 'deleted') {
                            EventBus bus = EventBus.instance;
                            bus.fire(EventBus.refreshPurchases);
                            bus.fire(EventBus.refreshBalances);
                          }
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buyer,
                                Flexible(
                                  child: Text(
                                    note,
                                    style: mainTextStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    names,
                                    style: subTextStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              DefaultTextStyle(
                                style: mainTextStyle,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(amount),
                                    Visibility(
                                      visible: received && bought,
                                      child: Text(amountToSelf),
                                    ),
                                  ],
                                ),
                              ),
                              Visibility(
                                visible: widget.purchase.category != null,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Icon(
                                    widget.purchase.category?.icon,
                                    color: mainTextStyle.color,
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
                  type: ReactionType.purchase,
                  onSendReaction: this.handleSendReaction,
                ),
              ),
            ],
          );
        });
  }
}
