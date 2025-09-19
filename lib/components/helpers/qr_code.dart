import 'dart:math';

import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:qr/qr.dart' as qr;

enum RasterizedShapeType {
  square(2, 2),
  lineVerticalLong(1, 3),
  lineHorizontalLong(3, 1),
  lineVerticalShort(1, 2),
  lineHorizontalShort(2, 1),
  dot(1, 1);

  final int width;
  final int height;
  int get numVariations => switch (this) {
        RasterizedShapeType.square => 2,
        RasterizedShapeType.lineVerticalLong => 1,
        RasterizedShapeType.lineHorizontalLong => 1,
        RasterizedShapeType.lineVerticalShort => 1,
        RasterizedShapeType.lineHorizontalShort => 1,
        RasterizedShapeType.dot => 3,
      };
  const RasterizedShapeType(this.width, this.height);
}

class RasterizedShape {
  final RasterizedShapeType type;
  final Offset position;
  final int variation;
  final bool usePrimary;

  RasterizedShape({required this.type, required this.position, required this.variation, required this.usePrimary});
}

class EmptyShape {
  final Offset position;
  final int variation;
  final double colorOffset = Random().nextDouble() * 0.1;

  EmptyShape({required this.position, required this.variation});
}

class GreedyRasterizer {
  final List<List<bool>> matrix;
  final int rows;
  final int cols;
  late List<List<bool>> visited;

  GreedyRasterizer(this.matrix)
      : rows = matrix.length,
        cols = matrix.isNotEmpty ? matrix[0].length : 0 {
    visited = List.generate(rows, (_) => List.filled(cols, false));
  }

  (List<RasterizedShape>, List<EmptyShape>) rasterize() {
    List<RasterizedShape> shapes = [];
    List<EmptyShape> emptyShapes = [];

    for (RasterizedShapeType type in RasterizedShapeType.values) {
      for (int r = 0; r <= rows - type.height; r++) {
        for (int c = 0; c <= cols - type.width; c++) {
          if (_canPlaceShape(r, c, type)) {
            shapes.add(RasterizedShape(
              type: type,
              position: Offset(c.toDouble(), r.toDouble()),
              variation: Random().nextInt(type.numVariations),
              usePrimary: Random().nextDouble() < 0.2,
            ));
            _markVisited(r, c, type);
          }
        }
      }
    }
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (!matrix[r][c]) {
          // Remove position markers
          if ((r < 7 && c < 7) || (r < 7 && c >= cols - 7) || (r >= rows - 7 && c < 7)) {
            continue;
          }
          if (Random().nextDouble() < 0.4) {
            continue;
          }
          emptyShapes.add(
            EmptyShape(
              position: Offset(c.toDouble(), r.toDouble()),
              variation: Random().nextInt(RasterizedShapeType.dot.numVariations),
            ),
          );
        }
      }
    }

    return (shapes, emptyShapes);
  }

  bool _canPlaceShape(int r, int c, RasterizedShapeType type) {
    for (int i = 0; i < type.height; i++) {
      for (int j = 0; j < type.width; j++) {
        if (!matrix[r + i][c + j] || visited[r + i][c + j]) {
          return false;
        }
      }
    }
    return true;
  }

  void _markVisited(int r, int c, RasterizedShapeType type) {
    for (int i = 0; i < type.height; i++) {
      for (int j = 0; j < type.width; j++) {
        visited[r + i][c + j] = true;
      }
    }
  }
}

class QrCode extends HookWidget {
  const QrCode({required this.data, super.key});

  final String data;

