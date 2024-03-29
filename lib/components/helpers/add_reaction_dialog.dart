import 'dart:math';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../helpers/app_theme.dart';
import '../../helpers/models.dart';
import '../../helpers/http.dart';

enum ReactionType {
  purchase("purchases", "purchase"),
  payment("payments", "payment"),
  request("requests", "request");

  const ReactionType(this.path, this.reactsTo);
  final String path;
  final String reactsTo;
}

class AddReactionDialog extends StatelessWidget {
  final ReactionType type;
  final List<Reaction> reactions;
  final int reactToId;
  final Function(String reaction, int userId) onSend;
  AddReactionDialog({
    required this.type,
    required this.reactions,
    required this.reactToId,
    required this.onSend,
  });

  Future<bool> _sendReaction(String reaction) async {
    try {
      Map<String, dynamic> body = {type.reactsTo + "_id": reactToId, "reaction": reaction};
      await Http.post(uri: '/${type.path}/reaction', body: body);
      return true;
    } catch (_) {
      throw _;
    }
  }

  List<Widget> _generateReactions(BuildContext context) {
    ThemeName themeName = context.watch<AppThemeState>().themeName;
    User user = context.read<UserState>().user!;
    return reactions.map((e) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: EdgeInsets.fromLTRB(4, 0, 4, 4),
        decoration: BoxDecoration(
          gradient: e.userId == user.id
              ? AppTheme.gradientFromTheme(themeName, useSecondaryContainer: true)
              : LinearGradient(colors: [Colors.transparent, Colors.transparent]),
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
                        color: themeName.type == ThemeType.gradient
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSecondaryContainer)
                    : Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
    print('add_reaction_dialog.dart: ');
    return Selector<UserState, int>(
      selector: (_, userProvider) => userProvider.user!.id,
      builder: (context, userId, _) {
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'reactions'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: Reaction.possibleReactions
                          .map(
                            (reaction) => InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                _sendReaction(reaction);
                                Navigator.pop(context);
                                this.onSend(reaction, userId);
                              },
                              child: Ink(
                                padding: EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: reactions.firstWhereOrNull(
                                              (el) => el.userId == userId && el.reaction == reaction) !=
                                          null
                                      ? Theme.of(context).colorScheme.secondaryContainer
                                      : Colors.transparent,
                                ),
                                child: Container(
                                  constraints:
                                      BoxConstraints(maxWidth: min(50, MediaQuery.of(context).size.width / 2 / 6)),
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
                          )
                          .toList()),
                  Visibility(
                    visible: reactions.length != 0,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          constraints: BoxConstraints(maxHeight: 200),
                          child: ListView(
                            shrinkWrap: true,
                            children: _generateReactions(context),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
