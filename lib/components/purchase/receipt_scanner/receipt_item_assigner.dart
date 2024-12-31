import 'package:csocsort_szamla/components/helpers/segmented_progress_indicator.dart';
import 'package:csocsort_szamla/helpers/color_generation.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReceiptItemAssigner extends StatefulWidget {
  const ReceiptItemAssigner({
    super.key,
    required this.member,
    required this.color,
    required this.surfaceColor,
    required this.assignedQuantity,
    required this.sumQuantity,
    required this.onAssign,
    required this.onUnassign,
    required this.intemValue,
    required this.currency,
  });

  final Member member;
  final Color color;
  final Color surfaceColor;
  final int assignedQuantity;
  final int sumQuantity;
  final VoidCallback onAssign;
  final Function(bool completely) onUnassign;
  final double intemValue;
  final Currency currency;

  @override
  State<ReceiptItemAssigner> createState() => _ReceiptItemAssignerState();
}

class _ReceiptItemAssignerState extends State<ReceiptItemAssigner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _curve;
  late String _assignedValue;

  String _calculateAssignedValue() {
    if (widget.sumQuantity == 0) {
      return (0.0).toMoneyString(widget.currency, withSymbol: true);
    } else {
      return (widget.intemValue * widget.assignedQuantity / widget.sumQuantity).toMoneyString(
        widget.currency,
        withSymbol: true,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _controller.addListener(() => setState(() {}));
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    _assignedValue = _calculateAssignedValue();
    if (widget.assignedQuantity > 0) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant ReceiptItemAssigner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assignedQuantity == 0 && widget.assignedQuantity > 0) {
      _controller.forward();
    } else if (oldWidget.assignedQuantity > 0 && widget.assignedQuantity == 0) {
      _controller.reverse();
    }
    _assignedValue = _calculateAssignedValue();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            Visibility(
              visible: _curve.value > 0,
              child: Positioned(
                top: 10,
                right: (1 - _curve.value) * 10,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => widget.onUnassign(true),
                    child: Ink(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.color, width: 2),
                      ),
                      child: Icon(
                        Icons.close,
                        color: widget.color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0.5,
              left: 0.5,
              child: Container(
                width: 55,
                height: 55,
                child: SegmentedCircularProgressIndicator(
                  color: widget.color,
                  numSegments: widget.sumQuantity,
                  activeSegments: widget.assignedQuantity,
                  inactiveColor: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(right: _curve.value * 40),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        widget.onAssign();
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        margin: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        width: 40,
                        height: 40,
                        child: Center(
                          child: Text(
                            widget.member.nickname.substring(0, widget.member.nickname.length < 2 ? null : 2),
                            style: TextStyle(
                              color: determineTextColor(widget.color),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            child: child,
                            position: Tween<Offset>(
                              begin: Offset(0, 0.5),
                              end: Offset(0, 0),
                            ).animate(animation),
                          ),
                        );
                      },
                      child: Text(
                        _assignedValue,
                        key: ValueKey<String>(_assignedValue),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
