import 'dart:math' as math;

import 'package:flutter/material.dart';

class CircleCheckAnimation extends StatefulWidget {
  final double size;
  final Duration duration;
  final Color color;
  final double strokeWidth;
  final Curve curve;

  const CircleCheckAnimation({
    super.key,
    this.size = 100.0,
    this.duration = const Duration(milliseconds: 800),
    this.color = Colors.green,
    this.strokeWidth = 4.0,
    this.curve = Curves.easeInOut,
  });

  @override
  State<CircleCheckAnimation> createState() => _CircleCheckAnimationState();
}

class _CircleCheckAnimationState extends State<CircleCheckAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void startAnimation() {
    if (_controller.status != AnimationStatus.forward &&
        _controller.status != AnimationStatus.completed) {
      _controller.forward(from: 0.0);
    }
  }

  void resetAnimation() {
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    // Example usage: Tap to animate
    return GestureDetector(
      onTap: startAnimation,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CircleCheckPainter(
              progress: _animation.value,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _CircleCheckPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;
  final double strokeWidth;

  _CircleCheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round; // Makes lines look smoother

    // --- Circle Animation ---
    // Start from top (-pi/2) and go clockwise
    double circleSweepAngle = math.pi * 2 * progress;
    canvas.drawArc(rect, -math.pi / 2, circleSweepAngle, false, paint);

    final checkCenter = center + Offset(-radius * 0.05, 0);

    // --- Checkmark Animation ---
    // Define checkmark points relative to the center
    // Adjust these factors to change the checkmark's shape and position
    final p1 =
        checkCenter + Offset(-radius * 0.38, radius * 0.08); // Start point
    final p2 = checkCenter +
        Offset(-radius * 0.1, radius * 0.35); // Middle point (corner)
    final p3 = checkCenter + Offset(radius * 0.5, -radius * 0.3); // End point

    // Calculate lengths of the two checkmark segments
    final len1 = (p2 - p1).distance;
    final len2 = (p3 - p2).distance;
    final totalCheckLength = len1 + len2;

    // Calculate how much of the checkmark to draw based on progress
    final currentCheckLength = totalCheckLength * progress;

    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    if (currentCheckLength <= len1) {
      // Draw part of the first segment
      final ratio = currentCheckLength / len1;
      final currentP = Offset.lerp(p1, p2, ratio)!;
      path.lineTo(currentP.dx, currentP.dy);
    } else {
      // Draw the full first segment
      path.lineTo(p2.dx, p2.dy);
      // Draw part of the second segment
      final remainingLength = currentCheckLength - len1;
      final ratio = remainingLength / len2;
      final currentP = Offset.lerp(p2, p3, ratio)!;
      path.lineTo(currentP.dx, currentP.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CircleCheckPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
