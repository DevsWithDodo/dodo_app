import 'dart:convert';

import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../essentials/validation_rules.dart';

class EditRequestDialog extends StatefulWidget {
  final String? textBefore;
  final int? requestId;
  EditRequestDialog({this.textBefore, this.requestId});

  @override
  _EditRequestDialogState createState() => _EditRequestDialogState();
}

class _EditRequestDialogState extends State<EditRequestDialog> {
  var _requestFormKey = GlobalKey<FormState>();

  TextEditingController _requestController = TextEditingController();

  late ShoppingRequest _updatedReqest;

  Future<BoolFutureOutput> _updateRequest(String newRequest) async {
    try {
      Map<String, dynamic> body = {'name': newRequest};
      http.Response response = await Http.put(
        uri: '/requests/' + widget.requestId.toString(),
        body: body,
      );
      _updatedReqest =
          ShoppingRequest.fromJson(jsonDecode(response.body)['data']);
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }

  void _buttonPressed() {
    if (_requestFormKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      String newRequest = _requestController.text;
      showFutureOutputDialog(
          context: context,
          future: _updateRequest(newRequest),
          outputCallbacks: {
            BoolFutureOutput.True: () async {
              await deleteCache( // TODO: event bus?
                uri: generateUri(
                  GetUriKeys.requests,
                  context,
                  queryParams: {
                    'group': context
                        .read<AppStateProvider>()
                        .currentGroup!
                        .id
                        .toString()
                  },
                ),
              );
              Navigator.pop(context);
              Navigator.pop(context, _updatedReqest);
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    _requestController.text = widget.textBefore!;
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Center(
              child: Text(
                'edit_request'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Form(
              key: _requestFormKey,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: TextFormField(
                  validator: (value) => validateTextField([
                    isEmpty(value),
                    minimalLength(value, 2),
                  ]),
                  controller: _requestController,
                  onFieldSubmitted: (value) => _buttonPressed(),
                  decoration: InputDecoration(
                    hintText: 'edited_request'.tr(),
                    prefixIcon: Icon(
                      Icons.shopping_cart,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(255),
                  ],
                ),
              ),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GradientButton(
                  onPressed: _buttonPressed,
                  child: Icon(Icons.check),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
