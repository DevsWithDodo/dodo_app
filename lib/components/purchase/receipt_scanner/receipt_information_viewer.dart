import 'package:csocsort_szamla/components/helpers/currency_picker_dropdown.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/purchase/receipt_scanner/receipt_item_assigner.dart';
import 'package:csocsort_szamla/helpers/color_generation.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ReceiptInformationViewer extends StatelessWidget {
  final ReceiptInformation? receiptInformation;
  final bool editInformation;
  final void Function(VoidCallback) onInformationChanged;
  final List<Member> members;
  final Map<int, Color> memberColors;
  const ReceiptInformationViewer({
    super.key,
    this.receiptInformation,
    required this.editInformation,
    required this.onInformationChanged,
    required this.members,
    required this.memberColors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (receiptInformation != null && !editInformation)
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: Theme.of(context).colorScheme.surfaceContainer,
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'receipt-scanner.members'.tr(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (Member member in members)
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: memberColors[member.id],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(member.nickname, style: TextStyle(color: determineTextColor(memberColors[member.id]!))),
                  ),
              ],
            ),
          ),
        Expanded(
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: Theme.of(context).colorScheme.surfaceContainer,
            ),
            clipBehavior: Clip.antiAlias,
            child: receiptInformation == null
                ? Center(child: Text('receipt-scanner.no-information'.tr()))
                : ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    children: [
                      if (!editInformation)
                        Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Center(
                            child: Text(
                              'receipt-scanner.assign-description'.tr(),
                              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: editInformation ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                          children: [
                            Text(
                              receiptInformation!.storeName,
                              style: Theme.of(context).textTheme.titleSmall,
                              textAlign: TextAlign.center,
                            ),
                            if (editInformation)
                              IconButton.filledTonal(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (context) => EditStoreNameDialog(
                                    name: receiptInformation!.storeName,
                                    onSave: (name) => onInformationChanged(() {
                                      receiptInformation!.storeName = name;
                                      Navigator.pop(context);
                                    }),
                                  ),
                                ),
                                icon: Icon(Icons.edit),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ),
                      if (editInformation)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: editInformation ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                            children: [
                              Text(
                                'currency'.tr(),
                                style: Theme.of(context).textTheme.titleSmall,
                                textAlign: TextAlign.center,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                ),
                                width: 100,
                                child: CurrencyPickerDropdown(
                                  currency: receiptInformation!.currency,
                                  currencyChanged: (currency) => onInformationChanged(() => receiptInformation!.currency = currency),
                                ),
                              )
                            ],
                          ),
                        ),
                      if (receiptInformation!.items.isEmpty)
                        Container(
                          child: Center(
                            child: Text('receipt-scanner.no-items'.tr()),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (ReceiptItem receiptItem in receiptInformation!.items)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AnimatedSize(
                                    alignment: Alignment.bottomCenter,
                                    duration: Duration(milliseconds: 100),
                                    child: Padding(
                                      padding: EdgeInsets.only(top: editInformation ? 10 : 15, left: 16, right: 16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: EdgeInsets.fromLTRB(
                                                8,
                                                receiptItem.assignedAmounts.isEmpty && !editInformation ? 5 : 8,
                                                8,
                                                8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  if (receiptItem.assignedAmounts.isEmpty && !editInformation)
                                                    Text(
                                                      'receipt-scanner.not-assigned'.tr(),
                                                      style: Theme.of(context).textTheme.labelSmall,
                                                    ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          receiptItem.itemName,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Text(
                                                        receiptItem.cost.toMoneyString(
                                                          receiptInformation!.currency,
                                                          withSymbol: true,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (editInformation)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 4),
                                              child: Row(
                                                children: [
                                                  IconButton.filledTonal(
                                                    onPressed: () => showDialog(
                                                      context: context,
                                                      builder: (context) => AddOrEditReceiptItemDialog(
                                                        item: receiptItem,
                                                        currency: receiptInformation!.currency,
                                                        onSave: (name, cost) => onInformationChanged(() {
                                                          receiptItem.itemName = name;
                                                          receiptItem.cost = cost;
                                                          Navigator.of(context).pop();
                                                        }),
                                                      ),
                                                    ),
                                                    icon: Icon(Icons.edit),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                  SizedBox(width: 4),
                                                  IconButton(
                                                    style: IconButton.styleFrom(
                                                      backgroundColor: Theme.of(context).colorScheme.error,
                                                      foregroundColor: Theme.of(context).colorScheme.onError,
                                                    ),
                                                    onPressed: () => onInformationChanged(() => receiptInformation!.items.remove(receiptItem)),
                                                    icon: Icon(Icons.delete),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                ],
                                              ),
                                            )
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (!editInformation) SizedBox(height: 6),
                                  if (!editInformation)
                                    SingleChildScrollView(
                                      padding: EdgeInsets.only(left: 16),
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(top: 5),
                                            child: IconButton.outlined(
                                              onPressed: () => onInformationChanged(
                                                () {
                                                  if (receiptItem.assignedAmounts.isEmpty) {
                                                    receiptItem.assignedAmounts = Map.fromIterables(
                                                      members.map((e) => e.id),
                                                      List.filled(members.length, 1),
                                                    );
                                                  } else {
                                                    receiptItem.assignedAmounts.clear();
                                                  }
                                                },
                                              ),
                                              padding: receiptItem.assignedAmounts.isEmpty ? EdgeInsets.zero : null,
                                              icon: receiptItem.assignedAmounts.isEmpty
                                                  ? Text(
                                                      "=",
                                                      style: TextStyle(
                                                        fontSize: 25,
                                                      ),
                                                    )
                                                  : Icon(Icons.clear),
                                            ),
                                          ),
                                          for (Member member in members)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 6),
                                              child: ReceiptItemAssigner(
                                                member: member,
                                                color: memberColors[member.id]!,
                                                surfaceColor: Theme.of(context).colorScheme.surfaceContainer,
                                                sumQuantity: receiptItem.assignedAmounts.values.fold(
                                                  0,
                                                  (previousValue, element) => previousValue + element,
                                                ),
                                                assignedQuantity: receiptItem.assignedAmounts[member.id] ?? 0,
                                                currency: receiptInformation!.currency,
                                                intemValue: receiptItem.cost,
                                                onAssign: () => onInformationChanged(() {
                                                  if (receiptItem.assignedAmounts[member.id] == null) {
                                                    receiptItem.assignedAmounts[member.id] = 1;
                                                  } else {
                                                    receiptItem.assignedAmounts[member.id] = receiptItem.assignedAmounts[member.id]! + 1;
                                                  }
                                                }),
                                                onUnassign: (bool completely) => onInformationChanged(() {
                                                  if (receiptItem.assignedAmounts[member.id] != null) {
                                                    if (completely || receiptItem.assignedAmounts[member.id] == 1) {
                                                      receiptItem.assignedAmounts.remove(member.id);
                                                    } else {
                                                      receiptItem.assignedAmounts[member.id] = receiptItem.assignedAmounts[member.id]! - 1;
                                                    }
                                                  }
                                                }),
                                              ),
                                            ),
                                        ],
                                      ),
                                    )
                                ],
                              ),
                            if (editInformation)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => showDialog(
                                      context: context,
                                      builder: (context) => AddOrEditReceiptItemDialog(
                                        currency: receiptInformation!.currency,
                                        onSave: (name, cost) => onInformationChanged(() {
                                          receiptInformation!.items.add(ReceiptItem(
                                            baseCost: cost,
                                            discount: 0,
                                            itemName: name,
                                            assignedAmounts: {},
                                          ));
                                          Navigator.of(context).pop();
                                        }),
                                      ),
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add, size: 20),
                                            SizedBox(width: 5),
                                            Text('receipt-scanner.add-item'.tr()),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('receipt-scanner.total'.tr()),
                            Text(receiptInformation!.totalCost.toMoneyString(receiptInformation!.currency, withSymbol: true)),
                          ],
                        ),
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

