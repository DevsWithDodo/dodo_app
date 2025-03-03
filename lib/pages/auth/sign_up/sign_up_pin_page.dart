import 'package:csocsort_szamla/components/auth/pin_pad.dart';
import 'package:csocsort_szamla/pages/auth/sign_up/currency_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../components/helpers/gradient_button.dart';

class SignUpPinPage extends StatefulWidget {
  final String username;
  const SignUpPinPage({super.key, required this.username});
  @override
  State<SignUpPinPage> createState() => _SignUpPinPageState();
}

class _SignUpPinPageState extends State<SignUpPinPage> {
  bool _isPinInput = true;
  String _pin = '';
  String _pinConfirm = '';
  String? _validationText;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('register'.tr()),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ListView(
                      padding: EdgeInsets.only(left: 20, right: 20),
                      shrinkWrap: true,
                      children: <Widget>[
                        PinPad(
                          pin: _pin,
                          onPinChanged: (newPin) =>
                              setState(() => _pin = newPin),
                          pinConfirm: _pinConfirm,
                          onPinConfirmChanged: (newPin) =>
                              setState(() => _pinConfirm = newPin),
                          isPinInput: _isPinInput,
                          validationText: _validationText,
                          onValidationTextChanged: (newText) =>
                              setState(() => _validationText = newText),
                          pinLabel: 'registration.set-pin'.tr(),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GradientButton(
                        child: Icon(Icons.arrow_left),
                        onPressed: () {
                          if (_isPinInput) {
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              _isPinInput = true;
                            });
                          }
                        },
                      ),
                      GradientButton(
                        child: Icon(Icons.arrow_right),
                        onPressed: () {
                          if (_isPinInput) {
                            if (_pin.length == 4) {
                              setState(() {
                                _isPinInput = false;
                              });
                            } else {
                              setState(() {
                                _validationText = '4_needed';
                              });
                            }
                          } else {
                            if (_pinConfirm.length == 4) {
                              if (_pin == _pinConfirm) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CurrencyPage(
                                      username: widget.username,
                                      pin: _pin,
                                    ),
                                  ),
                                );
                              } else {
                                setState(() {
                                  _validationText = 'pins_not_match';
                                });
                              }
                            } else {
                              setState(() {
                                _validationText = '4_needed';
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
