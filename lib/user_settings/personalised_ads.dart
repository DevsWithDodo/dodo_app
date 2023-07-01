import 'package:csocsort_szamla/essentials/providers/user_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:csocsort_szamla/essentials/http.dart';
import 'package:provider/provider.dart';

class PersonalisedAds extends StatefulWidget {
  @override
  _PersonalisedAdsState createState() => _PersonalisedAdsState();
}

class _PersonalisedAdsState extends State<PersonalisedAds> {
  late bool _personalisedAds;

  @override
  void initState() {
    super.initState();
    _personalisedAds = context.read<UserProvider>().user!.personalisedAds;
  }

  Future<bool> _updatePersonalisedAds() async {
    try {
      if (context.read<UserProvider>().user!.personalisedAds != _personalisedAds) {
        Map<String, dynamic> body = {
          "personalised_ads": _personalisedAds ? "on" : "off"
        };
        await Http.put(uri: '/user', body: body);
        context.read<UserProvider>().setPersonalisedAds(_personalisedAds);
        Future.delayed(delayTime()).then((value) => _onUpdatePersonalisedAds());
        return true;
      } else {
        return Future.value(true);
      }
    } catch (_) {
      throw _;
    }
  }

  void _onUpdatePersonalisedAds() {
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Text(
              'use_personalised_ads'.tr(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            )),
            SizedBox(
              height: 10,
            ),
            Center(
              child: Text(
                'use_personalised_ads_explanation'.tr(),
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SwitchListTile(
              value: _personalisedAds,
              secondary: Icon(
                Icons.update,
                color: Theme.of(context).colorScheme.secondary,
              ),
              activeColor: Theme.of(context).colorScheme.secondary,
              onChanged: (value) {
                setState(() {
                  _personalisedAds = value;
                });
                showDialog(
                    builder: (context) => FutureSuccessDialog(
                          future: _updatePersonalisedAds(),
                          onDataTrue: () {
                            _onUpdatePersonalisedAds();
                          },
                          onDataFalse: () {
                            Navigator.pop(context);
                            setState(() {
                              _personalisedAds = !_personalisedAds;
                            });
                          },
                          onNoData: () {
                            Navigator.pop(context);
                            setState(() {
                              _personalisedAds = !_personalisedAds;
                            });
                          },
                          dataTrueText: 'update_personalised_ads_scf',
                        ),
                    context: context,
                    barrierDismissible: false);
              },
              title: Text(
                'use_personalised_ads'.tr(),
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}
