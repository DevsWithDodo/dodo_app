import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:csocsort_szamla/essentials/http_handler.dart';

import '../essentials/widgets/error_message.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String username;
  ForgotPasswordPage({@required this.username});
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  Future<String> _getPasswordReminder(String username) async {
    http.Response response = await httpGet(
        context: context, uri: generateUri(GetUriKeys.passwordReminder, args: [username]));
    Map<String, dynamic> decoded = jsonDecode(response.body);
    print(decoded);
    return decoded['data'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('forgot_password'.tr()),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Text(
            'your_password_reminder'.tr(),
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          SizedBox(
            height: 20,
          ),
          FutureBuilder(
            future: _getPasswordReminder(widget.username),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  return Text(
                    snapshot.data,
                    style: Theme.of(context).textTheme.bodyText1,
                  );
                } else {
                  return ErrorMessage(
                    error: snapshot.error.toString(),
                    locationOfError: 'password_reminder',
                    callback: () {
                      setState(() {});
                    },
                  );
                }
              }
              return Center(child: CircularProgressIndicator());
            },
          )
        ],
      ),
    );
  }
}
