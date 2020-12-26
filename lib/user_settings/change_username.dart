import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../essentials/widgets/gradient_button.dart';
import 'change_username_dialog.dart';

class ChangeUsername extends StatefulWidget {
  @override
  _ChangeUsernameState createState() => _ChangeUsernameState();
}

class _ChangeUsernameState extends State<ChangeUsername> {
  var _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child:  Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: <Widget>[
              Center(
                child: Text(
                  'change_username'.tr(),
                  style:
                  Theme.of(context).textTheme.headline6,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Center(
                  child: Text(
                    'change_username_explanation'.tr(),
                    style:
                    Theme.of(context).textTheme.subtitle2,
                    textAlign: TextAlign.center,
                  )),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GradientButton(
                    child: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSecondary,),
                    onPressed: (){
                      showDialog(context: context, child: ChangeUsernameDialog());
                    },
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
