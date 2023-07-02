import 'dart:math';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models.dart';
import '../http.dart';

class AddReactionDialog extends StatefulWidget {
  final String type;
  final List<Reaction> reactions;
  final int reactToId;
  final Function(String reaction) onSend;
  AddReactionDialog({
    required this.type,
    required this.reactions,
    required this.reactToId,
    required this.onSend,
  });
  @override
  _AddReactionDialogState createState() => _AddReactionDialogState();
}

class _AddReactionDialogState extends State<AddReactionDialog> {
  void _onSendReaction(String reaction) {
    Navigator.pop(context);
    widget.onSend(reaction);
  }

  Future<bool> _sendReaction(String reaction) async {
    try {
      Map<String, dynamic> body = {
        widget.type.substring(0, widget.type.length - 1) + "_id":
            widget.reactToId,
        "reaction": reaction
      };
      await Http.post(uri: '/' + widget.type + '/reaction', body: body);
      return true;
    } catch (_) {
      throw _;
    }
  }

  List<Widget> _generateReactions() {
    String themeName = context.read<AppStateProvider>().themeName;
    User user = context.read<AppStateProvider>().user!;
    return widget.reactions.map((e) {
      return Container(
        padding: EdgeInsets.fromLTRB(10, 4, 10, 4),
        margin: EdgeInsets.fromLTRB(4, 0, 4, 4),
        decoration: BoxDecoration(
          gradient: e.userId == user.id
              ? AppTheme.gradientFromTheme(themeName,
                  useSecondaryContainer: true)
              : LinearGradient(
                  colors: [Colors.transparent, Colors.transparent]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                e.nickname,
                style: e.userId == user.id
                    ? Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: themeName.contains('Gradient')
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer)
                    : Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(e.reaction)
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppStateProvider, int>(
      selector: (_, userProvider) => userProvider.user!.id,
      builder: (context, userId, _) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'reactions'.tr(),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: Reaction.possibleReactions.map(
                      (reaction) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _sendReaction(reaction);
                            _onSendReaction(reaction);
                          },
                          child: Ink(
                            padding: EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: widget.reactions.firstWhereOrNull((el) =>
                                          el.userId == userId &&
                                          el.reaction == reaction) !=
                                      null
                                  ? Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                  : Colors.transparent,
                            ),
                            child: Container(
                              constraints: BoxConstraints(
                                  maxWidth: min(
                                      50,
                                      MediaQuery.of(context).size.width /
                                          2 /
                                          6)),
                              child: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text(
                                  reaction,
                                  style: TextStyle(fontSize: 50),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ).toList()),
                Visibility(
                  visible: widget.reactions.length != 0,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        constraints: BoxConstraints(maxHeight: 200),
                        child: ListView(
                          shrinkWrap: true,
                          children: _generateReactions(),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
