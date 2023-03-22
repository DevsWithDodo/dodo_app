import 'package:csocsort_szamla/essentials/models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CategoryPickerDropdown extends StatefulWidget {
  final Category defaultCategoryValue;
  final ValueChanged<Category> onCategoryChanged;
  final bool filled;
  final bool noContentPadding;
  final bool showSymbol;
  final Color dropdownColor;
  final Color textColor;
  CategoryPickerDropdown({
    @required this.defaultCategoryValue,
    @required this.onCategoryChanged,
    this.filled = true,
    this.noContentPadding = false,
    this.showSymbol = true,
    this.textColor,
    this.dropdownColor,
  });

  @override
  State<CategoryPickerDropdown> createState() => _CategoryPickerDropdown();
}

class _CategoryPickerDropdown extends State<CategoryPickerDropdown> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: Category.categories.map((category) {
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            widget.onCategoryChanged(category);
          },
          child: Ink(
            width: 75,
            decoration: BoxDecoration(
              color: widget.defaultCategoryValue == category
                  ? Theme.of(context).colorScheme.tertiary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  category.icon,
                  color: widget.defaultCategoryValue == category
                      ? Theme.of(context).colorScheme.onTertiary
                      : Theme.of(context).colorScheme.primary,
                ),
                Text(
                  category.text.tr(),
                  style: Theme.of(context).textTheme.labelSmall.copyWith(
                        color: widget.defaultCategoryValue == category
                            ? Theme.of(context).colorScheme.onTertiary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
