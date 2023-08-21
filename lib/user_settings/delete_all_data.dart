import 'package:csocsort_szamla/auth/login_or_register_page.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/widgets/confirm_choice_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../essentials/widgets/gradient_button.dart';

class DeleteAllData extends StatefulWidget {
  @override
  _DeleteAllDataState createState() => _DeleteAllDataState();
}

class _DeleteAllDataState extends State<DeleteAllData> {
  Future<BoolFutureOutput> _deleteAllData() async {
    try {
      await Http.delete(uri: '/user');
      await clearAllCache();
      AppStateProvider userProvider = context.read<AppStateProvider>();
      userProvider.setGroup(null);
      userProvider.setGroups([]);
      userProvider.setUser(null);
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Text(
              'delete_all_data'.tr(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            )),
            SizedBox(
              height: 10,
            ),
            Center(
              child: Text(
                'delete_all_data_explanation'.tr(),
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GradientButton(
                  child: Icon(Icons.delete_forever),
                  onPressed: () {
                    showDialog(
                            builder: (context) => ConfirmChoiceDialog(
                                  choice: 'sure_user_delete',
                                ),
                            context: context)
                        .then((value) {
                      if (value ?? false) {
                        showFutureOutputDialog(
                          context: context,
                          future: _deleteAllData(),
                          outputCallbacks: {
                            BoolFutureOutput.True: () =>
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) => LoginOrRegisterPage()),
                                  (r) => false,
                                ),
                          },
                        );
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
