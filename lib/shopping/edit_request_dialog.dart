import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../essentials/validation_rules.dart';

class EditRequestDialog extends StatefulWidget {
  final String textBefore;
  final int requestId;
  EditRequestDialog({this.textBefore, this.requestId});

  @override
  _EditRequestDialogState createState() => _EditRequestDialogState();
}

class _EditRequestDialogState extends State<EditRequestDialog> {
  var _requestFormKey = GlobalKey<FormState>();

  TextEditingController _requestController = TextEditingController();

  Future<bool> _updateRequest(String newRequest) async {
    try {
      Map<String, dynamic> body = {'name': newRequest};
      await httpPut(
        uri: '/requests/' + widget.requestId.toString(),
        context: context,
        body: body,
      );
      Future.delayed(delayTime()).then((value) => _onUpdateRequest());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onUpdateRequest() {
    deleteCache(uri: generateUri(GetUriKeys.requests));
    Navigator.pop(context);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    _requestController.text = widget.textBefore;
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
            SizedBox(
              height: 15,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GradientButton(
                    onPressed: () {
                      if (_requestFormKey.currentState.validate()) {
                        FocusScope.of(context).unfocus();
                        String newRequest = _requestController.text;
                        showDialog(
                            builder: (context) => FutureSuccessDialog(
                                  future: _updateRequest(newRequest),
                                  onDataTrue: () {
                                    _onUpdateRequest();
                                  },
                                  dataTrueText: 'request_edit_scf',
                                ),
                            barrierDismissible: false,
                            context: context);
                      }
                    },
                    child: Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
