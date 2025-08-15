import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/main/dialogs/iapp_not_supported_dialog.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/pages/app/store_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PremiumThemeDialog extends StatelessWidget {
  const PremiumThemeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'premium-theme-dialog.title'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('premium-theme-dialog.content'.tr()),
            const SizedBox(height: 16),
            GradientButton.icon(
              icon: const Icon(Icons.lock_open),
              label: Text('premium-theme-dialog.unlock'.tr()),
              onPressed: () {
                Navigator.pop(context);
                if (context.read<AppConfig>().isIAPPlatformEnabled) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => StorePage()));
                } else {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return IAPNotSupportedDialog();
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
