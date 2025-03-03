import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DownloadExportDialog extends StatefulWidget {
  const DownloadExportDialog({super.key});

  @override
  State<DownloadExportDialog> createState() => _DownloadExportDialogState();
}

class _DownloadExportDialogState extends State<DownloadExportDialog> {
  late String url;

  Future<BoolFutureOutput> _downloadPdf() async {
    try {
      Response response = await Http.get(uri: generateUri(GetUriKeys.groupExportPdf, context));
      url = response.body;
      return BoolFutureOutput.True;
    } catch (_) {
      rethrow;
    }
  }

  Future<BoolFutureOutput> _downloadXls() async {
    try {
      Response response = await Http.get(uri: generateUri(GetUriKeys.groupExportXls, context));
      url = response.body;
      return BoolFutureOutput.True;
    } catch (_) {
      rethrow;
    }
  }

  void _onDownloadComplete(String url) {
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
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text('download_export_explanation'.tr(), style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
            Divider(),
            SizedBox(height: 15),
            Text(
              'download_xls'.tr(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5),
            Text('download_xls_explanation'.tr(), style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
            SizedBox(height: 10),
            GradientButton(
              child: Icon(Icons.table_chart),
              onPressed: () {
                showFutureOutputDialog(context: context, future: _downloadXls(), outputCallbacks: {BoolFutureOutput.True: () => _onDownloadComplete(url)});
              },
            ),
            SizedBox(height: 15),
            Column(
              children: [
                Text(
                  'download_pdf'.tr(),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text('download_pdf_explanation'.tr(), style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                SizedBox(height: 10),
                GradientButton(
                  onPressed: () {
                    showFutureOutputDialog(context: context, future: _downloadPdf(), outputCallbacks: {
                      BoolFutureOutput.True: () => _onDownloadComplete(url),
                    });
                  },
                  child: Icon(Icons.picture_as_pdf),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
