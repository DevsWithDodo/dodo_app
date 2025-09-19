import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csocsort_szamla/components/helpers/ad_unit.dart';
import 'package:csocsort_szamla/components/helpers/background_paint.dart';
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
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class JoinGroupPage extends HookWidget {
  final bool fromAuth;

  JoinGroupPage({super.key, this.fromAuth = false});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    User user = context.select<UserNotifier, User>(
      (provider) => provider.user!,
    );
    List<Group> groups = context.select<UserNotifier, List<Group>>(
      (provider) => provider.user!.groups,
    );

    final contextToken = context.select<InviteUrlState, String?>(
      (invite) => invite.inviteUrl?.split('/').lastOrNull,
    );
    final editingToken = useState(contextToken ?? "");
    final token = useState(contextToken ?? "");
    final TextEditingController nicknameController = useTextEditingController();
    final selectedGuestId = useState<int?>(null);
    final inviteTokenError = useState<String?>(null);
    final selectGuestError = useState<String?>(null);
    final loading = useState<bool>(false);
    final group = useState<Group?>(null);
    final timer = useRef<Timer?>(null);
    final guests = useState<List<Guest>?>(null);

    final joinGroup = useCallback(() async {
      try {
        String nickname = (selectedGuestId.value == null || selectedGuestId.value == -1)
            ? nicknameController.text[0].toUpperCase() + nicknameController.text.substring(1)
            : guests.value!.firstWhere((element) => element.id == selectedGuestId.value).nickname;
        Map<String, dynamic> body = {
          'invitation_token': token.value,
          'nickname': nickname,
          'merge_with_member_id': selectedGuestId.value,
        };
        Response response = await Http.post(uri: '/join', body: body);

        if (response.body == "") {
          return BoolFutureOutput.False;
        }
        Map<String, dynamic> decoded = jsonDecode(response.body);
        UserNotifier userProvider = context.read<UserNotifier>();
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
        rethrow;
      }
    }, [nicknameController.text, selectedGuestId.value, token.value]);

    void setEditingToken(String value) {
      editingToken.value = value;
      timer.value?.cancel();
      if (value != '') {
        timer.value = Timer(
          Duration(milliseconds: 500),
          () {
            token.value = value;
          },
        );
      }
    }

    useEffect(() {
      if (token.value == '') {
        inviteTokenError.value = null;
        loading.value = false;
        return;
      }
      inviteTokenError.value = null;
      loading.value = true;
      Http.get(uri: generateUri(GetUriKeys.groupFromToken, context, params: [token.value]), useCache: false)
          .then((response) {
        final decoded = jsonDecode(response.body);
        group.value = Group(
          currency: Currency.fromCode(decoded['currency']),
          name: decoded['name'],
          id: decoded['id'],
          adminApproval: decoded['admin_approval'] == 1,
        );
        guests.value = (decoded['guests'] as List)
            .map((e) => Guest(
                  id: e['id'],
                  groupId: e['member_data']['group_id'],
                  nickname: e['member_data']['nickname'],
                ))
            .toList();

        loading.value = false;
      }).catchError((error) {
        if (error is String) {
          inviteTokenError.value = error;
        } else {
          inviteTokenError.value = error.toString();
        }
        loading.value = false;
        group.value = null;
        guests.value = null;
      });
      return null;
    }, [token.value]);

    return PopScope(
      canPop: false, // onPopInvoked handles the navigation, TODO: refactor
      onPopInvoked: (didPop) {
        if (user.group != null) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MainPage()), (r) => false);
          context.read<InviteUrlState>().inviteUrl = null;
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
                    onPressed: () => Navigator.pushAndRemoveUntil(
                        context, MaterialPageRoute(builder: (context) => MainPage()), (r) => false),
                  )
                : null,
          ),
          drawer: !(fromAuth || user.group != null)
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall!
                                        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  if (user.username != null && user.username != '')
                                    Text(
                                      'hi'.tr(args: [user.username!]),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(color: Theme.of(context).colorScheme.primary),
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
                          context.read<UserNotifier>().logout();
                          Navigator.pushAndRemoveUntil(
                              context, MaterialPageRoute(builder: (context) => LoginOrRegisterPage()), (r) => false);
                        },
                      ),
                    ],
                  ),
                ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: BackgroundPaint(
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
                                  if (group.value == null)
                                    Column(
                                      children: [
                                        Visibility(
                                          visible:
                                              contextToken == null && !kIsWeb && (Platform.isAndroid || Platform.isIOS),
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
                                                      token.value = scanResult!;
                                                    }
                                                  } else {
                                                    Fluttertoast.showToast(
                                                        msg: 'no_camera_access'.tr(), toastLength: Toast.LENGTH_LONG);
                                                  }
                                                },
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'paste_code'.tr(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge!
                                                    .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                                            errorText: inviteTokenError.value,
                                          ),
                                          onChanged: setEditingToken,
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
                                                      group.value!.name,
                                                      style: Theme.of(context).textTheme.bodyMedium,
                                                    ),
                                                    Text(
                                                      "${group.value!.currency.code} (${group.value!.currency.symbol})",
                                                      style: Theme.of(context).textTheme.bodyMedium,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (guests.value?.isNotEmpty ?? false)
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
                                                                for (Guest guest in guests.value!)
                                                                  Padding(
                                                                    padding: const EdgeInsets.only(right: 5),
                                                                    child: ChoiceChip(
                                                                      label: Text(guest.nickname),
                                                                      selected: selectedGuestId.value == guest.id,
                                                                      onSelected: (value) {
                                                                        selectedGuestId.value =
                                                                            selectedGuestId.value == guest.id
                                                                                ? null
                                                                                : guest.id;
                                                                        selectGuestError.value = null;
                                                                      },
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                          Divider(),
                                                          ChoiceChip(
                                                            label: Text('invitation-field.none'.tr()),
                                                            selected: selectedGuestId.value == -1,
                                                            onSelected: (value) {
                                                              selectedGuestId.value = -1;
                                                              selectGuestError.value = null;
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (selectedGuestId.value == -1 || (guests.value?.isEmpty ?? false))
                                                Padding(
                                                  padding:
                                                      EdgeInsets.only(top: (guests.value?.isEmpty ?? false) ? 16 : 8),
                                                  child: TextFormField(
                                                    controller: nicknameController,
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
                                              if (selectGuestError.value != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8),
                                                  child: Text(
                                                    selectGuestError.value!,
                                                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                                          color: Theme.of(context).colorScheme.error,
                                                        ),
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
                                                token.value = '';
                                                editingToken.value = '';
                                                group.value = null;
                                                selectedGuestId.value = null;
                                                nicknameController.text = ''; // TODO: initial value from cache
                                                selectGuestError.value = null;
                                                guests.value = null;
                                                inviteTokenError.value = null;
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  if (loading.value) LinearProgressIndicator(),
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
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            onPressed: () {
              // Has not pasted invitation token yet/it hasn't loaded yet
              if (guests.value == null) {
                _formKey.currentState!.validate();
                return;
              }
              // Guest has not been selected and there are guests available
              if (guests.value!.isNotEmpty && selectedGuestId.value == null) {
                selectGuestError.value = 'invitation-field.select-guest.error'.tr();
                return;
              } else {
                selectGuestError.value = null;
              }
              // Form handles text field validation
              if (_formKey.currentState!.validate()) {
                showFutureOutputDialog(
                  context: context,
                  future: joinGroup(),
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

// class _JoinGroupPageState extends State<JoinGroupPage> {
//   late String token;
//   late User user;
//   Timer? timer;
//   String? initeTokenError;
//   bool loading = false;
//   Group? group;
//   List<Guest>? guests;
//   final TextEditingController _tokenController = TextEditingController();
//   int? selectedGuestId;
//   late TextEditingController _nicknameController;
//   String? selectGuestError;

//   @override
//   void initState() {
//     super.initState();
//     user = context.read<UserNotifier>().user!;
//     final inviteUrl = context.read<InviteUrlState>().inviteUrl;
//     _nicknameController = TextEditingController(); // TODO: initial value from cache
//     token = inviteUrl?.split('/').lastOrNull ?? "";
//     _tokenController.text = token;
//     checkInvitation();
//   }

//   final _formKey = GlobalKey<FormState>();

// }
