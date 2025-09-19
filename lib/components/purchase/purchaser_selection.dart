import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/components/helpers/measure_size.dart';
import 'package:csocsort_szamla/helpers/curves.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class PurchaserSelection extends HookWidget {
  final List<Member> members;
  final int purchaserId;
  final void Function(int) onPurchaserChanged;
  const PurchaserSelection({
    super.key,
    required this.members,
    required this.purchaserId,
    required this.onPurchaserChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState<bool>(false);

    final chipWidths = useState<Map<int, double>?>(null);
    final cumulativeChipWidths = useMemoized(() {
      if (chipWidths.value == null || chipWidths.value!.length < members.length) return null;
      final sortedWidths =
          chipWidths.value!.entries.sorted((a, b) => a.key.compareTo(b.key)).map((e) => e.value).toList();
      var cumulative = 0.0;
      var widths = <double>[];
      for (var width in sortedWidths) {
        widths.add(cumulative);
        cumulative += width;
        cumulative += 8; // Add padding between chips.
      }
      return widths;
    }, [chipWidths.value]);

    final stackOrderedIndices = useMemoized(
      () {
        // First 0 to selectedIndex - 1, then end to selectedIndex, then selectedIndex.
        List<int> ordered = [];
        final selectedIndex = members.indexWhere((m) => m.id == purchaserId);
        for (int i = 0; i < selectedIndex; i++) {
          ordered.add(i);
        }
        for (int i = members.length - 1; i > selectedIndex; i--) {
          ordered.add(i);
        }
        ordered.add(selectedIndex);
        return ordered;
      },
      [purchaserId, members.length],
    );

    final newSelctedId = useState(purchaserId);

    final actualSelectedIndex =
        useMemoized(() => members.indexWhere((m) => m.id == newSelctedId.value), [newSelctedId.value, members]);

    final scrollController = useScrollController();

    final keys =
        useMemoized<List<GlobalKey>>(() => List.generate(members.length, (_) => GlobalKey()), [members.length]);

    final controller = useAnimationController(
      duration: M3Curves.expressiveDefaultSpatial.duration,
    );
    final animationValue = useAnimation<double>(controller);
    final curvedAnimationValue =
        useMemoized(() => M3Curves.expressiveDefaultSpatial.curve.transform(animationValue), [animationValue]);
    final scrollAnimationInProgress = useState(false);

    Future animateToIndex(int index, [bool jump = false]) async {
      if (members.isEmpty || // Guard for empty members list
          chipWidths.value == null ||
          chipWidths.value!.length != members.length || // Ensure all widths are measured
          cumulativeChipWidths == null ||
          index < 0 ||
          index >= members.length ||
          chipWidths.value![index] == null ||
          chipWidths.value![0] == null || // Ensure first chip width is available
          chipWidths.value![members.length - 1] == null) {
        // Ensure last chip width is available
        return;
      }
      if (!scrollController.hasClients) return;

      final keyContext = keys[index].currentContext;
      if (keyContext != null) {
        final viewportWidth = scrollController.position.viewportDimension;
        final firstChipWidth = chipWidths.value![0]!;

        final calculatedPaddingStart = viewportWidth / 2 - (firstChipWidth / 2);
        final effectivePaddingStart = max(0.0, calculatedPaddingStart);

        final chipTargetLeftInStack = cumulativeChipWidths[index];
        final chipTargetWidth = chipWidths.value![index]!;
        final chipTargetCenterInStack = chipTargetLeftInStack + chipTargetWidth / 2;

        final targetScrollOffset = effectivePaddingStart + chipTargetCenterInStack - (viewportWidth / 2) + 5;
        scrollAnimationInProgress.value = true;
        if (jump) {
          scrollController.jumpTo(targetScrollOffset);
          scrollAnimationInProgress.value = false;
          return;
        }
        await scrollController.animateTo(
          targetScrollOffset,
          duration: M3Curves.expressiveFastSpatial.duration,
          curve: M3Curves.expressiveFastSpatial.curve,
        );
        scrollAnimationInProgress.value = false;
      }
    }

    useEffect(() {
      if (newSelctedId.value != purchaserId) {
        newSelctedId.value = purchaserId;
        animateToIndex(members.indexWhere((m) => m.id == purchaserId)).then((_) {
          if (isExpanded.value) {
            controller.forward();
          }
        });
      }
    }, [purchaserId]);

    useEffect(() {
      if (chipWidths.value == null ||
          chipWidths.value!.length != members.length ||
          cumulativeChipWidths == null ||
          members.isEmpty) {
        return null; //
      }

      final targetIndex = members.indexWhere((m) => m.id == purchaserId);
      if (targetIndex == -1) {
        return null;
      }
      if (newSelctedId.value != purchaserId) {
        newSelctedId.value = purchaserId;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          animateToIndex(targetIndex, true);
        }
      });

      return null;
    }, [
      purchaserId,
      members,
      chipWidths.value,
      cumulativeChipWidths,
    ]);

    void toggleExpand() async {
      if (isExpanded.value) {
        await animateToIndex(actualSelectedIndex);
        controller.reverse();
        isExpanded.value = false;
      } else {
        controller.forward();
        isExpanded.value = true;
      }
    }

    void onChipTapped(int idx) {
      final chosenId = members[idx].id;
      newSelctedId.value = chosenId;
      animateToIndex(idx).then((_) {
        if (chosenId == purchaserId) {
          toggleExpand();
          return;
        }

        controller.reverse().whenComplete(() {
          isExpanded.value = false;
        });
        onPurchaserChanged(members[idx].id);
      });
    }

    if (chipWidths.value == null || chipWidths.value!.length != members.length) {
      return Opacity(
        opacity: 0,
        child: Row(
          children: members.mapIndexed(
            (index, member) {
              final isSelected = member.id == purchaserId;
              return MeasureSize(
                onChange: (size) {
                  // Store the width of each chip in a map.
                  chipWidths.value ??= {};
                  chipWidths.value = {
                    ...chipWidths.value!,
                    index: size.width,
                  };
                },
                child: ChoiceChip(
                  label: Text(member.nickname),
                  selected: isSelected,
                  showCheckmark: false,
                  onSelected: (_) => onChipTapped(members.indexOf(member)),
                ),
              );
            },
          ).toList(),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'from_who'.tr(),
          style: context.textTheme.labelLarge,
        ),
        Expanded(
          child: SizedBox(
            height: 50,
            child: LayoutBuilder(builder: (context, constraints) {
              final viewportWidth = constraints.maxWidth;
              final actualContentWidth = cumulativeChipWidths!.last + chipWidths.value![members.length - 1]!;

              final firstChipWidth = chipWidths.value![0]!;
              final lastChipWidth = chipWidths.value![members.length - 1]!;

              final paddingStart = viewportWidth / 2 - (firstChipWidth / 2);
              final paddingEnd = viewportWidth / 2 - (lastChipWidth / 2);
              // + 5 such that when animating to the middle, there is no off by a bit error resulting in jumping
              final effectivePaddingStart = max(0.0, paddingStart) + 5;
              final effectivePaddingEnd = max(0.0, paddingEnd) + 5;
              return SizedBox(
                width: constraints.maxWidth,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics:
                      animationValue != 1 || scrollAnimationInProgress.value ? NeverScrollableScrollPhysics() : null,
                  controller: scrollController,
                  child: Row(
                    children: [
                      SizedBox(width: effectivePaddingStart),
                      SizedBox(
                        width: actualContentWidth,
                        child: Stack(
                          children: stackOrderedIndices.map((orderedIndex) {
                            final member = members[orderedIndex];
                            final bool isTheSelectedChip = orderedIndex == actualSelectedIndex;

                            final double initialX = cumulativeChipWidths[actualSelectedIndex];
                            final double targetX = cumulativeChipWidths[orderedIndex];
                            final double currentX = lerpDouble(initialX, targetX, curvedAnimationValue) ?? targetX;

                            final double opacity =
                                isTheSelectedChip ? 1.0 : lerpDouble(0.0, 1.0, curvedAnimationValue)!;
                            return Positioned(
                              key: keys[orderedIndex],
                              left: currentX,
                              child: Opacity(
                                opacity: min(max(0, opacity), 1),
                                child: ChoiceChip(
                                  label: Text(member.nickname),
                                  selected: member.id == newSelctedId.value,
                                  selectedColor: context.colorScheme.primaryContainer,
                                  labelStyle: context.textTheme.labelLarge!.copyWith(
                                    color: member.id == newSelctedId.value
                                        ? context.colorScheme.onPrimaryContainer
                                        : context.colorScheme.onSurface,
                                  ),
                                  showCheckmark: false,
                                  onSelected: (animationValue == 1.0 || (animationValue == 0.0 && isTheSelectedChip))
                                      ? (_) => onChipTapped(orderedIndex)
                                      : (_) {},
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(width: effectivePaddingEnd),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        IconButton(
          iconSize: 28,
          icon: AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            child: isExpanded.value ? Icon(Icons.arrow_drop_up) : Icon(Icons.arrow_drop_down),
          ),
          onPressed: toggleExpand,
        ),
      ],
    );

    // final showSelection = useState(false);
    // final scrollController = useScrollController();
    // final chipKeys = useMemoized(() => {for (var member in members) member.id: GlobalKey()});

    // return Row(
    //   crossAxisAlignment: CrossAxisAlignment.center,
    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //   children: [
    //     Text(
    //       'from_who'.tr(),
    //       style: Theme.of(context).textTheme.labelLarge,
    //     ),
    //     Expanded(
    //       child: Center(
    //         child: AnimatedCrossFade(
    //           duration: Duration(milliseconds: 300),
    //           reverseDuration: Duration(seconds: 300),
    //           crossFadeState: showSelection.value ? CrossFadeState.showSecond : CrossFadeState.showFirst,
    //           firstChild: Chip(
    //             label: Text(
    //               members.firstWhere((element) => element.id == purchaserId).nickname,
    //               style: Theme.of(context).textTheme.labelLarge!.copyWith(
    //                     color: Theme.of(context).colorScheme.onSecondaryContainer,
    //                   ),
    //             ),
    //             backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    //           ),
    //           secondChild: SingleChildScrollView(
    //             scrollDirection: Axis.horizontal,
    //             controller: scrollController,
    //             child: Row(
    //               children: members
    //                   .mapIndexed(
    //                     (index, member) => Padding(
    //                       padding: EdgeInsets.only(left: 8),
    //                       child: ChoiceChip(
    //                         key: chipKeys[member.id],
    //                         label: Text(
    //                           member.nickname,
    //                           style: context.textTheme.labelLarge!.copyWith(
    //                             color: purchaserId == member.id
    //                                 ? context.colorScheme.onSecondaryContainer
    //                                 : context.colorScheme.onSurface,
    //                           ),
    //                         ),
    //                         backgroundColor: purchaserId == member.id
    //                             ? context.colorScheme.secondaryContainer
    //                             : context.colorScheme.surface,
    //                         showCheckmark: false,
    //                         onSelected: (selected) {
    //                           if (selected) {
    //                             onPurchaserChanged(member.id);
    //                             showSelection.value = false;
    //                           }
    //                         },
    //                         selected: purchaserId == member.id,
    //                       ),
    //                     ),
    //                   )
    //                   .toList(),
    //             ),
    //           ),
    //         ),
    //       ),
    //     ),
    //     IconButton(
    //       onPressed: () => showSelection.value = !showSelection.value,
    //       icon: Icon(
    //         showSelection.value ? Icons.arrow_drop_up : Icons.arrow_drop_down,
    //         color: showSelection.value
    //             ? Theme.of(context).colorScheme.primary
    //             : Theme.of(context).colorScheme.onSurfaceVariant,
    //       ),
    //     ),
    //   ],
    // );
  }
}
