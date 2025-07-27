import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:flutter/material.dart';

class RainbowPainter extends CustomPainter {
  RainbowPainter({required this.themeName});
  final ThemeName themeName;

  @override
  void paint(Canvas canvas, Size size) {
    final theme = AppTheme.themes[themeName]!;
    final numColors = AppTheme.gradientColors[themeName]?.length ?? 0;
    if (numColors < 2) {
      return;
    }
    final gradient = LinearGradient(
      colors: AppTheme.gradientColors[themeName]!.map((color) => color.withValues(alpha: 0.5)).toList(),
      // begin: Alignment.topLeft,
      // end: Alignment.bottomRight,
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
