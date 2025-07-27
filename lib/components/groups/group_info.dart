import 'dart:convert';

import 'package:csocsort_szamla/components/groups/dialogs/rename_group_dialog.dart';
import 'package:csocsort_szamla/components/groups/member_all_info.dart';
import 'package:csocsort_szamla/components/helpers/background_paint.dart';
import 'package:csocsort_szamla/components/helpers/confirm_choice_dialog.dart';
import 'package:csocsort_szamla/components/helpers/error_message.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/main/dialogs/iapp_not_supported_dialog.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/join_group_page.dart';
import 'package:csocsort_szamla/pages/app/store_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class GroupInfo extends StatefulWidget {
  const GroupInfo({
    super.key,
  });

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  Future<bool>? _isUserAdmin;
  Future<Map<String, dynamic>>? _boostNumber;

  Future<bool> _getIsUserAdmin() async {
    try {
      Response response = await Http.get(
        uri: generateUri(GetUriKeys.groupMember, context),
        useCache: false,
      );
      Map<String, dynamic> decoded = jsonDecode(response.body);
      return decoded['data']['is_admin'] == 1;
    } catch (_) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getBoostNumber() async {
    try {
      Response response = await Http.get(
        uri: generateUri(
          GetUriKeys.groupBoost,
          context,
          params: [context.read<UserNotifier>().user!.group!.id.toString()],
        ),
        useCache: false,
      );
      Map<String, dynamic> decoded = jsonDecode(response.body);
      return decoded['data'];
    } catch (_) {
      rethrow;
    }
  }

  Future<BoolFutureOutput> _postBoost() async {
    try {
      await Http.post(
        uri: '/groups/${context.read<UserNotifier>().user!.group!.id}/boost',
      );
      return BoolFutureOutput.True;
    } catch (_) {
      rethrow;
    }
  }

  Future<LeftOrRemovedFromGroupFutureOutput> _deleteGroup() async {
    try {
      await Http.delete(
        uri: '/groups/${context.read<UserNotifier>().user!.group!.id}',
      );
      if (mounted) {
        UserNotifier provider = context.read<UserNotifier>();
        if (provider.user!.groups.length > 1) {
          provider.setGroups(provider.user!.groups.where((group) => group.id != provider.user!.group!.id).toList());
          provider.setGroup(provider.user!.groups.first);
          return LeftOrRemovedFromGroupFutureOutput.leftHasOtherGroup;
        }
      }
      return LeftOrRemovedFromGroupFutureOutput.leftNoOtherGroup;
    } catch (_) {
      rethrow;
    }
  }

  void onTapStore() async {
    if (context.read<AppConfig>().isIAPPlatformEnabled) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StorePage()),
      );
      EventBus.instance.fire(EventBus.refreshGroupInfo);
    } else {
      showDialog(
        context: context,
        builder: (context) => IAPNotSupportedDialog(),
      );
    }
  }

  void onRefreshGroupInfoEvent() {
    setState(() {
      _isUserAdmin = _getIsUserAdmin();
      _boostNumber = _getBoostNumber();
    });
  }

  @override
  void initState() {
    super.initState();
    _isUserAdmin = _getIsUserAdmin();
    _boostNumber = _getBoostNumber();
    EventBus.instance.register(EventBus.refreshGroupInfo, onRefreshGroupInfoEvent);
  }

  @override
  void dispose() {
    EventBus.instance.unregister(EventBus.refreshGroupInfo, onRefreshGroupInfoEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<UserNotifier>().user!.group!;
    return CardWithBackground(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text('group-info'.tr(), style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 10),
            FutureBuilder(
              future: _isUserAdmin,
              builder: (context, adminSnapshot) {
                return FutureBuilder(
                  future: _boostNumber,
                  builder: (context, boostSnapshot) {
                    if (adminSnapshot.connectionState != ConnectionState.done ||
                        boostSnapshot.connectionState != ConnectionState.done) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (adminSnapshot.hasError || boostSnapshot.hasError) {
                      return ErrorMessage(
                          error: (adminSnapshot.error ?? boostSnapshot.error).toString(),
                          onTap: () {
                            setState(() {
                              _isUserAdmin = _getIsUserAdmin();
                              _boostNumber = _getBoostNumber();
                            });
                          });
                    }
                    final bool isBoosted = boostSnapshot.data!['is_boosted'] == 1;
                    final int boostsAvailable = boostSnapshot.data!['available_boosts'];
                    final bool isAdmin = adminSnapshot.data!;

                    final TapGestureRecognizer recognizer = TapGestureRecognizer();
                    recognizer.onTap = onTapStore;
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: RichText(
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.labelLarge,
                                  children: [
                                    TextSpan(text: '${'group-info.name'.tr()}: '),
                                    TextSpan(
                                      text: group.name,
                                      style:
                                          Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isAdmin)
                              IconButton.filledTonal(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(Icons.edit),
                                onPressed: () => showDialog(
                                  builder: (context) => RenameGroupDialog(),
                                  context: context,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.labelLarge,
                                  children: [
                                    TextSpan(text: '${'group-info.currency'.tr()}: '),
                                    TextSpan(
                                      text: "${group.currency.code}(${group.currency.symbol})",
                                      style:
                                          Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: Theme.of(context).textTheme.labelLarge,
                                      children: [
                                        TextSpan(text: '${'group-info.boosted'.tr()}: '),
                                        TextSpan(
                                          text: isBoosted ? 'yes'.tr() : 'no'.tr(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge!
                                              .copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (!isBoosted)
                                  IconButton.filledTonal(
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(Icons.insights),
                                    onPressed: boostsAvailable == 0
                                        ? () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => StorePage(),
                                              ),
                                            ).then((value) {
                                              setState(() {
                                                _boostNumber = _getBoostNumber();
                                              });
                                            })
                                        : () {
                                            showDialog(
                                                    builder: (context) => ConfirmChoiceDialog(
                                                          choice: 'sure_boost',
                                                        ),
                                                    context: context)
                                                .then((value) {
                                              if ((value ?? false)) {
                                                showFutureOutputDialog(
                                                    future: _postBoost(),
                                                    context: context,
                                                    outputCallbacks: {
                                                      BoolFutureOutput.True: () async {
                                                        await clearGroupCache(context);
                                                        EventBus.instance.fire(EventBus.refreshStatistics);
                                                        EventBus.instance.fire(EventBus.refreshGroupInfo);
                                                        Navigator.pop(context);
                                                      }
                                                    });
                                              }
                                            });
                                          },
                                  ),
                              ],
                            ),
                            if (!isBoosted)
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: DefaultTextStyle(
                                  style: Theme.of(context).textTheme.bodySmall!,
                                  textAlign: TextAlign.center,
                                  child: Column(
                                    children: [
                                      Text(
                                        'group-info.boosted.perks'.tr(),
                                      ),
                                      if (boostsAvailable != 0)
                                        Text(
                                          'group-info.boosted.boosts-available'.tr(args: [boostsAvailable.toString()]),
                                        ),
                                      if (boostsAvailable == 0)
                                        RichText(
                                          text: TextSpan(
                                            style: Theme.of(context).textTheme.bodySmall,
                                            children: [
                                              TextSpan(
                                                text: '${'group-info.boosted.no-boosts'.tr()} ',
                                              ),
                                              TextSpan(
                                                text: 'group-info.boosted.no-boosts.store'.tr(),
                                                style: TextStyle(
                                                    color: Theme.of(context).colorScheme.primary,
                                                    fontWeight: FontWeight.bold),
                                                recognizer: recognizer,
                                              )
                                            ],
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.error,
                                foregroundColor: Theme.of(context).colorScheme.onError),
                            icon: Icon(Icons.delete_forever),
                            label: Text('group-info.delete-group'.tr()),
                            onPressed: () async {
                              final value = await showDialog<bool>(
                                context: context,
                                builder: (context) => ConfirmChoiceDialog(
                                  choice: 'group-info.delete-group.explanation'.tr(),
                                ),
                              );

                              if ((value ?? false)) {
                                showFutureOutputDialog(
                                  future: _deleteGroup(),
                                  context: context,
                                  outputCallbacks: {
                                    LeftOrRemovedFromGroupFutureOutput.leftHasOtherGroup: () async {
                                      Navigator.pop(context);
                                      final bus = EventBus.instance;
                                      bus.fire(EventBus.refreshBalances);
                                      bus.fire(EventBus.refreshGroups);
                                      bus.fire(EventBus.refreshPurchases);
                                      bus.fire(EventBus.refreshPayments);
                                      bus.fire(EventBus.refreshShopping);
                                      bus.fire(EventBus.refreshGroupInfo);
                                    },
                                    LeftOrRemovedFromGroupFutureOutput.leftNoOtherGroup: () async {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (context) => JoinGroupPage(
                                            fromAuth: true,
                                          ),
                                        ),
                                        (r) => false,
                                      );
                                      UserNotifier provider = context.read<UserNotifier>();
                                      provider.setGroups([]);
                                      provider.setGroup(null);
                                      clearAllCache();
                                    }
                                  },
                                );
                              }
                            },
                          ),
                        ]
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
