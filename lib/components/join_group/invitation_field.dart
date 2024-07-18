import 'dart:async';
import 'dart:convert';

import 'package:csocsort_szamla/components/groups/qr_scanner_page.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

class InvitationField extends StatefulWidget {
  InvitationField({
      super.key,
      required this.token,
      required this.onChanged,
      required this.showScan,
      required this.showReset,
    });

  final bool showReset;
  final bool showScan;
  final String token;
  final Function(String) onChanged;

  @override
  State<InvitationField> createState() => _InvitationFieldState();
}

class _InvitationFieldState extends State<InvitationField> {
  Timer? timer;
  String? errorText;
  bool loading = false;
  Group? group;
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.text = widget.token;
    if (widget.token != '') {
      checkInvitation();
    }
  }

  @override
  void didUpdateWidget(covariant InvitationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token != oldWidget.token) {
      controller.text = widget.token;
      checkInvitation();
    }
  }

  void checkInvitation() async {
    if (widget.token == '') {
      setState(() {
        errorText = null;
        loading = false;
      });
      return;
    }
    try {
      setState(() {
        errorText = null;
        loading = true;
      });
      final response = await Http.get(
          uri: generateUri(GetUriKeys.groupFromToken, context,
              params: [widget.token]));
      final decoded = jsonDecode(response.body);
      group = Group(
        currency: Currency.fromCode(decoded['currency']),
        name: decoded['name'],
        id: decoded['id'],
        adminApproval: decoded['admin_approval'] == 1,
      );
    } catch (e) {
      if (e is String) {
        setState(() {
          errorText = e;
        });
      } else {
        setState(() {
          errorText = e.toString();
        });
      }
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Visibility(
          visible: group == null,
          child: Column(
            children: [
              Visibility(
                visible: widget.showScan,
                child: Column(
                  children: [
                    Text(
                      'scan_code'.tr(),
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 5),
                    GradientButton(
                      child: Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        if (await Permission.camera.request().isGranted) {
                          String? scanResult;
                          await Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                    builder: (context) => QRScannerPage()),
                              )
                              .then((value) => scanResult = value);
                          if (scanResult != null) {
                            widget.onChanged(scanResult!);
                            print('scanned: $scanResult');
                          }
                        } else {
                          Fluttertoast.showToast(
                              msg: 'no_camera_access'.tr(),
                              toastLength: Toast.LENGTH_LONG);
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    Text(
                      'paste_code'.tr(),
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(
                      height: 10,
                    )
                  ],
                ),
              ),
              TextFormField(
                validator: (value) => validateTextField([
                  isEmpty(value),
                ]),
                decoration: InputDecoration(
                  labelText: 'invitation'.tr(),
                  prefixIcon: Icon(
                    Icons.mail,
                  ),
                  errorText: errorText,
                ),
                onChanged: (value) {
                  timer?.cancel();
                  if (value != '') {
                    timer = Timer(Duration(milliseconds: 500), checkInvitation);
                  }
                  widget.onChanged(value);
                },
                controller: controller,
              ),
            ],
          ),
        ),
        if (group != null)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'invitation_field.selected_group'.tr(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group!.name,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              "${group!.currency.code} (${group!.currency.symbol})",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      if (widget.showReset)
                        TextButton(
                          child: Text('reset'.tr()),
                          onPressed: () {
                            setState(() {
                              group = null;
                            });
                            widget.onChanged('');
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Visibility(
          visible: loading,
          child: LinearProgressIndicator(),
        ),
      ],
    );
  }
}
