import 'package:csocsort_szamla/pages/app/bug_report_page.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ErrorMessage extends StatelessWidget {
  final String? error;
  final Function onTap;
  final String? errorLocation;

  ///Displays an error message with the given [error].
  ///When tapped on, the [onTap] method is called.
  ///If the error isn't 'no internet', the user can decide to report the error.
  ///Then the 'report a bug' is navigated to with the given [errorLocation] as the location.
  const ErrorMessage({super.key, required this.error, required this.onTap, this.errorLocation});
  @override
  Widget build(BuildContext context) {
    return InkWell(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Text(error!.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.error)),
              Visibility(
                visible: error != 'cannot_connect',
                child: Column(
                  children: [
                    Divider(),
                    Text('if_not_working'.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: Theme.of(context).colorScheme.onSurface)),
                    SizedBox(
                      height: 5,
                    ),
                    TextButton(
                      onPressed: () {
                        DateTime now = DateTime.now();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BugReportPage(
                              error: error,
                              date: now,
                              location: errorLocation,
                            ),
                          ),
                        );
                      },
                      child: Text('report_this_error'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(color: Theme.of(context).colorScheme.primary)),
                      // color: Theme.of(context).textTheme.bodyText1.color,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          onTap();
        });
  }
}
