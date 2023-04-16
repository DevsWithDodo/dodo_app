import 'package:flutter/material.dart';

import '../../config.dart';
import '../app_theme.dart';

class GradientButton extends StatelessWidget {
  final Widget child;
  final Function()? onPressed;
  final bool useSecondary;
  final double borderRadius;
  final bool useTertiary;
  final bool useSecondaryContainer;
  final bool usePrimaryContainer;
  final bool useTertiaryContainer;
  final bool disabled;
  final double paddingRight;
  final double paddingLeft;
  GradientButton({
    required this.child,
    this.onPressed,
    this.useSecondary = false,
    this.borderRadius = 20,
    this.useSecondaryContainer = false,
    this.usePrimaryContainer = false,
    this.useTertiary = false,
    this.useTertiaryContainer = false,
    this.disabled = false,
    this.paddingRight = 24,
    this.paddingLeft = 24,
  });

  factory GradientButton.icon({
    required Widget icon,
    required Widget label,
    required Function() onPressed,
    bool useSecondary = false,
    double borderRadius = 20,
    bool useSecondaryContainer = false,
    bool usePrimaryContainer = false,
    bool useTertiary = false,
    bool useTertiaryContainer = false,
    bool disabled = false,
  }) =>
      GradientButton(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [icon, SizedBox(width: 8), label],
        ),
        onPressed: onPressed,
        useSecondary: useSecondary,
        borderRadius: borderRadius,
        useSecondaryContainer: useSecondaryContainer,
        usePrimaryContainer: usePrimaryContainer,
        useTertiary: useTertiary,
        useTertiaryContainer: useTertiaryContainer,
        disabled: disabled,
        paddingLeft: 16,
      );

  @override
  Widget build(BuildContext context) {
    Color textColor = AppTheme.textColorOnGradient(
      currentThemeName,
      useSecondary: this.useSecondary,
      usePrimaryContainer: this.usePrimaryContainer,
      useTertiaryContainer: this.useTertiary,
      useSecondaryContainer: this.useSecondaryContainer,
    );
    return Theme(
      data: Theme.of(context).copyWith(
        iconTheme: IconThemeData(
          size: 18,
          color: this.disabled ? Colors.white : textColor,
        ),
      ),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: this.disabled ? Colors.white : textColor,
            ),
        child: Container(
          constraints: BoxConstraints(minWidth: 88.0, minHeight: 36.0),
          height: 40,
          child: Ink(
            decoration: BoxDecoration(
              gradient: disabled
                  ? LinearGradient(colors: [Colors.grey, Colors.grey])
                  : AppTheme.gradientFromTheme(
                      currentThemeName,
                      useSecondary: this.useSecondary,
                      usePrimaryContainer: this.usePrimaryContainer,
                      useTertiaryContainer: this.useTertiary,
                      useSecondaryContainer: this.useSecondaryContainer,
                    ),
              borderRadius: BorderRadius.circular(this.borderRadius),
            ),
            child: InkWell(
                borderRadius: BorderRadius.circular(this.borderRadius),
                onTap: this.disabled ? null : this.onPressed,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                          left: this.paddingLeft, right: this.paddingRight),
                      child: this.child,
                    ),
                  ],
                )),
          ),
        ),
      ),
    );
  }
}
