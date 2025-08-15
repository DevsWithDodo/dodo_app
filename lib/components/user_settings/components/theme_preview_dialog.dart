import 'package:csocsort_szamla/components/balance/balances.dart';
import 'package:csocsort_szamla/components/helpers/background_paint.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/purchase/purchase_entry.dart';
import 'package:csocsort_szamla/components/shopping/shopping_list_entry.dart';
import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemePreviewDialog extends StatelessWidget {
  final ThemeName themeName;
  final VoidCallback onThemeSelected;
  const ThemePreviewDialog({super.key, required this.themeName, required this.onThemeSelected});

  static final List<Member> _members = [
    Member(id: 1, nickname: 'theme-preview.member.1'.tr(), balance: 50),
    Member(id: 2, nickname: 'theme-preview.member.2'.tr(), balance: 0),
    Member(id: 3, nickname: 'theme-preview.member.3'.tr(), balance: -50),
  ];

  static final List<Purchase> _purchases = [
    Purchase.example('theme-preview.purchase.1'.tr(), 15, Currency.fromCode('EUR'), _members[0], _members),
    Purchase.example('theme-preview.purchase.2'.tr(), 10, Currency.fromCode('USD'), _members[1], _members),
    Purchase.example(
        'theme-preview.purchase.3'.tr(), 25, Currency.fromCode('EUR'), _members[0], [_members[1], _members[2]]),
  ];

  static final List<ShoppingRequest> _requests = [
    ShoppingRequest(
      id: 1,
      name: 'theme-preview.request.1'.tr(),
      requesterId: _members[0].id,
      requesterNickname: _members[0].nickname,
      updatedAt: DateTime.now(),
      reactions: [],
    ),
    ShoppingRequest(
      id: 2,
      name: 'theme-preview.request.2'.tr(),
      requesterId: _members[1].id,
      requesterNickname: _members[1].nickname,
      updatedAt: DateTime.now(),
      reactions: [],
    ),
    ShoppingRequest(
      id: 3,
      name: 'theme-preview.request.3'.tr(),
      requesterId: _members[2].id,
      requesterNickname: _members[2].nickname,
      updatedAt: DateTime.now(),
      reactions: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.getTheme(themeName),
      child: ChangeNotifierProvider(
        create: (context) => AppThemeState(themeName),
        builder: (context, child) => Dialog(
          insetPadding: const EdgeInsets.all(15),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    'theme-preview.dialog.title'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CardWithBackground(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'balances'.tr(),
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                          SizedBox(height: 25),
                                          ..._members.map(
                                            (member) => Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: BalanceMemberEntry(
                                                member: member,
                                                selectedCurrency: context.watch<UserNotifier>().currentGroup!.currency,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  CardWithBackground(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'purchases'.tr(),
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                          SizedBox(height: 25),
                                          ..._purchases.map((purchase) =>
                                              PurchaseEntry(purchase: purchase, selectedMemberId: _members[0].id))
                                        ],
                                      ),
                                    ),
                                  ),
                                  CardWithBackground(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'shopping_list'.tr(),
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                          SizedBox(height: 25),
                                          ..._requests.map(
                                            (request) => ShoppingListEntry(
                                              shoppingRequest: request,
                                              onDeleteRequest: (_) {},
                                              onEditRequest: (_) {},
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned.fill(
                                child: Container(
                              decoration: BoxDecoration(color: Colors.transparent),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('theme-preview.dialog.close'.tr()),
                    ),
                    GradientButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onThemeSelected();
                      },
                      child: Text('theme-preview.dialog.apply'.tr()),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
