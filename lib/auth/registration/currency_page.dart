import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/providers/invite_url_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/currency_picker_dropdown.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/groups/join_group.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../essentials/widgets/gradient_button.dart';

class CurrencyPage extends StatefulWidget {
  final String username;
  final String pin;
  CurrencyPage({required this.username, required this.pin});
  @override
  State<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> {
  String _defaultCurrency = 'EUR';
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
                  child: Center(
                    child: ListView(
                      padding: EdgeInsets.only(left: 20, right: 20),
                      shrinkWrap: true,
                      children: <Widget>[
                        Text(
                          'your_currency'.tr(),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        CurrencyPickerDropdown(
                          defaultCurrencyValue: _defaultCurrency,
                          currencyChanged: (newCurrency) => setState(() => _defaultCurrency = newCurrency),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GradientButton(
                        child: Icon(Icons.arrow_left),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      GradientButton(
                        child: Icon(Icons.arrow_right),
                        onPressed: () {
                          showFutureOutputDialog(
                            context: context,
                            future: context.read<AppStateProvider>().register(
                                  widget.username,
                                  widget.pin,
                                  _defaultCurrency,
                                  context,
                                ),
                            outputCallbacks: {
                              BoolFutureOutput.True: () => Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => JoinGroup(
                                        fromAuth: true,
                                        inviteURL: context.read<InviteUrlProvider>().inviteUrl,
                                      ),
                                    ),
                                    (r) => false,
                                  ),
                            },
                          );
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
