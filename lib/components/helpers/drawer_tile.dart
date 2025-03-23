import 'package:flutter/material.dart';

class DrawerTile extends StatelessWidget {
  const DrawerTile({
    super.key,
    required this.icon,
    required this.label,
    this.builder,
    this.onTap,
    this.dense = false,
    this.onReturn,
  });

  final IconData icon;
  final String label;
  final bool dense;
  final Widget Function(BuildContext)? builder;
  final Function()? onTap;
  final Function()? onReturn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        dense: dense,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        onTap: onTap ??
            (builder != null
                ? () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: builder!,
                      ),
                    );
                    onReturn?.call();
                  }
                : null),
      ),
    );
  }
}
