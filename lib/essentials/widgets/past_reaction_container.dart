import 'package:csocsort_szamla/essentials/models.dart';
import 'package:flutter/material.dart';

import 'add_reaction_dialog.dart';

class PastReactionContainer extends StatelessWidget {
  final List<Reaction> reactions;
  final int reactedToId;
  final Function callback;
  final bool isSecondaryColor;
  final String type;
  PastReactionContainer(
      {this.reactions, this.reactedToId, this.callback, this.isSecondaryColor, this.type});
  @override
  Widget build(BuildContext context) {
    Map<String, int> numberOfReactions = {'❗': 0, '👍': 0, '❤': 0, '😲': 0, '😥': 0, '❓': 0};
    for (Reaction reaction in reactions) {
      if (numberOfReactions.keys.contains(reaction.reaction))
        numberOfReactions[reaction.reaction]++;
    }
    var sortedKeys = numberOfReactions.keys.toList(growable: false)
      ..sort((k1, k2) {
        if (k1 == '❗' && numberOfReactions[k1] != 0) {
          return -1;
        }
        if (k2 == '❗' && numberOfReactions[k2] != 0) {
          return 1;
        }
        return numberOfReactions[k2].compareTo(numberOfReactions[k1]);
      });
    List<List<dynamic>> sortedReactions = [];
    for (String key in sortedKeys) {
      sortedReactions.add([key, numberOfReactions[key]]);
    }
    int sum = 0;
    for (var list in sortedReactions) {
      sum += list[1];
    }

    List<String> orderedReactions = [];
    int index = 0;
    if (sortedReactions[index][1] > 0) {
      orderedReactions.add(sortedReactions[index][0]);
      index++;
    }
    if (sortedReactions[index][1] > 0) {
      orderedReactions.add(sortedReactions[index][0]);
    }
    if (sum > 1) {
      orderedReactions.add(sum.toString());
    }
    return Visibility(
      visible: reactions.length != 0,
      child: Container(
        margin: EdgeInsets.only(right: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Material(
              type: MaterialType.canvas,
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showDialog(
                      builder: (context) => AddReactionDialog(
                            type: type,
                            reactions: reactions,
                            reactToId: reactedToId,
                            callback: callback,
                          ),
                      context: context);
                },
                borderRadius: BorderRadius.circular(10),
                child: Ink(
                    padding: EdgeInsets.only(top: 4, bottom: 4, left: 6, right: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.surfaceVariant),
                    child: Row(
                        children: orderedReactions.map((reaction) {
                      if (reaction != null && double.tryParse(reaction) != null) {
                        return Text(reaction,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant));
                      }
                      return Text(
                        reaction,
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    }).toList())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