  @override
  Widget build(BuildContext context) {
    final qrCode =
        useMemoized(() => qr.QrCode.fromData(data: data, errorCorrectLevel: qr.QrErrorCorrectLevel.L), [data]);
    final qrImage = useMemoized(() => qr.QrImage(qrCode), [qrCode]);
    final matrix = useMemoized(() {
      return List.generate(qrImage.moduleCount, (r) {
        return List.generate(qrImage.moduleCount, (c) => qrImage.isDark(r, c));
      });
    }, [qrImage]);
    final matrixWithoutPositionMarkers = useMemoized(() {
      final size = qrImage.moduleCount;
      final markerSize = 7;

      List<List<bool>> newMatrix = List.generate(size, (r) {
        return List.generate(size, (c) => matrix[r][c]);
      });

      void clearMarker(int startRow, int startCol) {
        for (int r = startRow; r < startRow + markerSize; r++) {
          for (int c = startCol; c < startCol + markerSize; c++) {
            if (r >= 0 && r < size && c >= 0 && c < size) {
              newMatrix[r][c] = false;
            }
          }
        }
      }

      // Top-left
      clearMarker(0, 0);
      // Top-right
      clearMarker(0, size - markerSize);
      // Bottom-left
      clearMarker(size - markerSize, 0);

      return newMatrix;
    }, [matrix, qrImage]);

    final rasterizer =
        useMemoized(() => GreedyRasterizer(matrixWithoutPositionMarkers), [matrixWithoutPositionMarkers]);
    final (shapes, emptyShapes) = useMemoized(() => rasterizer.rasterize(), [rasterizer]);
    final colorScheme = AppTheme
        .themes[context.watch<AppThemeState>().themeName.getBrightnessCounterPart(Brightness.light)]!.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.all(4),
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: QrPainter(
              shapes: shapes, moduleCount: qrImage.moduleCount, colorScheme: colorScheme, emptyShapes: emptyShapes),
        ),
      ),
    );
  }
}

class QrPainter extends CustomPainter {
  final List<RasterizedShape> shapes;
  final int moduleCount;
  final ColorScheme colorScheme;
  final List<EmptyShape> emptyShapes;

  QrPainter({required this.shapes, required this.moduleCount, required this.colorScheme, required this.emptyShapes});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = colorScheme.primary;
    final cellSize = size.width / moduleCount;
    final cellPadding = cellSize * 0.2;

    // Draw position markers as circles
    void drawPositionMarker(int startRow, int startCol) {
      final center = Offset(
        (startCol + 3.5) * cellSize,
        (startRow + 3.5) * cellSize,
      );
      final outerRadius = cellSize * 2.8;
      final innerRadius = cellSize * 2.5;

      final paint = Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellSize * 0.85;

      // Outer circle
      canvas.drawCircle(center, outerRadius, paint);
      var verySunnyPath = _buildVerySunnyPath(Size(innerRadius, innerRadius));
      verySunnyPath = verySunnyPath.shift(
        Offset(center.dx - innerRadius / 2 - verySunnyPath.getBounds().left,
            center.dy - innerRadius / 2 - verySunnyPath.getBounds().top),
      );

      print(Size(innerRadius, innerRadius));
      print(center.dx - innerRadius / 2);
      print(verySunnyPath.getBounds());

      final rect = Rect.fromLTWH(
        center.dx - innerRadius / 2,
        center.dy - innerRadius / 2,
        innerRadius,
        innerRadius,
      );
      print(rect);
      // canvas.drawRect(rect, paint);

      canvas.drawPath(verySunnyPath, paint..style = PaintingStyle.fill);
    }

    drawPositionMarker(0, 0); // Top-left
    drawPositionMarker(0, moduleCount - 7); // Top-right
    drawPositionMarker(moduleCount - 7, 0); // Bottom-left

