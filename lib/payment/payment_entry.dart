import 'package:collection/collection.dart' show IterableExtension;
import 'package:csocsort_szamla/essentials/app_theme.dart';
import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/event_bus.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/add_reaction_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/past_reaction_container.dart';
import 'package:csocsort_szamla/payment/payment_all_info.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaymentEntry extends StatefulWidget {
  final Payment payment;
  final int? selectedMemberId;
  PaymentEntry({
    required this.payment,
    this.selectedMemberId,
  });

  @override
  _PaymentEntryState createState() => _PaymentEntryState();
}

class _PaymentEntryState extends State<PaymentEntry> {
  void handleSendReaction(String reaction) {
    User user = context.read<AppStateProvider>().user!;
    Reaction? oldReaction = widget.payment.reactions!
        .firstWhereOrNull((element) => element.userId == user.id);
    bool alreadyReacted = oldReaction != null;
    bool sameReaction =
        alreadyReacted ? oldReaction.reaction == reaction : false;
    if (sameReaction) {
      widget.payment.reactions!.remove(oldReaction);
      setState(() {});
    } else if (!alreadyReacted) {
      widget.payment.reactions!.add(Reaction(
        nickname: user.username,
        reaction: reaction,
        userId: user.id,
      ));
      setState(() {});
    } else {
      widget.payment.reactions!.add(
        Reaction(
          nickname: oldReaction.nickname,
          reaction: reaction,
          userId: user.id,
        ),
      );
      widget.payment.reactions!.remove(oldReaction);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    String themeName = context.watch<AppStateProvider>().themeName;
    return Selector<AppStateProvider, User>(
        selector: (context, userProvider) => userProvider.user!,
        builder: (context, user, _) {
          int selectedMemberId = widget.selectedMemberId ?? user.id;
          bool paid = widget.payment.payerId == selectedMemberId;
          Color textColor = paid
              ? themeName.contains('Gradient')
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onPrimaryContainer
              : Theme.of(context).colorScheme.onSurfaceVariant;
          String note = (widget.payment.note == '')
              ? 'no_note'.tr()
              : widget.payment.note[0].toUpperCase() +
                  widget.payment.note.substring(1);
          String takerName = paid
              ? widget.payment.takerNickname
              : widget.payment.payerNickname;
          String amount = (paid ? '' : '-') +
              widget.payment.amountOriginalCurrency.toMoneyString(
                  widget.payment.originalCurrency,
                  withSymbol: true);
          BoxDecoration boxDecoration = paid
              ? BoxDecoration(
                  gradient: AppTheme.gradientFromTheme(themeName,
                      usePrimaryContainer: true),
                  borderRadius: BorderRadius.circular(15),
                )
              : BoxDecoration();

          TextStyle mainTextStyle =
              Theme.of(context).textTheme.bodyLarge!.copyWith(color: textColor);
          TextStyle subTextStyle =
              Theme.of(context).textTheme.bodySmall!.copyWith(color: textColor);
          Widget buyer = Row(
            children: [
              Icon(
                paid ? Icons.call_made : Icons.call_received,
                color: textColor,
                size: 11,
              ),
              SizedBox(width: 2),
              Text(
                paid ? 'payment-entry.paid'.tr() : 'payment-entry.received'.tr(),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: textColor,
                      fontSize: 9.5,
                    ),
              ),
            ],
          );
          return Stack(
            children: [
              Container(
                decoration: boxDecoration,
                margin: EdgeInsets.only(
                  top: widget.payment.reactions!.length == 0 ? 0 : 14,
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
                                builder: (context) => AddReactionDialog(
                                      type: 'payments',
                                      reactions: widget.payment.reactions!,
                                      reactToId: widget.payment.id,
                                      onSend: this.handleSendReaction,
                                    ),
                                context: context);
                          },
                    onTap: () async {
                      showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => SingleChildScrollView(
                              child: PaymentAllInfo(widget.payment))).then(
                        (value) {
                          if (value == 'deleted') {
                            final bus = EventBus.instance;
                            bus.fire(EventBus.refreshPayments);
                            bus.fire(EventBus.refreshBalances);
                          }
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
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
                                    takerName,
                                    style: mainTextStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    note,
                                    style: subTextStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ],
                            ),
                          ),
                          Text(
                            amount,
                            style: mainTextStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: selectedMemberId == user.id,
                child: PastReactionContainer(
                  reactedToId: widget.payment.id,
                  reactions: widget.payment.reactions!,
                  onSendReaction: this.handleSendReaction,
                  isSecondaryColor: widget.payment.payerId == user.id,
                  type: 'payments',
                ),
              )
            ],
          );
        });
  }
}
