import 'package:flutter/material.dart';

class BorderShimmer extends StatefulWidget {
  final double borderWidth;
  final List<Color> gradientColors;
  final Duration duration;

  const BorderShimmer({
    super.key,
    this.borderWidth = 20,
    required this.gradientColors,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<BorderShimmer> createState() => _BorderShimmerState();
}

class _BorderShimmerState extends State<BorderShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ShimmerGlowPainter(
            progress: _controller.value,
            borderWidth: widget.borderWidth,
            colors: widget.gradientColors,
          ),
        );
      },
    );
  }
}

class _ShimmerGlowPainter extends CustomPainter {
  final double progress;
  final double borderWidth;
  final List<Color> colors;

  _ShimmerGlowPainter({
    required this.progress,
    required this.borderWidth,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final Paint glowPaint = Paint()
      ..shader = _createGlowShader(rect)
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, borderWidth / 2)
      ..strokeWidth = borderWidth / 2 + progress * borderWidth / 2;

    canvas.drawRect(rect, glowPaint);
  }

  Shader _createGlowShader(Rect rect) {
    return SweepGradient(
      transform: GradientRotation(progress * 2 * 3.14),
      colors: colors,
    ).createShader(rect);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
