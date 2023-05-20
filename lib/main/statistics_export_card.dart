import 'dart:convert';

import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/widgets/error_message.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/groups/dialogs/download_export_dialog.dart';
import 'package:csocsort_szamla/main/in_app_purchase_page.dart';
import 'package:csocsort_szamla/main/statistics_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StatisticsDataExport extends StatefulWidget {
  const StatisticsDataExport();

  @override
  State<StatisticsDataExport> createState() => _StatisticsDataExportState();
}

class _StatisticsDataExportState extends State<StatisticsDataExport> {
  Future<Map<String, dynamic>>? _group;

  Future<Map<String, dynamic>> _getGroup() async {
    try {
      http.Response response = await httpGet(
          context: context, uri: generateUri(GetUriKeys.groupBoost));
      Map<String, dynamic> decoded = jsonDecode(response.body);
      return decoded['data'];
    } catch (_) {
      throw _;
    }
  }

  void showNoStatisticsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'statistics_not_available'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(color: Theme.of(context).colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text('statistics_not_available_explanation'.tr(),
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface),
                    textAlign: TextAlign.center),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GradientButton(
                      child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.onPrimary,
                              BlendMode.srcIn),
                          child: Image.asset(
                            'assets/dodo.png',
                            width: 25,
                          )),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => InAppPurchasePage()));
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _group = _getGroup();
  }

  @override
  void didUpdateWidget(covariant StatisticsDataExport oldWidget) {
    super.didUpdateWidget(oldWidget);
    _group = null;
    _group = _getGroup();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Text(
              'statistics_and_export'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(height: 10),
            FutureBuilder(
                future: _group,
                builder:
                    (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      bool statisticsEnabled =
                          snapshot.data!['is_boosted'] == 1 ||
                              snapshot.data!['trial'] == 1;
                      DateTime createdAt = DateTime.parse(
                              snapshot.data!['created_at'] ?? '2020-01-17')
                          .toLocal();
                      return Column(
                        children: [
                          Text(
                            'statistics_and_export_explanation_1'.tr(),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          GradientButton(
                            child: Icon(Icons.show_chart),
                            onPressed: () {
                              if (statisticsEnabled) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => StatisticsPage(
                                            groupCreation: createdAt)));
                              } else {
                                showNoStatisticsDialog();
                              }
                            },
                          ),
                          SizedBox(height: 15),
                          Text(
                            'statistics_and_export_explanation_2'.tr(),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          GradientButton(
                            child: Icon(Icons.download),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return DownloadExportDialog();
                                },
                              );
                            },
                          ),
                        ],
                      );
                    }
                    return ErrorMessage(
                        error: snapshot.error.toString(),
                        onTap: () {
                          _group = null;
                          _group = _getGroup();
                        });
                  }
                  return Center(child: CircularProgressIndicator());
                }),
          ],
        ),
      ),
    );
  }
}
