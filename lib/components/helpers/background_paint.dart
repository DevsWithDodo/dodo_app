import 'dart:math';

import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/painters/random_image_painter.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class BackgroundPaint extends HookWidget {
  const BackgroundPaint({super.key, required this.child, this.imageCount = 10});
  final int imageCount;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appThemeState = context.watch<AppThemeState>();
    final backgroundImages = AppTheme.backgroundImages[appThemeState.themeName]!;
    final paintIndex = useState(Random().nextInt(5));
    return backgroundImages.isEmpty
        ? child
        : CustomPaint(
            painter: RandomImagePainter(images: backgroundImages, paintIndex: paintIndex.value),
            child: child,
          );
  }
}

class CardWithBackground extends StatelessWidget {
  const CardWithBackground({super.key, required this.child, this.margin});
  final EdgeInsetsGeometry? margin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: margin,
      child: BackgroundPaint(
        child: child,
      ),
    );
  }
}
