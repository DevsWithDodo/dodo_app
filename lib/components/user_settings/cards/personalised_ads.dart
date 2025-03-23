import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PersonalisedAds extends StatefulWidget {
  const PersonalisedAds({super.key});

  @override
  State<PersonalisedAds> createState() => _PersonalisedAdsState();
}

class _PersonalisedAdsState extends State<PersonalisedAds> {
  late bool _personalisedAds;

  @override
  void initState() {
    super.initState();
    _personalisedAds = context.read<UserNotifier>().user!.personalisedAds;
  }

  Future<BoolFutureOutput> _updatePersonalisedAds() async {
    try {
      if (context.read<UserNotifier>().user!.personalisedAds != _personalisedAds) {
        Map<String, dynamic> body = {"personalised_ads": _personalisedAds ? "on" : "off"};
        await Http.put(uri: '/user', body: body);
        if (mounted) context.read<UserNotifier>().setPersonalisedAds(_personalisedAds);
      }
      return BoolFutureOutput.True;
    } catch (_) {
      rethrow;
    }
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
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            )),
            SizedBox(
              height: 10,
            ),
            Center(
              child: Text(
                'use_personalised_ads_explanation'.tr(),
                style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                showFutureOutputDialog(
                  context: context,
                  future: _updatePersonalisedAds(),
                  outputCallbacks: {
                    FutureOutput.Error: () => setState(() => _personalisedAds = !value),
                  },
                );
              },
              title: Text(
                'use_personalised_ads'.tr(),
                style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}
