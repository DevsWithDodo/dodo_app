import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

import '../../helpers/gradient_button.dart';

class ShareGroupDialog extends StatefulWidget {
  final String? inviteCode;
  const ShareGroupDialog({super.key, required this.inviteCode});

  @override
  State<ShareGroupDialog> createState() => _ShareGroupDialogState();
}

class _ShareGroupDialogState extends State<ShareGroupDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                'share'.tr(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            SizedBox(
              height: 15,
            ),
            Container(
              constraints: BoxConstraints(maxWidth: 400),
              padding: EdgeInsets.all(10),
              child: PrettyQrView.data(
                data: 'https://dodoapp.net/join/${widget.inviteCode}',
                decoration: PrettyQrDecoration(
                  shape: PrettyQrSmoothSymbol(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Divider(),
            Text(
              'share_url'.tr(),
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5),
            GradientButton(
              onPressed: () {
                Share.share(
                  'https://dodoapp.net/join/${widget.inviteCode!}',
                  subject: 'invitation_to_lender'.tr(),
                );
              },
              child: Icon(Icons.share),
            ),
          ],
        ),
      ),
    );
  }
}
