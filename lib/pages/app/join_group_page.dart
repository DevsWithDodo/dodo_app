import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csocsort_szamla/components/helpers/ad_unit.dart';
import 'package:csocsort_szamla/components/helpers/drawer_tile.dart';
import 'package:csocsort_szamla/components/helpers/future_output_dialog.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/invite_url_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/validation_rules.dart';
import 'package:csocsort_szamla/pages/app/create_group_page.dart';
import 'package:csocsort_szamla/pages/app/customize_page.dart';
import 'package:csocsort_szamla/pages/app/main_page.dart';
import 'package:csocsort_szamla/pages/app/qr_scanner_page.dart';
import 'package:csocsort_szamla/pages/app/user_settings_page.dart';
import 'package:csocsort_szamla/pages/auth/login_or_register_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';
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
  late User user;
  Timer? timer;
  String? errorText;
  bool loading = false;
  Group? group;
  List<Guest>? guests;
  TextEditingController _tokenController = TextEditingController();
  int? selectedGuestId = null;
  late TextEditingController _nicknameController;

  @override
  void initState() {
    super.initState();
    user = context.read<UserState>().user!;
    final inviteUrl = context.read<InviteUrlState>().inviteUrl;
    _nicknameController = TextEditingController(); // TODO: initial value from cache
    token = inviteUrl?.split('/').lastOrNull ?? "";
    checkInvitation();
  }

  var _formKey = GlobalKey<FormState>();

  Future<BoolFutureOutput> _joinGroup(String token, String nickname, int? selectedGuestId) async {
    try {
      Map<String, dynamic> body = {
        'invitation_token': token,
        'nickname': nickname,
        'merge_with_member_id': selectedGuestId,
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
      return BoolFutureOutput.True;
    } catch (_) {
      throw _;
    }
  }

  void checkInvitation() async {
    if (token == '') {
      setState(() {
        errorText = null;
        loading = false;
      });
      return;
    }
    try {
      setState(() {
        errorText = null;
        loading = true;
      });
      final response = await Http.get(uri: generateUri(GetUriKeys.groupFromToken, context, params: [token]), useCache: false);
      final decoded = jsonDecode(response.body);
      group = Group(
        currency: Currency.fromCode(decoded['currency']),
        name: decoded['name'],
        id: decoded['id'],
        adminApproval: decoded['admin_approval'] == 1,
      );
      guests = (decoded['guests'] as List)
          .map((e) => Guest(
                id: e['id'],
                groupId: e['member_data']['group_id'],
                nickname: e['member_data']['nickname'],
              ))
          .toList();
    } catch (e) {
      if (e is String) {
        setState(() {
          errorText = e;
        });
      } else {
        setState(() {
          errorText = e.toString();
        });
      }
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MainPage()), (r) => false);
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
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MainPage()), (r) => false),
                  )
                : null,
          ),
          drawer: !(widget.fromAuth || user.group != null)
              ? null
              : Drawer(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
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
                                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  if (user.username != null)
                                    Text(
                                      'hi'.tr(args: [user.username!]),
                                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(),
                      DrawerTile(
                        icon: Icons.palette,
                        label: 'customization'.tr(),
                        builder: (context) => CustomizePage(),
                      ),
                      DrawerTile(
                        dense: true,
                        icon: Icons.account_circle,
                        label: 'profile'.tr(),
                        builder: (context) => UserSettingsPage(),
                      ),
                      DrawerTile(
                        icon: Icons.exit_to_app,
                        label: 'logout'.tr(),
                        onTap: () {
                          context.read<UserState>().logout();
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginOrRegisterPage()), (r) => false);
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
                    if (groups.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: Text(
                          'join-group.first-hint'.tr(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    if (context.watch<InviteUrlState>().inviteUrl == null)
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'no_group_yet'.tr(),
                            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(width: 10),
                          FilledButton.tonal(
                            child: Text('create_group'.tr()),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CreateGroupPage()),
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
                            Column(
                              children: [
                                if (group == null)
                                  Column(
                                    children: [
                                      Visibility(
                                        visible: widget.inviteURL == null && !kIsWeb && (Platform.isAndroid || Platform.isIOS),
                                        child: Column(
                                          children: [
                                            GradientButton.icon(
                                              label: Text('join-group.qr-scan'.tr()),
                                              icon: Icon(Icons.qr_code_scanner),
                                              onPressed: () async {
                                                if (await Permission.camera.request().isGranted) {
                                                  String? scanResult;
                                                  await Navigator.of(context)
                                                      .push(
                                                        MaterialPageRoute(builder: (context) => QRScannerPage()),
                                                      )
                                                      .then((value) => scanResult = value);
                                                  if (scanResult != null) {
                                                    setState(() => token = scanResult!);
                                                    print('scanned: $scanResult');
                                                    checkInvitation();
                                                  }
                                                } else {
                                                  Fluttertoast.showToast(msg: 'no_camera_access'.tr(), toastLength: Toast.LENGTH_LONG);
                                                }
                                              },
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              'paste_code'.tr(),
                                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            )
                                          ],
                                        ),
                                      ),
                                      TextFormField(
                                        validator: (value) => validateTextField([
                                          isEmpty(value),
                                        ]),
                                        decoration: InputDecoration(
                                          labelText: 'invitation'.tr(),
                                          prefixIcon: Icon(
                                            Icons.mail,
                                          ),
                                          errorText: errorText,
                                        ),
                                        onChanged: (value) {
                                          timer?.cancel();
                                          if (value != '') {
                                            timer = Timer(
                                              Duration(milliseconds: 200),
                                              checkInvitation,
                                            );
                                          }
                                          setState(() => token = value);
                                        },
                                        controller: _tokenController,
                                      ),
                                    ],
                                  )
                                else
                                  Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: Theme.of(context).colorScheme.surfaceContainer,
                                        ),
                                        padding: EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'invitation-field.selected-group'.tr(),
                                              style: Theme.of(context).textTheme.titleSmall,
                                            ),
                                            SizedBox(height: 5),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 5),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(
                                                    group!.name,
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                  Text(
                                                    "${group!.currency.code} (${group!.currency.symbol})",
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (guests?.isNotEmpty ?? false)
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(height: 10),
                                                  Text(
                                                    'invitation-field.who-are-you'.tr(),
                                                    style: Theme.of(context).textTheme.titleSmall,
                                                  ),
                                                  SizedBox(height: 5),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 5),
                                                    child: Column(
                                                      children: [
                                                        SingleChildScrollView(
                                                          scrollDirection: Axis.horizontal,
                                                          child: Row(
                                                            children: [
                                                              for (Guest guest in guests!)
                                                                Padding(
                                                                  padding: const EdgeInsets.only(right: 5),
                                                                  child: ChoiceChip(
                                                                    label: Text(guest.nickname),
                                                                    selected: selectedGuestId == guest.id,
                                                                    onSelected: (value) => setState(() {
                                                                      selectedGuestId = selectedGuestId == guest.id ? null : guest.id;
                                                                    }),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                        Divider(),
                                                        ChoiceChip(
                                                          label: Text('invitation-field.none'.tr()),
                                                          selected: selectedGuestId == -1,
                                                          onSelected: (value) => setState(() {
                                                            selectedGuestId = -1;
                                                          }),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (selectedGuestId == -1 || selectedGuestId == null || (guests?.isEmpty ?? false))
                                              Padding(
                                                padding: EdgeInsets.only(top: (guests?.isEmpty ?? false) ? 16 : 8),
                                                child: TextFormField(
                                                  controller: _nicknameController,
                                                  decoration: InputDecoration(
                                                    labelText: 'nickname-in-group'.tr(),
                                                  ),
                                                  validator: (value) => validateTextField([
                                                    isEmpty(value),
                                                  ]),
                                                  inputFormatters: [
                                                    LengthLimitingTextInputFormatter(15),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (context.watch<InviteUrlState>().inviteUrl == null)
                                        Positioned(
                                          right: 4,
                                          top: 4,
                                          child: IconButton.outlined(
                                            iconSize: 16,
                                            visualDensity: VisualDensity.compact,
                                            icon: Icon(Icons.close),
                                            onPressed: () {
                                              setState(() {
                                                _tokenController.clear();
                                                token = '';
                                                group = null;
                                                selectedGuestId = null;
                                                _nicknameController.text = ''; // TODO: initial value from cache
                                              });
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                if (loading) LinearProgressIndicator(),
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
              if (_formKey.currentState!.validate() && (selectedGuestId != null || (guests?.isEmpty ?? true))) {
                String nickname = (selectedGuestId == null || selectedGuestId == -1) ? _nicknameController.text[0].toUpperCase() + _nicknameController.text.substring(1) : guests!.firstWhere((element) => element.id == selectedGuestId).nickname;
                showFutureOutputDialog(
                  context: context,
                  future: _joinGroup(token, nickname, selectedGuestId == -1 ? null : selectedGuestId),
                  outputCallbacks: {
                    BoolFutureOutput.True: () async {
                      EventBus.instance.fire(EventBus.refreshGroups);
                      EventBus.instance.fire(EventBus.refreshPayments);
                      EventBus.instance.fire(EventBus.refreshPurchases);
                      EventBus.instance.fire(EventBus.refreshShopping);
                      EventBus.instance.fire(EventBus.refreshStatistics);
                      EventBus.instance.fire(EventBus.refreshGroupInfo);
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
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
