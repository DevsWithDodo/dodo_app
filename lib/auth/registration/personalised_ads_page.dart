import 'package:csocsort_szamla/essentials/providers/user_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../essentials/widgets/gradient_button.dart';

class PersonalisedAdsPage extends StatefulWidget {
  final String username;
  final String pin;
  final String defaultCurrency;

  PersonalisedAdsPage({
    required this.username,
    required this.pin,
    required this.defaultCurrency,
  });

  @override
  State<PersonalisedAdsPage> createState() => _PersonalisedAdsPageState();
}

class _PersonalisedAdsPageState extends State<PersonalisedAdsPage> {
  bool _personalisedAds = false;
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
                          'we_are_concerned_your_privacy'.tr(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: TextButton(
                                onPressed: () => launchUrlString(
                                    'https://policies.google.com/privacy'),
                                child: Text(
                                  'personalised_ads'.tr(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(
                                        decoration: TextDecoration.underline,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Switch(
                              onChanged: (newValue) =>
                                  setState(() => _personalisedAds = newValue),
                              value: _personalisedAds,
                            )
                          ],
                        )
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
                        child: Icon(Icons.send),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => FutureSuccessDialog(
                              future: context.read<UserProvider>().register(
                                  widget.username,
                                  widget.pin,
                                  widget.defaultCurrency,
                                  _personalisedAds,
                                  context),
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
