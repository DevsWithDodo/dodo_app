import 'package:csocsort_szamla/components/user_settings/components/payment_method_field_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PaymentMethodField extends StatelessWidget {
  final PaymentMethodFieldModel paymentMethod;
  final VoidCallback onRemove;
  final VoidCallback onPriorityChange;
  final VoidCallback onTextChange;
  final bool showLabels;

  const PaymentMethodField({
    super.key,
    required this.paymentMethod,
    required this.onRemove,
    required this.onPriorityChange,
    required this.onTextChange,
    required this.showLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
              isDense: true,
            ),
      ),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(50),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(3),
          3: FixedColumnWidth(50),
        },
        children: [
          if (showLabels)
            TableRow(
              children: [
                SizedBox(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('payment-method.name'.tr()),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('payment-method.value'.tr()),
                ),
                SizedBox(),
              ],
            ),
          TableRow(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onPriorityChange,
                icon: AnimatedCrossFade(
                  duration: Duration(milliseconds: 100),
                  crossFadeState: paymentMethod.priority ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  firstChild: Icon(Icons.star),
                  secondChild: Icon(Icons.star_border),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: TextField(
                  controller: paymentMethod.nameController,
                  decoration: InputDecoration(
                    hintText: 'payment-method.name.hint'.tr(),
                    isDense: false,
                  ),
                  onChanged: (_) => onTextChange(),
                  onTapOutside: (_) => onTextChange(),
                ),
              ),
              TextField(
                controller: paymentMethod.valueController,
                decoration: InputDecoration(
                  hintText: 'payment-method.value.hint'.tr(),
                  isDense: false,
                ),
                onChanged: (_) => onTextChange(),
                onEditingComplete: onTextChange,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.delete),
                onPressed: onRemove,
              )
            ],
          )
        ],
      ),

      // Row(
      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //   children: [
      //     IconButton(
      //       visualDensity: VisualDensity.compact,
      //       onPressed: onPriorityChange,
      //       icon: AnimatedCrossFade(
      //         duration: Duration(milliseconds: 100),
      //         crossFadeState: paymentMethod.priority ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      //         firstChild: Icon(Icons.star),
      //         secondChild: Icon(Icons.star_border),
      //       ),
      //     ),
      //     Expanded(
      //       child: Row(
      //         children: [
      //           Flexible(
      //             flex: 2,
      //             child: Column(
      //               crossAxisAlignment: CrossAxisAlignment.start,
      //               children: [
      //                 if (showLabels)
      //                   Padding(
      //                     padding: const EdgeInsets.only(bottom: 2),
      //                     child: Text('payment-method.name'.tr()),
      //                   ),
      //                 TextField(
      //                   controller: paymentMethod.nameController,
      //                   decoration: InputDecoration(
      //                     hintText: 'payment-method.name.hint'.tr(),
      //                     isDense: false,
      //                   ),
      //                   onChanged: (_) => onTextChange(),
      //                   onTapOutside: (_) => onTextChange(),
      //                 ),
      //               ],
      //             ),
      //           ),
      //           SizedBox(width: 5),
      //           Flexible(
      //             flex: 3,
      //             child: Column(
      //               crossAxisAlignment: CrossAxisAlignment.start,
      //               children: [
      //                 if (showLabels)
      //                   Padding(
      //                     padding: const EdgeInsets.only(bottom: 2),
      //                     child: Text('payment-method.value'.tr()),
      //                   ),
      //                 TextField(
      //                   controller: paymentMethod.valueController,
      //                   decoration: InputDecoration(
      //                     hintText: 'payment-method.value.hint'.tr(),
      //                     isDense: false,
      //                   ),
      //                   onChanged: (_) => onTextChange(),
      //                   onEditingComplete: onTextChange,
      //                 ),
      //               ],
      //             ),
      //           ),
      //         ],
      //       ),
      //     ),
      //     IconButton(
      //       visualDensity: VisualDensity.compact,
      //       icon: Icon(Icons.delete),
      //       onPressed: onRemove,
      //     )
      //   ],
      // ),
    );
  }
}
