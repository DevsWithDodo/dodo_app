import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

class DownloadExportDialog extends StatefulWidget {
  @override
  _DownloadExportDialogState createState() => _DownloadExportDialogState();
}

class _DownloadExportDialogState extends State<DownloadExportDialog> {
  Future<bool> _downloadPdf() async {
    try {
      http.Response response =
          await httpGet(context: context, uri: generateUri(GetUriKeys.groupExportPdf));
      String url = response.body;
      Future.delayed(delayTime()).then((value) => _onDownloadPdf(url));
      return true;
    } catch (_) {
      throw _;
    }
  }

  Future<bool> _downloadXls() async {
    try {
      http.Response response =
          await httpGet(context: context, uri: generateUri(GetUriKeys.groupExportXls));
      String url = response.body;
      Future.delayed(delayTime()).then((value) => _onDownloadXls(url));
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onDownloadPdf(String url) {
    Navigator.pop(context);
    launchUrlString(url, mode: LaunchMode.externalApplication);
  }

  void _onDownloadXls(String url) {
    Navigator.pop(context);
    launchUrlString(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'download_export'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text('download_export_explanation'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            Divider(),
            SizedBox(height: 15),
            Text(
              'download_xls'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(fontSize: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5),
            Text('download_xls_explanation'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            SizedBox(height: 10),
            GradientButton(
              child: Icon(Icons.table_chart, color: Theme.of(context).colorScheme.onPrimary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return FutureSuccessDialog(
                      future: _downloadXls(),
                    );
                  },
                );
              },
            ),
            SizedBox(height: 15),
            Column(
              children: [
                Text(
                  'download_pdf'.tr(),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontSize: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text('download_pdf_explanation'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
                SizedBox(height: 10),
                GradientButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return FutureSuccessDialog(
                          future: _downloadPdf(),
                        );
                      },
                    );
                  },
                  child: Icon(Icons.picture_as_pdf, color: Theme.of(context).colorScheme.onPrimary),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
