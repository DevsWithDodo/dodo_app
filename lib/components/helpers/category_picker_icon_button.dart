import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/components/helpers/category_picker_dropdown.dart';
import 'package:flutter/material.dart';

class CategoryPickerIconButton extends StatefulWidget {
  final Category? selectedCategory;
  final Function(Category?)? onCategoryChanged;

  const CategoryPickerIconButton({this.selectedCategory, this.onCategoryChanged, super.key});

  @override
  State<CategoryPickerIconButton> createState() => _CategoryPickerIconButton();
}

class _CategoryPickerIconButton extends State<CategoryPickerIconButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      isSelected: widget.selectedCategory != null,
      onPressed: () {
        showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: CategoryPickerDropdown(
                    defaultCategoryValue: widget.selectedCategory,
                    onCategoryChanged: (newCategory) {
                      Navigator.pop(context, newCategory);
                    },
                  ),
                ),
              );
            }).then((newCurrency) => widget.onCategoryChanged!(newCurrency));
      },
      icon: Icon(
        widget.selectedCategory == null ? Icons.app_registration : widget.selectedCategory!.icon,
        // color: widget.selectedCategory == null
        //     ? Theme.of(context).colorScheme.primary
        //     : Theme.of(context).colorScheme.tertiary,
      ),
    );
  }
}
