import 'dart:convert';
import 'dart:io';

import 'package:csocsort_szamla/components/groups/merge_on_join_page.dart';
import 'package:csocsort_szamla/components/helpers/ad_unit.dart';
import 'package:csocsort_szamla/components/helpers/drawer_tile.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/join_group/invitation_field.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/invite_url_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:csocsort_szamla/pages/app/create_group_page.dart';
import 'package:csocsort_szamla/pages/app/main_page.dart';
import 'package:csocsort_szamla/pages/app/user_settings_page.dart';
import 'package:csocsort_szamla/pages/auth/login_or_register_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class JoinGroupPage extends StatefulWidget {
  final bool fromAuth;
  final String? inviteURL;

  JoinGroupPage({this.fromAuth = false, this.inviteURL});

  @override
  _JoinGroupPageState createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  late String token;
  late TextEditingController _nicknameController;
  late User user;

  @override
  void initState() {
    super.initState();
    user = context.read<UserState>().user!;
    final inviteUrl = context.read<InviteUrlState>().inviteUrl;
    _nicknameController = TextEditingController(
        text: user.username[0].toUpperCase() + user.username.substring(1));
    token = inviteUrl?.split('/').lastOrNull ?? "";
  }

  var _formKey = GlobalKey<FormState>();

  Future<BoolFutureOutput> _joinGroup(String token, String nickname) async {
    try {
      Map<String, dynamic> body = {
        'invitation_token': token,
        'nickname': nickname
      };
      Response response = await Http.post(uri: '/join', body: body);

      if (response.body == "") {
        return BoolFutureOutput.False;
      }
      Map<String, dynamic> decoded = jsonDecode(response.body);
      UserState userProvider = context.read<UserState>();
      userProvider.setGroups(
          userProvider.user!.groups +
              [
                Group(
                  id: decoded['data']['group_id'],
                  name: decoded['data']['group_name'],
                  currency: Currency.fromCode(decoded['data']['currency']),
                )
              ],
          notify: false);
      userProvider.setGroup(userProvider.user!.groups.last);
      List<Member> guests = (decoded['data']['members'] as List<dynamic>)
          .where((element) => element['is_guest'] == 1)
          .map((e) => Member.fromJson(e))
          .toList();
      if (guests.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MergeOnJoinPage(
              guests: guests,
            ),
          ),
        );
      }
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (token == '') {
    //   _tokenController.text = widget.inviteURL != null ? widget.inviteURL!.split('/').removeLast() : '';
    // }
    User user = context.select<UserState, User>(
      (provider) => provider.user!,
    );
    List<Group> groups = context.select<UserState, List<Group>>(
      (provider) => provider.user!.groups,
    );

    return PopScope(
      canPop: false, // onPopInvoked handles the navigation, TODO: refactor
      onPopInvoked: (didPop) {
        if (user.group != null) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainPage()),
              (r) => false);
        }
      },
      child: Form(
        key: _formKey,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'join_group'.tr(),
            ),
            leading: (user.group != null)
                ? IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => MainPage()),
                        (r) => false),
                  )
                : null,
          ),
          drawer: !(widget.fromAuth || user.group != null)
              ? null
              : Drawer(
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.horizontal(right: Radius.circular(16)),
                  ),
                  elevation: 16,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: <Widget>[
                            DrawerHeader(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'DODO',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    'hi'.tr() + ' ' + user.username + '!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(),
                      DrawerTile(
                        icon: Icons.settings, 
                        label: 'settings'.tr(),
                        builder: (context) => UserSettingsPage(),
                      ),
                      DrawerTile(
                        icon: Icons.exit_to_app, 
                        label: 'logout'.tr(),
                        onTap: () {
                          context.read<UserState>().logout();
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginOrRegisterPage()),
                              (r) => false);
                        },
                      ),
                    ],
                  ),
                ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                Column(
                  children: [
                    Visibility(
                      visible: groups.length == 0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                        child: Text(
                          'join-group.first-hint'.tr(),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleSmall!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    if (context.watch<InviteUrlState>().inviteUrl == null)
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'no_group_yet'.tr(),
                            style:
                                Theme.of(context).textTheme.labelLarge!.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(width: 10),
                          FilledButton.tonal(
                            child: Text('create_group'.tr()),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CreateGroupPage()),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 500),
                        child: Column(
                          children: [
                            InvitationField(
                              token: token,
                              onChanged: (value) =>
                                  setState(() => token = value),
                              showScan: widget.inviteURL == null &&
                                  !kIsWeb &&
                                  (Platform.isAndroid || Platform.isIOS),
                              showReset: context.watch<InviteUrlState>().inviteUrl == null,
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            TextFormField(
                              validator: (value) => validateTextField([
                                isEmpty(value),
                                minimalLength(value, 1),
                              ]),
                              decoration: InputDecoration(
                                labelText: 'nickname_in_group'.tr(),
                                prefixIcon: Icon(
                                  Icons.account_circle,
                                ),
                              ),
                              controller: _nicknameController,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(15),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                AdUnit(site: 'join_group'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                String nickname = _nicknameController.text[0].toUpperCase() +
                    _nicknameController.text.substring(1);
                showFutureOutputDialog(
                  context: context,
                  future: _joinGroup(token, nickname),
                  outputCallbacks: {
                    BoolFutureOutput.True: () async {
                      EventBus.instance.fire(EventBus.refreshGroups);
                      EventBus.instance.fire(EventBus.refreshPayments);
                      EventBus.instance.fire(EventBus.refreshPurchases);
                      EventBus.instance.fire(EventBus.refreshShopping);
                      EventBus.instance.fire(EventBus.refreshStatistics);
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => MainPage()),
                        (r) => false,
                      );
                      final inviteState = context.read<InviteUrlState>();
                      if (inviteState.inviteUrl != null) {
                        inviteState.inviteUrl = null;
                      }
                    },
                  },
                  outputChildren: {
                    BoolFutureOutput.False: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                            child: Text(
                          'approve_still_needed'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        )),
                        SizedBox(
                          height: 15,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GradientButton(
                              child: Icon(Icons.check),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        )
                      ],
                    ),
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
