import 'package:csocsort_szamla/components/helpers/ad_unit.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/purchase/receipt_scanner/receipt_information_viewer.dart';
import 'package:csocsort_szamla/components/purchase/receipt_scanner/receipt_reader.dart';
import 'package:csocsort_szamla/helpers/color_generation.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum LargeView { pictureSelection, receiptInformation }

class ReceiptScannerPage extends StatefulWidget {
  final List<Member> members;
  final void Function(ReceiptInformation) onReceiptInformationReady;
  final ReceiptInformation? initialInformation;
  const ReceiptScannerPage({
    super.key,
    this.initialInformation,
    required this.members,
    required this.onReceiptInformationReady,
  });

  @override
  State<ReceiptScannerPage> createState() => _ReceiptScannerPageState();
}

class _ReceiptScannerPageState extends State<ReceiptScannerPage> with SingleTickerProviderStateMixin {
  ReceiptInformation? receiptInformation;
  LargeView largeView = LargeView.pictureSelection;
  static const smallFlex = 1;
  static const largeFlex = 8;

  AnimationController? _flexController;
  Animation<double>? _flexAnimation;

  bool editInformation = false;

  late Map<int, Color> memberColors;

  @override
  void initState() {
    super.initState();
    _flexController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _flexAnimation = Tween<double>(begin: largeFlex.toDouble(), end: smallFlex.toDouble()).animate(_flexController!);
    _flexController!.addListener(() => setState(() {}));
    memberColors = Map.fromIterables(
      widget.members.map((e) => e.id),
      generateDistinctColors(widget.members.length),
    );

    if (widget.initialInformation != null) {
      receiptInformation = widget.initialInformation;
      setLargeView(LargeView.receiptInformation);
    }
  }

  void setLargeView(LargeView view) {
    setState(() {
      largeView = view;
      if (view == LargeView.pictureSelection) {
        _flexController!.reverse();
      } else {
        _flexController!.forward(from: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Stack(
          clipBehavior: Clip.none,
          children: [
            Text('receipt-scanner.title'.tr()),
            Positioned(
              left: 1,
              bottom: -12,
              child: Text(
                'receipt-scanner.experimental'.tr(),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          ],
        ),
        forceMaterialTransparency: true,
      ),
      floatingActionButton: (receiptInformation?.items.where((item) => item.assignedAmounts.isNotEmpty).isNotEmpty ?? false)
          ? FloatingActionButton(
              onPressed: () => widget.onReceiptInformationReady(receiptInformation!),
              child: Icon(Icons.check),
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * _flexAnimation!.value / largeFlex,
                    ),
                    child: GestureDetector(
                      onTap: largeView != LargeView.pictureSelection ? () => setLargeView(LargeView.pictureSelection) : null,
                      child: ReceiptReader(
                        initialInformation: receiptInformation,
                        maxPictureSize: constraints.maxHeight * 0.65,
                        onInformation: (information) => setState(() {
                          receiptInformation = information;
                          if (information != null) setLargeView(LargeView.receiptInformation);
                        }),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: largeView != LargeView.receiptInformation ? () => setLargeView(LargeView.receiptInformation) : null,
                      child: Column(
                        children: [
                          if (receiptInformation != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: Column(
                                children: [
                                  Text(
                                    'receipt-scanner.warning'.tr(),
                                    style: Theme.of(context).textTheme.labelMedium!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 10),
                                  GradientButton.icon(
                                    onPressed: () => setState(() => editInformation = !editInformation),
                                    label: Text(editInformation ? 'save' : 'edit').tr(),
                                    icon: Icon(editInformation ? Icons.save : Icons.edit),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: ReceiptInformationViewer(
                              receiptInformation: receiptInformation,
                              editInformation: editInformation,
                              onInformationChanged: (callback) => setState(callback),
                              members: widget.members,
                              memberColors: memberColors,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              );
            }),
          ),
         Visibility(
            visible: MediaQuery.of(context).viewInsets.bottom == 0,
            child: AdUnit(site: 'receipt_scanner'),
          ),
        ],
      ),
    );
  }
}
