import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

final Map<Record, List<ImagePlacement>> _placedImageBoundsCache = {};

class ImagePlacement {
  final Rect bounds;
  final double scale;
  final double rotation;
  final int imageIndex;
  ImagePlacement({required this.bounds, required this.scale, required this.rotation, required this.imageIndex});
}

List<ImagePlacement> _getPlacedImageBounds(Size size, int numDifferentImages, int paintIndex) {
  final record = (size.width, numDifferentImages, paintIndex);
  if (_placedImageBoundsCache.containsKey(record)) {
    return _placedImageBoundsCache[record]!;
  }
  final List<ImagePlacement> placements = [];
  final random = Random();
  final imageSize = min(size.width, size.height);
  for (var i = 0; i < 1000; i++) {
    final double scale = 1 / 15 + random.nextDouble() * 4 / 15; // Scale between 0.3 and 1.0
    final double rotation = random.nextDouble() * 2 * pi; // Full circle rotation
    final scaledImageSize = imageSize * scale;
    // Try to find a valid position
    for (var j = 0; j < 300; j++) {
      // Max 100 attempts to place a single image
      final dx = random.nextDouble() * (size.width - scaledImageSize + 50);
      final dy = random.nextDouble() * (size.height - scaledImageSize + 50);

      final newImageRect = Rect.fromLTWH(dx - 25, dy - 25, scaledImageSize, scaledImageSize);

      // Check for overlaps
      bool overlaps = false;
      for (final placedRect in placements) {
        if (newImageRect.overlaps(placedRect.bounds)) {
          overlaps = true;
          break;
        }
      }

      if (!overlaps) {
        placements.add(ImagePlacement(
            bounds: newImageRect, scale: scale, rotation: rotation, imageIndex: random.nextInt(numDifferentImages)));
        break; // Move to the next image
      }
    }
  }

  _placedImageBoundsCache[record] = placements;
  return placements;
}

class RandomImagePainter extends CustomPainter {
  final List<ui.Image> images;
  late int paintIndex;
  RandomImagePainter({required this.images, this.paintIndex = 0});
  @override
  void paint(Canvas canvas, Size size) {
    var placedImageBounds = _getPlacedImageBounds(Size(1600, 1600), images.length, paintIndex);
    final canvasRect = Rect.fromLTWH(0, 0, size.width, size.height);
    placedImageBounds =
        placedImageBounds.where((placement) => !placement.bounds.intersect(canvasRect).isEmpty).toList();
    for (var placement in placedImageBounds) {
      final image = images[placement.imageIndex];
      // Calculate the scale and rotation based on the placement
      final largestImageEdge = max(image.width, image.height);
      final double scale = placement.scale / largestImageEdge * 800;
      final double rotation = placement.rotation;
      final Rect bounds = placement.bounds;

      final imageWidth = image.width * scale;
      final imageHeight = image.height * scale;
      final dx = bounds.left + (bounds.width - imageWidth) / 2;
      final dy = bounds.top + (bounds.height - imageHeight) / 2;
      final newImageRect = Rect.fromLTWH(dx, dy, imageWidth, imageHeight);
      canvas.save();
      // Translate to the center of the image for rotation
      canvas.translate(dx + imageWidth / 2, dy + imageHeight / 2);
      canvas.rotate(rotation);
      // Translate back
      canvas.translate(-(dx + imageWidth / 2), -(dy + imageHeight / 2));

      // Draw the image
      paintImage(
        canvas: canvas,
        rect: newImageRect,
        image: image,
        fit: BoxFit.fill,
        opacity: 0.6,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
