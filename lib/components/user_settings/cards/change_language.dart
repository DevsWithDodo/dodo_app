import 'package:csocsort_szamla/helpers/http.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguagePicker extends StatefulWidget {
  const LanguagePicker({super.key});

  @override
  State<LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<LanguagePicker> {
  List<Widget> _getLocales() {
    return context.supportedLocales.map((locale) {
      return LanguageElement(
        localeName: locale.languageCode,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
                child: Text(
              'change_language'.tr(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            )),
            SizedBox(height: 10),
            Center(
              child: Wrap(
                spacing: 5,
                children: _getLocales(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class LanguageElement extends StatefulWidget {
  final String? localeName;

  const LanguageElement({super.key, this.localeName});

  @override
  State<LanguageElement> createState() => _LanguageElementState();
}

class _LanguageElementState extends State<LanguageElement> {
  Future<bool> _changeLanguage(String? localeCode) {
    Map<String, dynamic> body = {'language': localeCode};
    Http.put(uri: '/user', body: body);
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        context.setLocale(Locale(widget.localeName!));
        _changeLanguage(widget.localeName);
      },
      child: Ink(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
            // gradient: (widget.localeName == context.locale.languageCode)
            //     ? AppTheme.gradientFromTheme(Theme.of(context))
            //     : LinearGradient(colors: [Colors.white, Colors.white]),
            color: (widget.localeName == context.locale.languageCode) ? Theme.of(context).colorScheme.secondary : ElevationOverlay.applyOverlay(context, Theme.of(context).colorScheme.surface, 10),
            borderRadius: BorderRadius.circular(15)),
        child: Center(
            child: Text(widget.localeName!.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: (widget.localeName == context.locale.languageCode) ? Theme.of(context).colorScheme.onSecondary : Theme.of(context).colorScheme.onSurfaceVariant,
                    ))),
      ),
    );
  }
}
