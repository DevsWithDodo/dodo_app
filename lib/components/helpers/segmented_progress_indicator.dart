import 'package:flutter/material.dart';

class SegmentedCircularProgressIndicator extends StatelessWidget {
  final Color color;
  final int numSegments;
  final int activeSegments;
  final Color inactiveColor;

  const SegmentedCircularProgressIndicator({super.key, 
    required this.color,
    required this.numSegments,
    required this.activeSegments,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < numSegments; i++) _buildSegment(i),
        ],
      ),
    );
  }

  Widget _buildSegment(int index) {
    double gapAngle = 7.5; // Narrow transparent arc in degrees
    double segmentAngle = 360 / numSegments;
    double startAngle = segmentAngle * index + gapAngle / 2;
    bool isActive = index < activeSegments;

    return Transform.rotate(
      angle: startAngle * (3.14159265359 / 180), // Convert to radians
      child: Align(
        alignment: Alignment.topCenter,
        child: CustomPaint(
          size: Size(100, 100),
          painter: ArcPainter(
            color: isActive ? color : inactiveColor,
            startAngle: 0,
            sweepAngle: (segmentAngle - gapAngle) * (3.14159265359 / 180),
          ),
        ),
      ),
    );
  }
}

class ArcPainter extends CustomPainter {
  final Color color;
  final double startAngle;
  final double sweepAngle;

  ArcPainter({
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - 2,
    );

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
