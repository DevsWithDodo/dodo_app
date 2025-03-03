import 'package:csocsort_szamla/config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScreenSizeProvider extends StatelessWidget {
  ScreenSizeProvider({super.key, required this.builder}) {
    _screenSize = ScreenSize(width: 0, height: 0, isMobile: false, padding: EdgeInsets.zero);
  }
  final Widget Function(BuildContext context) builder;
  late final ScreenSize _screenSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        MediaQueryData mediaQuery = MediaQuery.of(context);
        _screenSize.updateValues(
          constraints.maxWidth,
          constraints.maxHeight - mediaQuery.padding.top - mediaQuery.padding.bottom,
          constraints.maxWidth < tabletViewWidth,
          mediaQuery.padding,
        );

        return ChangeNotifierProvider.value(
          value: _screenSize,
          builder: (context, _) => builder(context),
        );
      },
    );
  }
}

class ScreenSize extends ChangeNotifier {
  double width;
  double height;
  EdgeInsets padding;
  bool isMobile;

  ScreenSize({required this.width, required this.height, required this.padding, required this.isMobile});

  void updateValues(double newWidth, double newHeight, bool newIsMobile, EdgeInsets newPadding, {bool notify = true}) {
    bool changed = width != newWidth || height != newHeight || isMobile != newIsMobile || padding != newPadding;
    width = newWidth;
    height = newHeight;
    isMobile = newIsMobile;
    padding = newPadding;
    if (notify && changed) {
      notifyListeners();
    }
  }
}
