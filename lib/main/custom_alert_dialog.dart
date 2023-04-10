import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final Map<String, dynamic> content;
  final Widget? actions;
  final bool centerBody;
  CustomAlertDialog(
      {required this.content, this.actions, this.centerBody = false}) {
    assert(content.containsKey('title'));
    assert(content.containsKey('body'));
    assert((content['body'] as List).length == 0 ||
        content['body'] is List<String>);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.all(15),
        children: [
          Text(
            (content['title'] as String?)!.tr(),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Column(
            crossAxisAlignment: centerBody
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: (content['body'] as List<String>)
                .map((body) => Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Text(
                        body.tr(),
                        textAlign:
                            centerBody ? TextAlign.center : TextAlign.start,
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: 15),
          actions ?? Container()
        ],
      ),
    );
  }
}
