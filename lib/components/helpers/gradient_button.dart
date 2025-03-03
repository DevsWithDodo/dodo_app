import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../helpers/app_theme.dart';

class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool useSecondary;
  final double borderRadius;
  final bool useTertiary;
  final bool useSecondaryContainer;
  final bool usePrimaryContainer;
  final bool useTertiaryContainer;
  final bool disabled;
  final double paddingRight;
  final double paddingLeft;
  final ThemeName? themeName; 
  const GradientButton({super.key, 
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
    this.themeName,
  });

  factory GradientButton.icon({
    required Widget icon,
    required Widget label,
    VoidCallback? onPressed,
    ThemeName? themeName,
    bool useSecondary = false,
    double borderRadius = 20,
    bool useSecondaryContainer = false,
    bool usePrimaryContainer = false,
    bool useTertiary = false,
    bool useTertiaryContainer = false,
    bool disabled = false,
  }) =>
      GradientButton(
        onPressed: onPressed,
        useSecondary: useSecondary,
        borderRadius: borderRadius,
        useSecondaryContainer: useSecondaryContainer,
        usePrimaryContainer: usePrimaryContainer,
        useTertiary: useTertiary,
        useTertiaryContainer: useTertiaryContainer,
        disabled: disabled,
        paddingLeft: 16,
        paddingRight: 16,
        themeName: themeName,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [icon, SizedBox(width: 8), label],
        ),
      );

  @override
  Widget build(BuildContext context) {
    ThemeName themeName = this.themeName ?? context.watch<AppThemeState>().themeName;
    Color textColor = AppTheme.textColorOnGradient(
      themeName,
      useSecondary: useSecondary,
      usePrimaryContainer: usePrimaryContainer,
      useTertiaryContainer: useTertiary,
      useSecondaryContainer: useSecondaryContainer,
    );
    return Theme(
      data: Theme.of(context).copyWith(
        iconTheme: IconThemeData(
          size: 18,
          color: disabled ? Colors.white : textColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: disabled ? Colors.white : textColor,
              ),
          child: Container(
            constraints: BoxConstraints(minWidth: 88.0, minHeight: 36.0),
            height: 40,
            child: Ink(
              decoration: BoxDecoration(
                color: null,
                gradient: disabled
                    ? LinearGradient(colors: [Colors.grey, Colors.grey])
                    : AppTheme.gradientFromTheme(
                        themeName,
                        useSecondary: useSecondary,
                        usePrimaryContainer: usePrimaryContainer,
                        useTertiaryContainer: useTertiary,
                        useSecondaryContainer: useSecondaryContainer,
                      ),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: InkWell(
                  borderRadius: BorderRadius.circular(borderRadius),
                  onTap: disabled ? null : onPressed,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.only(
                            left: paddingLeft, right: paddingRight),
                        child: child,
                      ),
                    ],
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
