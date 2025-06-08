import 'package:flutter/material.dart';

class M3Curves {
  static ({Cubic curve, Duration duration}) get expressiveFastSpatial => (
        curve: Cubic(0.42, 1.67, 0.21, 0.90),
        duration: const Duration(milliseconds: 300),
      );
  static ({Cubic curve, Duration duration}) get expressiveDefaultSpatial => (
        curve: Cubic(0.38, 1.21, 0.22, 1.00),
        duration: const Duration(milliseconds: 500),
      );
  static ({Cubic curve, Duration duration}) get expressiveSlowSpatial => (
        curve: Cubic(0.39, 1.29, 0.35, 0.98),
        duration: const Duration(milliseconds: 650),
      );
  static ({Cubic curve, Duration duration}) get expressiveFastEffect => (
        curve: Cubic(0.31, 0.94, 0.34, 1.00),
        duration: const Duration(milliseconds: 150),
      );
  static ({Cubic curve, Duration duration}) get expressiveDefaultEffect => (
        curve: Cubic(0.34, 0.80, 0.34, 1.00),
        duration: const Duration(milliseconds: 200),
      );
  static ({Cubic curve, Duration duration}) get expressiveSlowEffect => (
        curve: Cubic(0.34, 0.88, 0.34, 1.00),
        duration: const Duration(milliseconds: 300),
      );

  static ({Cubic curve, Duration duration}) get standardFastSpatial => (
        curve: Cubic(0.27, 1.06, 0.18, 1.00),
        duration: const Duration(milliseconds: 350),
      );
  static ({Cubic curve, Duration duration}) get standardDefaultSpatial => (
        curve: Cubic(0.27, 1.06, 0.18, 1.00),
        duration: const Duration(milliseconds: 500),
      );
  static ({Cubic curve, Duration duration}) get standardSlowSpatial => (
        curve: Cubic(0.27, 1.06, 0.18, 1.00),
        duration: const Duration(milliseconds: 700),
      );
  static ({Cubic curve, Duration duration}) get standardFastEffect => (
        curve: Cubic(0.31, 0.94, 0.34, 1.00),
        duration: const Duration(milliseconds: 150),
      );
  static ({Cubic curve, Duration duration}) get standardDefaultEffect => (
        curve: Cubic(0.34, 0.80, 0.34, 1.00),
        duration: const Duration(milliseconds: 200),
      );
  static ({Cubic curve, Duration duration}) get standardSlowEffect => (
        curve: Cubic(0.34, 0.80, 0.34, 1.00),
        duration: const Duration(milliseconds: 300),
      );
}
