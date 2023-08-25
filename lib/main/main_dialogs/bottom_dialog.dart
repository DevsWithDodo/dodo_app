import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainBottomDialog extends StatelessWidget {
  final Widget? label;
  final Widget? title;
  final Widget? subtitle;
  final Widget? icon;
  final Widget? button;
  final bool dismissible;
  MainBottomDialog({
    this.label,
    this.title,
    this.subtitle,
    this.icon,
    this.button,
    this.dismissible = true,
    super.key,
  }) {
    assert(
      label != null || (title != null && subtitle != null),
      'You must provide either a label or a title and a subtitle',
    );
    assert(
      !(label != null && (title != null || subtitle != null)),
      'You can\'t provide both a label and a title or subtitle',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Dismissible(
        key: GlobalKey(),
        onDismissed: (direction) => context.read<VoidCallback>()(),
        direction: dismissible ? DismissDirection.down : DismissDirection.none,
        child: Container(
          padding: EdgeInsets.all(10),
          constraints: BoxConstraints(
            maxWidth: 500,
          ),
          decoration: BoxDecoration(
            color: ElevationOverlay.applyOverlay(
              context,
              Theme.of(context).colorScheme.surface,
              10,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          iconTheme: Theme.of(context).iconTheme.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                size: 30,
                              ),
                        ),
                        child: DefaultTextStyle(
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          child: Row(
                            children: [
                              Padding(
                                  padding: EdgeInsets.only(right: 10),
                                  child: icon),
                              label ??
                                  Flexible(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        title!,
                                        DefaultTextStyle(
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                          child: subtitle!,
                                        ),
                                      ],
                                    ),
                                  )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: dismissible,
                      child: IconButton(
                        onPressed: context.read<VoidCallback>(),
                        icon: Icon(
                          Icons.close,
                          size: 18,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              button ?? SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
