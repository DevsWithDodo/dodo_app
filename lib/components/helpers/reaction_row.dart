import 'package:collection/collection.dart';
import 'package:csocsort_szamla/components/helpers/add_reaction_dialog.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReactionRow extends StatelessWidget {
  final ReactionType type;
  final int reactToId;
  final Function(String reaction) onSendReaction;
  final List<Reaction> reactions;

  const ReactionRow({
    super.key,
    required this.type,
    required this.reactToId,
    required this.onSendReaction,
    required this.reactions,
  });

  Future<bool> _sendReaction(String reaction) async {
    try {
      Map<String, dynamic> body = {"${type.reactsTo}_id": reactToId, "reaction": reaction};
      await Http.post(uri: '/${type.path}/reaction', body: body);
      return true;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: Reaction.possibleReactions
              .map(
                (reaction) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _sendReaction(reaction);
                        Navigator.pop(context);
                        onSendReaction(reaction);
                      },
                      child: Ink(
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: reactions.firstWhereOrNull(
                                    (el) => el.userId == context.read<UserNotifier>().user!.id && el.reaction == reaction,
                                  ) !=
                                  null
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : Colors.transparent,
                        ),
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Text(
                            reaction,
                            style: TextStyle(fontSize: 50),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList()),
    );
  }
}
