import 'package:csocsort_szamla/helpers/models.dart';
import 'package:flutter/material.dart';

import 'add_reaction_dialog.dart';

class PastReactionContainer extends StatelessWidget {
  final List<Reaction> reactions;
  final int reactedToId;
  final Function(String reaction) onSendReaction;
  final bool isSecondaryColor;
  final ReactionType type;
  const PastReactionContainer({super.key, 
    required this.reactions,
    required this.reactedToId,
    required this.onSendReaction,
    required this.isSecondaryColor,
    required this.type,
  });
  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return Container();
    }
    Map<String, int> reactionMap = {};
    for (Reaction reaction in reactions) {
      if (reactionMap.keys.contains(reaction.reaction)) {
        reactionMap[reaction.reaction] = reactionMap[reaction.reaction]! + 1;
      } else {
        reactionMap[reaction.reaction] = 1;
      }
    }
    var sortedKeys = reactionMap.keys.toList(growable: false)
      ..sort((k1, k2) {
        if (k1 == '❗') {
          return -1;
        }
        if (k2 == '❗') {
          return 1;
        }
        return reactionMap[k2]!.compareTo(reactionMap[k1]!);
      });
    int sum = sortedKeys.map((k) => reactionMap[k]!).reduce((a, b) => a + b);
    List<String> orderedReactions = sortedKeys.map((k) => k).toList(growable: false).take(2).toList();
    return Container(
      margin: EdgeInsets.only(right: 7),
      child: Align(
        alignment: Alignment.topRight,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => showDialog(
              context: context,
              builder: (context) => AddReactionDialog(
                type: type,
                reactions: reactions,
                reactToId: reactedToId,
                onSend: onSendReaction,
              ),
            ),
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Visibility(
                    visible: sum > 1,
                    child: Text(sum.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge!
                            .copyWith(color: Theme.of(context).colorScheme.onSurface)),
                  ),
                  ...orderedReactions
                      .map(
                        (reaction) => Text(
                          reaction,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                      
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
