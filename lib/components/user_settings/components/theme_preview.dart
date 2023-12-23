import 'dart:async';

import 'package:csocsort_szamla/components/balance/balances.dart';
import 'package:csocsort_szamla/components/purchase/purchase_entry.dart';
import 'package:csocsort_szamla/components/shopping/shopping_list_entry.dart';
import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/helpers/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/user_settings_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class ThemePreview extends StatefulWidget {
  const ThemePreview({required this.themeName, required this.offset, super.key});

  final ThemeName themeName;
  final Offset offset;

  static final List<Member> _members = [
    Member(id: 1, username: 'theme-preview.member.1'.tr(), balance: 50),
    Member(id: 2, username: 'theme-preview.member.2'.tr(), balance: 0),
    Member(id: 3, username: 'theme-preview.member.3'.tr(), balance: -50),
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
  State<ThemePreview> createState() => _ThemePreviewState();
}

class _ThemePreviewState extends State<ThemePreview> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _left;
  late Animation<double> _top;
  late Animation<double> _animationValue;
  late Animation<double> _borderRadius;

  late StreamSubscription _shouldHide;

  double _paddingHorizontal = 16;
  double _paddingVertical = 10;

  late final double _maxHeight;
  late final double _maxWidth;

  @override
  void initState() {
    super.initState();
    final screenSize = context.read<ScreenSize>();
    _controller = AnimationController(duration: Duration(milliseconds: 400), reverseDuration: Duration(milliseconds: 200), vsync: this)
      ..addListener(() => setState(() {}));

    _maxHeight = screenSize.height - 2 * _paddingVertical;
    _maxWidth = min(screenSize.width - 2 * _paddingHorizontal, 500);
    if (screenSize.width - 2 * _paddingHorizontal > 500) {
      _paddingHorizontal = (screenSize.width - 500) / 2;
    }

    final animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _left = Tween<double>(begin: widget.offset.dx, end: _paddingHorizontal).animate(animation);
    _top = Tween<double>(begin: widget.offset.dy, end: _paddingVertical + screenSize.padding.top).animate(animation);
    _animationValue = Tween<double>(begin: 0, end: 1).animate(animation);
    _borderRadius = Tween<double>(begin: 100, end: 15).animate(animation);

    _controller.forward();

    _shouldHide = context.read<StackWidgetState>().hide.listen((shouldHide) {
      if (shouldHide) {
        if (_controller.isAnimating) {
          _controller.stop();
        }
        _controller.reverse().then((_) => context.read<StackWidgetState>().setWidget(null));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _shouldHide.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _top.value,
      left: _left.value,
      child: Theme(
        data: AppTheme.getTheme(widget.themeName),
        child: ChangeNotifierProvider(
            create: (context) => AppThemeState(widget.themeName),
            builder: (context, _) {
              return Stack(
                children: [
                  Container(
                    width: _maxWidth * _animationValue.value,
                    height: _maxHeight * _animationValue.value,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_borderRadius.value),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: _maxWidth * _animationValue.value < 250
                        ? SizedBox()
                        : SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'balances'.tr(),
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        SizedBox(height: 15),
                                        ...ThemePreview._members.map(
                                          (member) => BalanceMemberEntry(
                                            member: member,
                                            selectedCurrency: context.watch<UserState>().currentGroup!.currency,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'purchases'.tr(),
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        SizedBox(height: 15),
                                        ...ThemePreview._purchases.map((purchase) => PurchaseEntry(
                                            purchase: purchase, selectedMemberId: ThemePreview._members[0].id))
                                      ],
                                    ),
                                  ),
                                ),
                                Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'shopping_list'.tr(),
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        SizedBox(height: 15),
                                        ...ThemePreview._requests.map(
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
                  ),
                  GestureDetector(
                    onTap: () => context.read<StackWidgetState>().hideWidget(),
                    child: Container(
                      // Container to block tapping on examples
                      width: _maxWidth,
                      height: _maxHeight,
                      color: Colors.transparent,
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }
}
