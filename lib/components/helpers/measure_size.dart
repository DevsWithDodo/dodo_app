import 'package:flutter/material.dart';

class MeasureSize extends StatefulWidget {
  final Widget child;
  final void Function(Size size) onChange;

  const MeasureSize({
    super.key,
    required this.child,
    required this.onChange,
  });

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  final _key = GlobalKey();
  Size? oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _key.currentContext;
      if (context == null) return;
      final newSize = context.size;
      if (newSize != null && oldSize != newSize) {
        oldSize = newSize;
        widget.onChange(newSize);
      }
    });

    return Container(key: _key, child: widget.child);
  }
}
