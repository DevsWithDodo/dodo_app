import 'package:flutter/material.dart';

enum DialogShowTime {
  onInit,
  onBuild,
  both,
}

enum DialogType {
  modal,
  bottom,
}

abstract class MainDialog extends StatelessWidget {
  final DialogShowTime showTime;
  final DialogType type;
  final bool Function(BuildContext context) canShow;
  final void Function(BuildContext context, {String? payload})? onDismiss;
  const MainDialog({
    required this.showTime,
    required this.type,
    required this.canShow,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}
