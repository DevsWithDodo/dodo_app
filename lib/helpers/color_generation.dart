import 'dart:math';

import 'package:flutter/material.dart';

Color determineTextColor(Color backgroundColor) {
  // Normalize RGB values to the range [0, 1].
  double r = backgroundColor.red / 255.0;
  double g = backgroundColor.green / 255.0;
  double b = backgroundColor.blue / 255.0;

  // Apply the luminance formula.
  double luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;

  // Use white text for dark backgrounds and black text for light backgrounds.
  return (luminance < 0.5) ? Color(0xFFFFFFFF) : Color(0xFF000000);
}

List<Color> generateDistinctColors(int numberOfColors) {
  if (numberOfColors <= 0) {
    throw ArgumentError('Number of colors must be greater than zero.');
  }

  List<Color> colors = [];
  double hueStep = 360 / (numberOfColors); // Spread hues evenly across the spectrum.
  double firstHue = Random().nextDouble() * 360; // Randomize the starting hue.

  for (int i = 0; i < numberOfColors; i++) {
    double hue = (firstHue + i * hueStep) % 360;
    // Convert HSV to RGB for the Color class.
    colors.add(hsvToColor(hue, 0.3, 0.9)); // High saturation and brightness.
  }

  return colors;
}

Color hsvToColor(double hue, double saturation, double value) {
  double c = value * saturation;
  double x = c * (1 - ((hue / 60) % 2 - 1).abs());
  double m = value - c;

  double r = 0, g = 0, b = 0;

  if (hue < 60) {
    r = c;
    g = x;
  } else if (hue < 120) {
    r = x;
    g = c;
  } else if (hue < 180) {
    g = c;
    b = x;
  } else if (hue < 240) {
    g = x;
    b = c;
  } else if (hue < 300) {
    r = x;
    b = c;
  } else {
    r = c;
    b = x;
  }

  return Color.fromARGB(
    255,
    ((r + m) * 255).round(),
    ((g + m) * 255).round(),
    ((b + m) * 255).round(),
  );
}
