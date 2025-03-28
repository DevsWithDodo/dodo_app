import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PersonalisedAdsDialog extends StatefulWidget {
  const PersonalisedAdsDialog({super.key});

  @override
  State<PersonalisedAdsDialog> createState() => _PersonalisedAdsDialogState();
}

class _PersonalisedAdsDialogState extends State<PersonalisedAdsDialog> {
  bool _personalisedAds = false;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(15),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'personalised-ads.dialog.title'.tr(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'personalised-ads.dialog.subtitle'.tr(),
              style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'personalised-ads.dialog.question'.tr(),
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                Switch(
                  value: _personalisedAds,
                  onChanged: (value) => setState(() => _personalisedAds = value),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GradientButton(
              child: Icon(Icons.check),
              onPressed: () {
                showFutureOutputDialog(
                  context: context,
                  future: _updatePersonalisedAds(),
                  outputCallbacks: {
                    BoolFutureOutput.True: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
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
}
