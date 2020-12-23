import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../app_theme.dart';
import '../http_handler.dart';
import '../future_success_dialog.dart';

class ReportABugPage extends StatefulWidget {
  final String location;
  final DateTime date;
  final String error;
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
          flexibleSpace: Container(
            decoration: BoxDecoration(
                gradient: AppTheme.gradientFromTheme(Theme.of(context))
            ),
          ),
          title: Text('report_a_bug'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, ),),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('time_of_error'.tr(), style: Theme.of(context).textTheme.headline6),
                      SizedBox(height: 5,),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(DateFormat('yyyy/MM/dd - kk:mm').format(widget.date==null?now:widget.date), style: Theme.of(context).textTheme.bodyText1,),
                      ),
                      SizedBox(height: 15,),
                      Text('what_is_wrong'.tr(), style: Theme.of(context).textTheme.headline6,),
                      widget.error==null?
                      TextFormField(
                        validator: (text){
                          if(text.trim().length==0){
                            return 'field_empty'.tr();
                          }
                          return null;
                        },
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 10,
                        controller: _bugController,
                        decoration: InputDecoration(
                          labelText: 'bug'.tr(),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2),
                          ),
                        ),
                        style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).textTheme.bodyText1.color),
                        cursorColor: Theme.of(context).colorScheme.secondary,
                      )
                          :
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(widget.error.tr(), style: Theme.of(context).textTheme.bodyText1,),
                      ),
                      SizedBox(height: 15,),
                      Text('where_did_happen'.tr(), style: Theme.of(context).textTheme.headline6,),
                      widget.location==null?
                      TextFormField(
                        validator: (text){
                          if(text.trim().length==0){
                            return 'field_empty'.tr();
                          }
                          return null;
                        },
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 10,
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'location'.tr(),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2),
                          ),
                        ),
                        style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).textTheme.bodyText1.color),
                        cursorColor: Theme.of(context).colorScheme.secondary,
                      )
                          :
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(widget.location, style: Theme.of(context).textTheme.bodyText1,),
                      ),
                      SizedBox(height: 15,),
                      Text('anything_else'.tr(), style: Theme.of(context).textTheme.headline6,),
                      TextFormField(
                        validator: (text){
                          return null;
                        },
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 10,
                        controller: _detailsController,
                        decoration: InputDecoration(
                          labelText: 'details'.tr(),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2),
                          ),
                        ),
                        style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).textTheme.bodyText1.color),
                        cursorColor: Theme.of(context).colorScheme.secondary,
                      ),
                      SizedBox(height: 15,),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: (){
            if(_formKey.currentState.validate()){
              String error = widget.error??_bugController.text;
              DateTime date = widget.date??now;
              String location = widget.location??_locationController.text;
              String details = _detailsController.text;
              showDialog(
                barrierDismissible: false,
                context: context,
                child: FutureSuccessDialog(
                  future: _postBug(error, date, location, details),
                  dataTrueText: 'bug_scf',
                  onDataTrue: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                )
              );


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
        "error":bugText,
        "date":date,
        "location":location,
        "details":details
      };

      await httpPost(uri: '/bug', body: body, context: context);
      return true;
    } catch (_) {
      throw _;
    }
  }
}