import 'package:csocsort_szamla/config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScreenWidthProvider extends StatefulWidget {
  const ScreenWidthProvider({super.key, required this.child});
  final Widget child;

  @override
  State<ScreenWidthProvider> createState() => _ScreenWidthProviderState();
}

class _ScreenWidthProviderState extends State<ScreenWidthProvider> {
  late ScreenWidth _screenWidth;

  @override
  void initState() {
    super.initState();
    _screenWidth = ScreenWidth(width: 0, height: 0, isMobile: false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        MediaQueryData mediaQuery = MediaQuery.of(context);
        _screenWidth.updateValues(
          constraints.maxWidth,
          constraints.maxHeight -
              mediaQuery.padding.top -
              mediaQuery.padding.bottom,
          constraints.maxWidth < tabletViewWidth,
        );

        return ChangeNotifierProvider.value(
          value: _screenWidth,
          child: widget.child,
        );
      },
    );
  }
}

class ScreenWidth extends ChangeNotifier {
  double width;
  double height;
  bool isMobile;

  ScreenWidth(
      {required this.width, required this.height, required this.isMobile});

  void updateValues(double newWidth, double newHeight, bool newIsMobile,
      {bool notify = true}) {
    width = newWidth;
    height = newHeight;
    isMobile = newIsMobile;
    print('screen width');
    if (notify) {
      notifyListeners();
    }
  }
}
