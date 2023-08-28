import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';

class MemberPaymentMethods extends StatelessWidget {
  final Member member;

  const MemberPaymentMethods({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...member.paymentMethods
                ?.sorted((a, b) => a.priority ? -1 : 1)
                .map(
                  (paymentMethod) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              Icon(Icons.payment),
                              SizedBox(width: 5),
                              Flexible(
                                child: DefaultTextStyle(
                                  style: Theme.of(context).textTheme.bodyLarge!,
                                  child: Row(
                                    children: [
                                      Text("${paymentMethod.name}: "),
                                      Flexible(
                                        child: Text(
                                          "${paymentMethod.value}",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(width: 5),
                            paymentMethod.priority
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                  )
                                : SizedBox(),
                            IconButton.filledTonal(
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: paymentMethod.value));
                                showToast('clipboard.copy-successful'.tr());
                                Navigator.pop(context);
                              },
                              icon: Icon(Icons.copy),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .toList() ??
            [
              SizedBox(height: 10),
              Text(
                'payment-methods.no-payment-method'.tr(),
                textAlign: TextAlign.center,
              ),
            ],
        ...member.paymentMethods?.isEmpty ?? false
            ? [
                SizedBox(height: 10),
                Text(
                  'payment-methods.no-payment-method'.tr(),
                  textAlign: TextAlign.center,
                ),
              ]
            : [],
      ],
    );
  }
}
