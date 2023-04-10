import 'package:csocsort_szamla/auth/registration/personalised_ads_page.dart';
import 'package:csocsort_szamla/essentials/widgets/currency_picker_dropdown.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../essentials/widgets/gradient_button.dart';

class CurrencyPage extends StatefulWidget {
  final String? inviteUrl;
  final String? username;
  final String? pin;
  CurrencyPage({this.inviteUrl, this.username, this.pin});
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
                          currencyChanged: (newCurrency) =>
                              setState(() => _defaultCurrency = newCurrency),
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
                        child: Icon(
                          Icons.arrow_left,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      GradientButton(
                        child: Icon(
                          Icons.arrow_right,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PersonalisedAdsPage(
                                inviteUrl: widget.inviteUrl,
                                username: widget.username,
                                pin: widget.pin,
                                defaultCurrency: _defaultCurrency,
                              ),
                            ),
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
