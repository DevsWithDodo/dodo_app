import 'dart:convert';

import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/widgets/confirm_choice_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/error_message.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/main/iapp_not_supported_dialog.dart';
import 'package:csocsort_szamla/main/in_app_purchase_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'main_group_page.dart';

class BoostGroup extends StatefulWidget {
  @override
  _BoostGroupState createState() => _BoostGroupState();
}

class _BoostGroupState extends State<BoostGroup> {
  Future<Map<String, dynamic>>? _boostNumber;

  Future<Map<String, dynamic>> _getBoostNumber() async {
    try {
      http.Response response = await httpGet(
          context: context,
          uri: generateUri(GetUriKeys.groupBoost,
              params: [currentGroupId.toString()]),
          useCache: false);
      Map<String, dynamic> decoded = jsonDecode(response.body);
      return decoded['data'];
    } catch (_) {
      throw _;
    }
  }

  Future<bool> _postBoost() async {
    try {
      await httpPost(
          context: context,
          uri: '/groups/' + currentGroupId.toString() + '/boost');
      Future.delayed(delayTime()).then((value) => _onPostBoost());
      return true;
    } catch (_) {
      throw _;
    }
  }

  Future<void> _onPostBoost() async {
    await clearGroupCache();
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => MainPage()), (r) => false);
  }

  @override
  void initState() {
    super.initState();
    _boostNumber = null;
    _boostNumber = _getBoostNumber();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _boostNumber,
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'boost_group'.tr(),
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        snapshot.data!['is_boosted'] == 0
                            ? 'boost_group_explanation'.tr()
                            : 'boost_group_boosted_explanation'.tr(),
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      Visibility(
                        visible: snapshot.data!['is_boosted'] == 0,
                        child: Column(
                          children: [
                            SizedBox(height: 20),
                            Text(
                              'available'.tr(args: [
                                snapshot.data!['available_boosts'].toString()
                              ]),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                            ),
                            SizedBox(height: 10),
                            GradientButton(
                              useSecondary: true,
                              child: Icon(Icons.insights),
                              onPressed: () {
                                if (snapshot.data!['available_boosts'] == 0) {
                                  if (isIAPPlatformEnabled) {
                                    Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    InAppPurchasePage()))
                                        .then((value) {
                                      setState(() {});
                                    });
                                  } else {
                                    showDialog(
                                        context: context,
                                        builder: (context) =>
                                            IAPPNotSupportedDialog());
                                  }
                                } else {
                                  showDialog(
                                          builder: (context) =>
                                              ConfirmChoiceDialog(
                                                choice: 'sure_boost',
                                              ),
                                          context: context)
                                      .then((value) {
                                    if (value ?? false) {
                                      showDialog(
                                          builder: (context) =>
                                              FutureSuccessDialog(
                                                future: _postBoost(),
                                                dataTrueText: 'boost_scf',
                                                onDataTrue: () {
                                                  _onPostBoost();
                                                },
                                              ),
                                          barrierDismissible: false,
                                          context: context);
                                    }
                                  });
                                }
                              },
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return ErrorMessage(
                  error: snapshot.error.toString(),
                  onTap: () {
                    setState(() {
                      _boostNumber = null;
                      _boostNumber = _getBoostNumber();
                    });
                  });
            }
          }
          return LinearProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          );
        });
  }
}
