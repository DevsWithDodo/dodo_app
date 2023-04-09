import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

import '../../essentials/widgets/gradient_button.dart';

class ShareGroupDialog extends StatefulWidget {
  final String inviteCode;
  ShareGroupDialog({@required this.inviteCode});

  @override
  _ShareGroupDialogState createState() => _ShareGroupDialogState();
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
                style: Theme.of(context).textTheme.titleLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            SizedBox(
              height: 15,
            ),
            PrettyQr(
              data: 'dodo://${widget.inviteCode}',
              roundEdges: true,
              size: MediaQuery.of(context).size.width > 350 ? 250 : 120,
              elementColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(
              height: 10,
            ),
            Divider(),
            Text(
              'share_url'.tr(),
              style: Theme.of(context).textTheme.bodyLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5),
            GradientButton(
              onPressed: () {
                Share.share(
                  'https://dodoapp.net/join/' + widget.inviteCode,
                  subject: 'invitation_to_lender'.tr(),
                );
              },
              child: Icon(
                Icons.share,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
