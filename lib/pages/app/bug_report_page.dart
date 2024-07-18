import 'package:csocsort_szamla/components/helpers/ad_unit.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class BugReportPage extends StatefulWidget {
  final String? location;
  final DateTime? date;
  final String? error;
  BugReportPage({this.error, this.date, this.location});
  @override
  _BugReportPageState createState() => _BugReportPageState();
}

class _BugReportPageState extends State<BugReportPage> {
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
                                      labelText: 'bug'.tr(),
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
                                      labelText: 'location'.tr(),
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
                                labelText: 'details'.tr(),
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
                child: AdUnit(site: 'report_bug'),
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
              showFutureOutputDialog(
                context: context,
                future: _postBug(error, date, location, details),
                outputCallbacks: {
                  BoolFutureOutput.True: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }
                }
              );
            }
          },
          child: Icon(Icons.send),
        ),
      ),
    );
  }

  Future<BoolFutureOutput> _postBug(String bugText, DateTime date, String location, String details) async {
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
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }
}