enum ReceiptItemDialogMode { add, edit }

class AddOrEditReceiptItemDialog extends StatelessWidget {
  final ReceiptItem? item;
  final Currency currency;
  final void Function(String name, double cost) onSave;
  final ReceiptItemDialogMode mode;
  AddOrEditReceiptItemDialog({
    super.key,
    this.item,
    required this.onSave,
    required this.currency,
  }) : mode = item == null ? ReceiptItemDialogMode.add : ReceiptItemDialogMode.edit {
    nameController.text = item?.itemName ?? '';
    costController.text = item?.cost.toMoneyString(currency) ?? '';
  }

  final TextEditingController nameController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void handleSave() {
    if (!(formKey.currentState?.validate.call() ?? false)) {
      return;
    }
    onSave(nameController.text, double.parse(costController.text.replaceAll(',', '.')));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mode == ReceiptItemDialogMode.add ? 'receipt-scanner.item-dialog.add' : 'receipt-scanner.item-dialog.edit',
                style: Theme.of(context).textTheme.titleMedium,
              ).tr(),
              SizedBox(height: 15),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'receipt-scanner.item-dialog.item.name'.tr(),
                ),
                validator: (value) => validateTextField([
                  isEmpty(value),
                ]),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: costController,
                decoration: InputDecoration(
                  labelText: 'receipt-scanner.item-dialog.item.cost'.tr(),
                  suffix: Text(currency.symbol),
                ),
                validator: (value) => validateTextField([
                  isEmpty(value),
                  notValidNumber(
                    value,
                    needsGreaterZero: true,
                  )
                ]),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 15),
              GradientButton.icon(
                icon: Icon(Icons.save),
                label: Text('save'.tr()),
                onPressed: handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditStoreNameDialog extends StatelessWidget {
  final String name;
  final void Function(String name) onSave;
  EditStoreNameDialog({
    super.key,
    required this.name,
    required this.onSave,
  }) {
    nameController.text = name;
  }

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 15),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'receipt-scanner.store-dialog.name'.tr(),
                ),
                validator: (value) => validateTextField([
                  isEmpty(value),
                ]),
              ),
              SizedBox(height: 15),
              GradientButton.icon(
                icon: Icon(Icons.save),
                label: Text('save'.tr()),
                onPressed: () => (formKey.currentState?.validate.call() ?? false) ? onSave(nameController.text) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
