import 'package:csocsort_szamla/config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScreenWidthProvider extends StatelessWidget {
  ScreenWidthProvider({super.key, required this.builder}) {
    _screenWidth = ScreenWidth(width: 0, height: 0, isMobile: false);
  }
  final Widget Function(BuildContext context) builder;
  late final ScreenWidth _screenWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        MediaQueryData mediaQuery = MediaQuery.of(context);
        _screenWidth.updateValues(
          constraints.maxWidth,
          constraints.maxHeight - mediaQuery.padding.top - mediaQuery.padding.bottom,
          constraints.maxWidth < tabletViewWidth,
        );

        return ChangeNotifierProvider.value(
          value: _screenWidth,
          builder: (context, _) => this.builder(context),
        );
      },
    );
  }
}

class ScreenWidth extends ChangeNotifier {
  double width;
  double height;
  bool isMobile;

  ScreenWidth({required this.width, required this.height, required this.isMobile});

  void updateValues(double newWidth, double newHeight, bool newIsMobile, {bool notify = true}) {
    bool changed = width != newWidth || height != newHeight || isMobile != newIsMobile;
    width = newWidth;
    height = newHeight;
    isMobile = newIsMobile;
    if (notify && changed) {
      notifyListeners();
    }
  }
}
