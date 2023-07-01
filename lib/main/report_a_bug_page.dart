import 'package:csocsort_szamla/essentials/ad_management.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../essentials/http.dart';
import '../essentials/validation_rules.dart';
import '../essentials/widgets/future_success_dialog.dart';

class ReportABugPage extends StatefulWidget {
  final String? location;
  final DateTime? date;
  final String? error;
  ReportABugPage({this.error, this.date, this.location});
  @override
  _ReportABugPageState createState() => _ReportABugPageState();
}

class _ReportABugPageState extends State<ReportABugPage> {
  TextEditingController _bugController = new TextEditingController();
  TextEditingController _locationController = new TextEditingController();
  TextEditingController _detailsController = new TextEditingController();
  var _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'report_a_bug'.tr(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 5,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                DateFormat('yyyy/MM/dd - HH:mm')
                                    .format(widget.date == null ? now : widget.date!),
                                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            widget.error == null
                                ? TextFormField(
                                    validator: (value) => validateTextField([
                                      isEmpty(value),
                                    ]),
                                    keyboardType: TextInputType.multiline,
                                    minLines: 1,
                                    maxLines: 10,
                                    controller: _bugController,
                                    decoration: InputDecoration(
                                      hintText: 'bug'.tr(),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      widget.error!.tr(),
                                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                            SizedBox(
                              height: 15,
                            ),
                            widget.location == null
                                ? TextFormField(
                                    validator: (value) => validateTextField([
                                      isEmpty(value),
                                    ]),
                                    keyboardType: TextInputType.multiline,
                                    minLines: 1,
                                    maxLines: 10,
                                    controller: _locationController,
                                    decoration: InputDecoration(
                                      hintText: 'location'.tr(),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      widget.location!,
                                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                            SizedBox(
                              height: 15,
                            ),
                            TextFormField(
                              validator: (value) => validateTextField([]),
                              keyboardType: TextInputType.multiline,
                              minLines: 1,
                              maxLines: 10,
                              controller: _detailsController,
                              decoration: InputDecoration(
                                hintText: 'details'.tr(),
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: MediaQuery.of(context).viewInsets.bottom == 0,
                child: AdUnitForSite(site: 'report_bug'),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          foregroundColor: Theme.of(context).colorScheme.onTertiary,
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              String error = widget.error ?? _bugController.text;
              DateTime date = widget.date ?? now;
              String location = widget.location ?? _locationController.text;
              String details = _detailsController.text;
              showDialog(
                  builder: (context) => FutureSuccessDialog(
                        future: _postBug(error, date, location, details),
                        dataTrueText: 'bug_scf',
                        onDataTrue: () {
                          _onPostBug();
                        },
                      ),
                  barrierDismissible: false,
                  context: context);
            }
          },
          child: Icon(Icons.send),
        ),
      ),
    );
  }

  Future<bool> _postBug(String bugText, DateTime date, String location, String details) async {
    try {
      Map<String, dynamic> body = {
        "description": bugText +
            "\nTime: " +
            DateFormat('yyyy/MM/dd - HH:mm').format(date) +
            "\nLocation: " +
            location +
            "\nDetails: " +
            details,
      };

      await Http.post(uri: '/bug', body: body);
      Future.delayed(delayTime()).then((value) => _onPostBug());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onPostBug() {
    Navigator.pop(context);
    Navigator.pop(context);
  }
}
