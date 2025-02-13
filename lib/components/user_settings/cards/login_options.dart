import 'package:csocsort_szamla/components/user_settings/cards/change_password_dialog.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginOptions extends StatefulWidget {
  @override
  _LoginOptionsState createState() => _LoginOptionsState();
}

class _LoginOptionsState extends State<LoginOptions> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserState>().user!;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Text(
                'user-settings.login-options'.tr(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 5,
            ),
            Center(
                child: Text(
              'user-settings.login-options.description'.tr(),
              style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            )),
            SizedBox(
              height: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Text(
                        'user-settings.login-options.pin'.tr(),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (user.hasPassword)
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.green,
                            size: 30,
                          ),
                          SizedBox(width: 10),
                          IconButton.filled(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => ChangePasswordDialog(),
                              );
                            },
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.edit),
                          ),
                        ],
                      )
                    else
                      TextButton(
                        onPressed: () {},
                        child: Text('user-settings.login-options.set-option'.tr()),
                      ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox.fromSize(
                      size: Size(35, 35),
                      child: Padding(
                        padding: EdgeInsets.all(5),
                        child: Image.asset(
                          'assets/google.png',
                        ),
                      ),
                    ),
                    if (user.googleConnected)
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        size: 30,
                      )
                    else
                      TextButton(
                        onPressed: () {},
                        child: Text('user-settings.login-options.social.link'.tr()),
                      ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        'assets/apple.png',
                        height: 35,
                        width: 35,
                      ),
                    ),
                    if (user.appleConnected)
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        size: 30,
                      )
                    else
                      TextButton(
                        onPressed: () {},
                        child: Text('user-settings.login-options.social.link'.tr()),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