    for (var emptyShape in emptyShapes) {
      final rect = Rect.fromLTWH(
        emptyShape.position.dx * cellSize + cellPadding / 2,
        emptyShape.position.dy * cellSize + cellPadding / 2,
        cellSize - cellPadding,
        cellSize - cellPadding,
      );
      paint.color = colorScheme.onSurfaceVariant.withValues(alpha: 0.05 + emptyShape.colorOffset);
      switch (emptyShape.variation) {
        case 0:
          canvas.drawCircle(rect.center, rect.width * 0.5, paint);
          break;
        case 1:
          canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(2)), paint);
          break;
        case 2:
          canvas.drawPath(_buildJellybeanPath(rect.size).shift(rect.topLeft), paint);
          break;
      }
    }

    for (var shape in shapes) {
      if (shape.usePrimary) {
        paint.color = colorScheme.tertiary;
      } else {
        paint.color = colorScheme.primary;
      }

      final rect = Rect.fromLTWH(
        shape.position.dx * cellSize + cellPadding / 2,
        shape.position.dy * cellSize + cellPadding / 2,
        shape.type.width * cellSize - cellPadding,
        shape.type.height * cellSize - cellPadding,
      );

      if (shape.type == RasterizedShapeType.dot) {
        final radius = ((cellSize - cellPadding) * 0.5).clamp(1.0, double.infinity);

        switch (shape.variation) {
          case 0:
            canvas.drawCircle(rect.center, radius, paint);
            break;
          case 1:
            canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(8)), paint);
            break;
          case 2:
            canvas.drawPath(_buildJellybeanPath(rect.size).shift(rect.topLeft), paint);
            break;
        }
      } else if (shape.type == RasterizedShapeType.lineHorizontalShort ||
          shape.type == RasterizedShapeType.lineHorizontalLong) {
        final rrect = RRect.fromRectAndRadius(
          rect,
          Radius.circular(cellSize * 0.4),
        );
        canvas.drawRRect(rrect, paint);
      } else if (shape.type == RasterizedShapeType.lineVerticalShort ||
          shape.type == RasterizedShapeType.lineVerticalLong) {
        final rrect = RRect.fromRectAndRadius(
          rect,
          Radius.circular(cellSize * 0.4),
        );
        canvas.drawRRect(rrect, paint);
      } else if (shape.type == RasterizedShapeType.square) {
        switch (shape.variation) {
          case 0:
            canvas.drawCircle(rect.center, rect.width * 0.5, paint);
            break;
          case 1:
            final path = _buildFourSidedCookiePath(rect.size).shift(rect.topLeft);
            canvas.drawPath(path, paint);
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Path _buildFourSidedCookiePath(Size size) {
  final path = Path();
  path.moveTo(size.width * 0.02, size.height * 0.34);
  path.cubicTo(
    -0.07,
    size.height * 0.14,
    size.width * 0.14,
    -0.07,
    size.width * 0.34,
    size.height * 0.02,
  );
  path.cubicTo(
    size.width * 0.4,
    size.height * 0.05,
    size.width * 0.47,
    size.height * 0.08,
    size.width * 0.54,
    size.height * 0.08,
  );
  path.cubicTo(
    size.width * 0.6,
    size.height * 0.05,
    size.width * 0.66,
    size.height * 0.02,
    size.width * 0.66,
    size.height * 0.02,
  );
  path.cubicTo(
    size.width * 0.86,
    -0.07,
    size.width * 1.07,
    size.height * 0.14,
    size.width * 0.98,
    size.height * 0.34,
  );
  path.cubicTo(
    size.width * 0.95,
    size.height * 0.4,
    size.width * 0.92,
    size.height * 0.47,
    size.width * 0.92,
    size.height * 0.54,
  );
  path.cubicTo(
    size.width * 0.95,
    size.height * 0.6,
    size.width * 0.98,
    size.height * 0.66,
    size.width * 0.98,
    size.height * 0.66,
  );
  path.cubicTo(
    size.width * 1.07,
    size.height * 0.86,
    size.width * 0.86,
    size.height * 1.07,
    size.width * 0.66,
    size.height * 0.98,
  );
  path.cubicTo(
    size.width * 0.6,
    size.height * 0.95,
    size.width * 0.54,
    size.height * 0.92,
    size.width * 0.47,
    size.height * 0.92,
  );
  path.cubicTo(
    size.width * 0.4,
    size.height * 0.95,
    size.width * 0.34,
    size.height * 0.98,
    size.width * 0.34,
    size.height * 0.98,
  );
  path.cubicTo(
    size.width * 0.14,
    size.height * 1.07,
    -0.07,
    size.height * 0.86,
    size.width * 0.02,
    size.height * 0.66,
  );
  path.cubicTo(
    size.width * 0.05,
    size.height * 0.6,
    size.width * 0.08,
    size.height * 0.54,
    size.width * 0.08,
    size.height * 0.47,
  );
  path.cubicTo(
    size.width * 0.05,
    size.height * 0.4,
    size.width * 0.02,
    size.height * 0.34,
    size.width * 0.02,
    size.height * 0.34,
  );
  path.close();
  return path;
}

Path _buildVerySunnyPath(Size size) {
  final path = Path();
  path.moveTo(size.width * 0.74, size.height * 0.4);
  path.cubicTo(
    size.width * 0.76,
    size.height * 0.3,
    size.width * 0.9,
    size.height * 0.3,
    size.width * 0.92,
    size.height * 0.4,
  );
  path.cubicTo(
    size.width * 0.93,
    size.height * 0.47,
    size.width,
    size.height / 2,
    size.width * 1.06,
    size.height * 0.47,
  );
  path.cubicTo(
    size.width * 1.15,
    size.height * 0.41,
    size.width * 1.25,
    size.height * 0.51,
    size.width * 1.19,
    size.height * 0.59,
  );
  path.cubicTo(
    size.width * 1.16,
    size.height * 0.65,
    size.width * 1.19,
    size.height * 0.72,
    size.width * 1.25,
    size.height * 0.74,
  );
  path.cubicTo(
    size.width * 1.35,
    size.height * 0.76,
    size.width * 1.35,
    size.height * 0.9,
    size.width * 1.26,
    size.height * 0.92,
  );
  path.cubicTo(
    size.width * 1.19,
    size.height * 0.93,
    size.width * 1.16,
    size.height,
    size.width * 1.19,
    size.height * 1.06,
  );
  path.cubicTo(
    size.width * 1.25,
    size.height * 1.15,
    size.width * 1.15,
    size.height * 1.25,
    size.width * 1.07,
    size.height * 1.19,
  );
  path.cubicTo(
    size.width,
    size.height * 1.16,
    size.width * 0.93,
    size.height * 1.19,
    size.width * 0.92,
    size.height * 1.25,
  );
  path.cubicTo(
    size.width * 0.9,
    size.height * 1.35,
    size.width * 0.76,
    size.height * 1.35,
    size.width * 0.74,
    size.height * 1.26,
  );
  path.cubicTo(
    size.width * 0.72,
    size.height * 1.19,
    size.width * 0.65,
    size.height * 1.16,
    size.width * 0.6,
    size.height * 1.19,
  );
  path.cubicTo(
    size.width * 0.51,
    size.height * 1.25,
    size.width * 0.41,
    size.height * 1.15,
    size.width * 0.46,
    size.height * 1.07,
  );
  path.cubicTo(
    size.width / 2,
    size.height,
    size.width * 0.47,
    size.height * 0.93,
    size.width * 0.41,
    size.height * 0.92,
  );
  path.cubicTo(
    size.width * 0.3,
    size.height * 0.9,
    size.width * 0.3,
    size.height * 0.76,
    size.width * 0.4,
    size.height * 0.74,
  );
  path.cubicTo(
    size.width * 0.47,
    size.height * 0.72,
    size.width / 2,
    size.height * 0.65,
    size.width * 0.47,
    size.height * 0.6,
  );
  path.cubicTo(
    size.width * 0.41,
    size.height * 0.51,
    size.width * 0.51,
    size.height * 0.41,
    size.width * 0.59,
    size.height * 0.46,
  );
  path.cubicTo(
    size.width * 0.65,
    size.height / 2,
    size.width * 0.72,
    size.height * 0.47,
    size.width * 0.74,
    size.height * 0.41,
  );
  path.close();
  return path;
}

Path _buildJellybeanPath(Size size) {
  final path = Path();
  path.moveTo(size.width * 0.39, size.height * 0.08);
  path.cubicTo(
    size.width * 0.47,
    size.height * 0.03,
    size.width * 0.57,
    size.height * 0.03,
    size.width * 0.65,
    size.height * 0.08,
  );
  path.cubicTo(
    size.width * 0.88,
    size.height * 0.23,
    size.width * 0.93,
    size.height * 0.26,
    size.width * 0.98,
    size.height * 0.39,
  );
  path.cubicTo(
    size.width * 1.02,
    size.height * 0.69,
    size.width * 1.03,
    size.height * 0.79,
    size.width * 0.87,
    size.height * 0.92,
  );
  path.cubicTo(
    size.width * 0.61,
    size.height * 1.03,
    size.width * 0.55,
    size.height * 1.05,
    size.width * 0.43,
    size.height * 1.03,
  );
  path.cubicTo(
    size.width * 0.17,
    size.height * 0.92,
    size.width * 0.07,
    size.height * 0.89,
    size.width * 0.02,
    size.height * 0.69,
  );
  path.cubicTo(
    size.width * 0.05,
    size.height * 0.39,
    size.width * 0.06,
    size.height * 0.32,
    size.width * 0.16,
    size.height * 0.23,
  );
  path.cubicTo(
    size.width * 0.39,
    size.height * 0.08,
    size.width * 0.39,
    size.height * 0.08,
    size.width * 0.39,
    size.height * 0.08,
  );
  path.close();
  return path;
}
