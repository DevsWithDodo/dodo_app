import 'dart:math';

import 'package:csocsort_szamla/essentials/validation_rules.dart';
import 'package:csocsort_szamla/essentials/widgets/currency_picker_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:csocsort_szamla/essentials/http_handler.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String username;
  ForgotPasswordPage({required this.username});
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  Future<String?> _getPasswordReminder(String username) async {
    http.Response response = await httpGet(
        context: context,
        uri: generateUri(GetUriKeys.passwordReminder, args: [username]));
    Map<String, dynamic> decoded = jsonDecode(response.body);
    print(decoded);
    return decoded['data'];
  }

  TextEditingController groupCountController = TextEditingController();
  bool submittedGroupCount = false;

  String currency = '';
  List<List<TextEditingController>> groupQuestionsControllers = [];

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
            'need_answer_questions'.tr(),
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          SizedBox(height: 20),
          TextFormField(
            enabled: !submittedGroupCount,
            validator: (value) => validateTextField([
              isEmpty(value),
              notValidNumber(value, type: 'integer'),
            ]),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            controller: groupCountController,
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'group_count'.tr(),
              helperText:
                  groupCountController.text != '' ? 'group_count'.tr() : null,
              filled: true,
              prefixIcon: Icon(Icons.question_answer),
              suffixIcon: IconButton(
                icon: Icon(Icons.send),
                onPressed: () => setState(() => submittedGroupCount = true),
              ),
            ),
          ),
          Visibility(
            visible: submittedGroupCount,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () =>
                          setState(() => submittedGroupCount = false),
                      child: Text('reset'.tr()),
                    ),
                  ],
                ),
                CurrencyPickerDropdown(
                  defaultCurrencyValue: 'EUR',
                  currencyChanged: (value) => setState(() => currency = value),
                ),
                SizedBox(height: 20),
                ...(_generateQuestions())
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _generateQuestions() {
    List<Widget> questions = [];
    int groupCount = min(int.tryParse(groupCountController.text) ?? 0, 3);
    for (int i = 0; i < groupCount; i++) {
      questions.addAll([
        Text(
          'group_num'.tr(args: [(i + 1).toString()]),
          style: Theme.of(context)
              .textTheme
              .bodyLarge!
              .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        SizedBox(height: 10),
        TextFormField(
          validator: (value) => validateTextField([
            isEmpty(value),
          ]),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: 'group_name'.tr(),
            helperText:
                groupCountController.text != '' ? 'group_name'.tr() : null,
            prefixIcon: Icon(Icons.question_answer),
            suffixIcon: IconButton(
              icon: Icon(Icons.send),
              onPressed: () => setState(() => submittedGroupCount = true),
            ),
          ),
        ),
        SizedBox(height: 20),
        TextFormField(
          validator: (value) => validateTextField([
            isEmpty(value),
          ]),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: 'nickname'.tr(),
            helperText:
                groupCountController.text != '' ? 'nickname'.tr() : null,
            prefixIcon: Icon(Icons.question_answer),
            suffixIcon: IconButton(
              icon: Icon(Icons.send),
              onPressed: () => setState(() => submittedGroupCount = true),
            ),
          ),
        ),
        SizedBox(height: 20),
        TextFormField(
          validator: (value) => validateTextField([
            isEmpty(value),
          ]),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: 'balance'.tr(),
            helperText: groupCountController.text != '' ? 'balance'.tr() : null,
            prefixIcon: Icon(Icons.question_answer),
            suffixIcon: IconButton(
              icon: Icon(Icons.send),
              onPressed: () => setState(() => submittedGroupCount = true),
            ),
          ),
        ),
        SizedBox(height: 20),
        TextFormField(
          validator: (value) => validateTextField([
            isEmpty(value),
          ]),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: 'last_transaction_amount'.tr(),
            helperText: groupCountController.text != ''
                ? 'last_transaction_amount'.tr()
                : null,
            prefixIcon: Icon(Icons.question_answer),
            suffixIcon: IconButton(
              icon: Icon(Icons.send),
              onPressed: () => setState(() => submittedGroupCount = true),
            ),
          ),
        ),
        SizedBox(height: 20),
        TextFormField(
          validator: (value) => validateTextField([
            isEmpty(value),
          ]),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: 'last_transaction_date'.tr(),
            helperText: groupCountController.text != ''
                ? 'last_transaction_date'.tr()
                : null,
            prefixIcon: Icon(Icons.question_answer),
            suffixIcon: IconButton(
              icon: Icon(Icons.send),
              onPressed: () => setState(() => submittedGroupCount = true),
            ),
          ),
        ),
        Divider()
      ]);
    }
    return questions;
  }
}
