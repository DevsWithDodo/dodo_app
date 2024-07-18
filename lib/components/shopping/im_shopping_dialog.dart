import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../helpers/validation_rules.dart';

class ImShoppingDialog extends StatefulWidget {
  @override
  _ImShoppingDialogState createState() => _ImShoppingDialogState();
}

class _ImShoppingDialogState extends State<ImShoppingDialog> {
  TextEditingController _controller = TextEditingController();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<BoolFutureOutput> _postImShopping(String store) async {
    try {
      Map<String, dynamic> body = {'store': store};
      await Http.post(
        body: body,
        uri: '/groups/' +
            context.read<UserState>().currentGroup!.id.toString() +
            '/send_shopping_notification',
      );
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'where'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                'im_shopping_explanation'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextFormField(
                  validator: (value) => validateTextField([
                    isEmpty(value),
                    minimalLength(value, 1),
                  ]),
                  decoration: InputDecoration(
                    labelText: 'store'.tr(),
                    prefixIcon: Icon(
                      Icons.shopping_basket,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  controller: _controller,
                  inputFormatters: [LengthLimitingTextInputFormatter(20)],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GradientButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        String store = _controller.text;
                        showFutureOutputDialog(
                          context: context,
                          future: _postImShopping(store),
                          outputCallbacks: {
                            BoolFutureOutput.True: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }
                          }
                        );
                      }
                    },
                    child: Icon(Icons.send),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
