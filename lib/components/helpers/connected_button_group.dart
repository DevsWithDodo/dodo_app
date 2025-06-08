import 'package:collection/collection.dart';
import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/helpers/curves.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

enum ButtonGroupSize {
  xs,
  s,
  m,
  l,
  xl;
}

enum ButtonGroupShape {
  rounded,
  square;
}

class ConnectedButtonGroup extends HookWidget {
  final List<GroupedButton> children;
  final ButtonGroupSize size;
  final ButtonGroupShape shape;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const ConnectedButtonGroup({
    super.key,
    required this.children,
    required this.size,
    this.shape = ButtonGroupShape.rounded,
    required this.selectedIndex,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      constraints: BoxConstraints(
        maxWidth: 350,
      ),
      child: Row(
        children: children.mapIndexed(
          (index, button) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 4,
                ),
                child: GroupedButton(
                  first: index == 0,
                  last: index == children.length - 1,
                  isSelected: index == selectedIndex,
                  child: button.child,
                  onTap: () => onSelected(index),
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }
}

class GroupedButton extends HookWidget {
  final Widget child;
  final bool first;
  final bool last;
  final bool isSelected;
  final VoidCallback? onTap;

  const GroupedButton({
    super.key,
    required this.child,
    this.first = false,
    this.last = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 300),
      initialValue: isSelected ? 1.0 : 0.0,
    );

    var unselected = BorderRadius.circular(8);
    var pressed = BorderRadius.circular(4);
    final selected = BorderRadius.circular(100);

    useEffect(() {
      controller.animateTo(
        isSelected ? 1.0 : 0.0,
        duration: M3Curves.standardSlowSpatial.duration,
        curve: M3Curves.standardSlowSpatial.curve,
      );
      return null;
    }, [isSelected]);

    final radiusAnim = TweenSequence<BorderRadius?>(
      [
        TweenSequenceItem<BorderRadius?>(
          tween: BorderRadiusTween(begin: unselected, end: pressed),
          weight: 50,
        ),
        TweenSequenceItem<BorderRadius?>(
          tween: BorderRadiusTween(begin: pressed, end: selected),
          weight: 50,
        ),
      ],
    ).animate(controller);

    final textColorAnim = TweenSequence<Color?>(
      [
        TweenSequenceItem<Color?>(
          tween: ColorTween(
            begin: context.colorScheme.onSurface,
            end: isSelected
                ? context.colorScheme.onTertiary
                : context.colorScheme.onSurface,
          ),
          weight: 50,
        ),
        TweenSequenceItem<Color?>(
          tween: ColorTween(
            begin: isSelected
                ? context.colorScheme.onTertiary
                : context.colorScheme.onSurface,
            end: context.colorScheme.onTertiary,
          ),
          weight: 50,
        ),
      ],
    ).animate(controller);

    final backgroundColorAnim = TweenSequence<Color?>(
      [
        TweenSequenceItem<Color?>(
          tween: ColorTween(
            begin: context.colorScheme.surfaceContainerHighest,
            end: isSelected
                ? context.colorScheme.tertiary
                : context.colorScheme.surfaceContainerHighest,
          ),
          weight: 50,
        ),
        TweenSequenceItem<Color?>(
          tween: ColorTween(
            begin: isSelected
                ? context.colorScheme.tertiary
                : context.colorScheme.surfaceContainerHighest,
            end: context.colorScheme.tertiary,
          ),
          weight: 50,
        ),
      ],
    ).animate(controller);

    final borderRadius = useAnimation(radiusAnim)!;
    final textColor = useAnimation(textColorAnim)!;
    final backgroundColor = useAnimation(backgroundColorAnim)!;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: borderRadius),
        onTapDown: (_) {
          controller.animateTo(
            0.5,
            duration: M3Curves.standardFastSpatial.duration,
            curve: M3Curves.standardFastSpatial.curve,
          );
        },
        onTapCancel: () {
          controller.animateTo(
            isSelected ? 1.0 : 0.0,
            duration: M3Curves.standardFastEffect.duration,
            curve: M3Curves.standardFastEffect.curve,
          );
        },
        onTap: () {
          onTap?.call();
          controller.animateTo(
            isSelected ? 1.0 : 0.0,
            duration: M3Curves.standardSlowSpatial.duration,
            curve: M3Curves.standardSlowSpatial.curve,
          );
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              iconTheme: IconThemeData(
                size: 18,
                color: textColor,
              ),
            ),
            child: DefaultTextStyle(
              style: context.textTheme.labelLarge!.copyWith(
                color: textColor,
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
