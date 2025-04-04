import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher_string.dart';

class VersionNotSupportedPage extends StatelessWidget {
  const VersionNotSupportedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'version_not_supported'.tr(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'version_not_supported_explanation'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 35,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GradientButton(
                  child: Text('download_new_version'.tr()),
                  onPressed: () {
                    launchUrlString(getShopURL());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
