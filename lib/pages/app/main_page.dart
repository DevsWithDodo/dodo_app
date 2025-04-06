import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:connectivity_widget/connectivity_widget.dart';
import 'package:csocsort_szamla/components/groups/dialogs/share_group_dialog.dart';
import 'package:csocsort_szamla/components/groups/group_info.dart';
import 'package:csocsort_szamla/components/helpers/drawer_tile.dart';
import 'package:csocsort_szamla/components/history/history.dart';
import 'package:csocsort_szamla/components/main/main_dialog_builder.dart';
import 'package:csocsort_szamla/components/main/statistics_export_card.dart';
import 'package:csocsort_szamla/components/shopping/shopping_list.dart';
import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/helpers/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/pages/app/create_group_page.dart';
import 'package:csocsort_szamla/pages/app/customize_page.dart';
import 'package:csocsort_szamla/pages/app/join_group_page.dart';
import 'package:csocsort_szamla/pages/app/purchase_page.dart';
import 'package:csocsort_szamla/pages/app/store_page.dart';
import 'package:csocsort_szamla/pages/app/user_settings_page.dart';
import 'package:csocsort_szamla/pages/auth/login_or_register_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/balance/balances.dart';
import '../../components/helpers/ad_unit.dart';
import '../../components/helpers/error_message.dart';
import '../../components/main/dialogs/iapp_not_supported_dialog.dart';
import '../../helpers/currencies.dart';
import '../../helpers/http.dart';
import '../../helpers/models.dart';

class IsOnlineProvider extends ChangeNotifier {
  late bool _isOnline;
  IsOnlineProvider({required bool isOnline}) {
    _isOnline = isOnline;
  }

  bool get isOnline => _isOnline;

  void setIsOnline(bool isOnline) {
    _isOnline = isOnline;
    notifyListeners();
  }
}

class MainPage extends StatefulWidget {
  final int selectedHistoryIndex;
  final int selectedIndex;
  final String? scrollTo;

  const MainPage({super.key, this.selectedHistoryIndex = 0, this.selectedIndex = 0, this.scrollTo});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  SharedPreferences? prefs;
  Future<List<Group>>? _groups;
  Future<dynamic>? _sumBalance;
  Future<String>? _invitation;

  TabController? _tabController;
  int _selectedIndex = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? scrollTo;

  Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<List<Group>> _getGroups() async {
    if (!mounted) {
      return [];
    }
    Response response = await Http.get(uri: generateUri(GetUriKeys.groups, context), overwriteCache: true);
    Map<String, dynamic> decoded = jsonDecode(response.body);
    UserNotifier userProvider = context.read<UserNotifier>();
    List<Group> groups = [];
    for (var group in decoded['data']) {
      groups.add(Group(
        name: group['group_name'],
        id: group['group_id'],
        currency: Currency.fromCode(group['currency']),
      ));
    }
    userProvider.setGroups(groups, notify: false);
    //The group ID cannot change, but the group name and currency can change
    Group? group = groups.firstWhereOrNull(
      (group) => (group.id == userProvider.currentGroup!.id && (group.name != userProvider.currentGroup!.name || group.currency != userProvider.currentGroup!.currency)),
    ); // Only notify if the current group's name or currency changed
    if (group != null) {
      userProvider.setGroup(group);
    }
    return groups;
  }

  Future<dynamic> _getSumBalance() async {
    try {
      Response response = await Http.get(uri: generateUri(GetUriKeys.userBalanceSum, context));
      Map<String, dynamic> decoded = jsonDecode(response.body);
      return decoded['data'];
    } catch (_) {
      rethrow;
    }
  }

  Future<String> _getInvitation() async {
    try {
      Response response = await Http.get(
        uri: generateUri(GetUriKeys.groupCurrent, context),
        useCache: false,
      );
      Map<String, dynamic> decoded = jsonDecode(response.body);
      return decoded['data']['invitation'];
    } catch (_) {
      rethrow;
    }
  }

  List<Widget> _generateListTiles(List<Group> groups) {
    int currentGroupId = context.watch<UserNotifier>().user!.group!.id;
    final theme = Theme.of(context);
    return groups
        .map<Widget>((group) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                tileColor: group.id == currentGroupId ? theme.colorScheme.secondaryContainer : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
                title: Text(
                  group.name,
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: group.id == currentGroupId ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () async {
                  context.read<UserNotifier>().setGroup(group);
                  setState(() {
                    _selectedIndex = 0;
                    _tabController!.animateTo(_selectedIndex);
                  });
                  final bus = EventBus.instance;
                  bus.fire(EventBus.refreshBalances);
                  bus.fire(EventBus.refreshPurchases);
                  bus.fire(EventBus.refreshPayments);
                  bus.fire(EventBus.refreshPayments);
                  bus.fire(EventBus.refreshShopping);
                  bus.fire(EventBus.refreshStatistics);
                  bus.fire(EventBus.refreshGroupInfo);
                },
              ),
            ))
        .toList()
      ..add(Divider());
  }

  void onRefreshBalancesEvent() {
    setState(() {
      _sumBalance = _getSumBalance();
    });
  }

  void onRefreshGroupsEvent() {
    setState(() {
      _groups = _getGroups();
    });
  }

  void onRefreshGroupInfoEvent() {
    setState(() {
      _invitation = _getInvitation();
    });
  }

  @override
  void initState() {
    super.initState();

    _selectedIndex = widget.selectedIndex;
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.selectedIndex);
    _groups = _getGroups();
    _sumBalance = _getSumBalance();
    _invitation = _getInvitation();
    final bus = EventBus.instance;
    bus.register(EventBus.refreshBalances, onRefreshBalancesEvent);
    bus.register(EventBus.refreshGroups, onRefreshGroupsEvent);
    bus.register(EventBus.refreshGroupInfo, onRefreshGroupInfoEvent);
    scrollTo = widget.scrollTo;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Future.delayed(Duration(seconds: 1)).then((value) => scrollTo = null);
    });
  }

  @override
  void dispose() {
    _tabController!.dispose();
    final bus = EventBus.instance;
    bus.unregister(EventBus.refreshBalances, onRefreshBalancesEvent);
    bus.unregister(EventBus.refreshGroups, onRefreshGroupsEvent);
    bus.unregister(EventBus.refreshGroupInfo, onRefreshGroupInfoEvent);
    super.dispose();
  }

  void _handleDrawer() {
    if (context.read<ScreenSize>().isMobile) {
      _scaffoldKey.currentState!.openEndDrawer();
    } else {
      _scaffoldKey.currentState!.openDrawer();
    }
  }

  Widget _invitationButton() {
    return FutureBuilder(
        future: _invitation,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return IconButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => ShareGroupDialog(inviteCode: snapshot.data!),
              ),
              icon: Icon(Icons.share),
            );
          }
          return Container();
        });
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = context.watch<ScreenSize>().isMobile;
    if (!isMobile && _selectedIndex > 1) {
      _selectedIndex = 0;
      _tabController!.animateTo(_selectedIndex);
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
    }
    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            leading: !isMobile
                ? IconButton(
                    onPressed: _handleDrawer,
                    icon: Icon(Icons.menu),
                  )
                : _invitationButton(),
            actions: [if (!isMobile) _invitationButton()],
            centerTitle: true,
            title: Text(
              context.watch<UserNotifier>().user!.group?.name ?? '',
              style: TextStyle(letterSpacing: 0.25, fontSize: 24),
            ),
          ),
          bottomNavigationBar: !isMobile
              ? null
              : NavigationBar(
                  onDestinationSelected: (index) {
                    if (index != 3) {
                      setState(() {
                        _selectedIndex = index;
                        _tabController!.animateTo(index);
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      });
                    } else {
                      _handleDrawer();
                    }
                  },
                  selectedIndex: _selectedIndex,
                  destinations: _bottomNavbarItems(),
                ),
          drawer: !isMobile
              ? Drawer(
                  child: _drawer(),
                )
              : null,
          endDrawer: isMobile
              ? Drawer(
                  child: _drawer(),
                )
              : null,
          floatingActionButton: Visibility(
            visible: _selectedIndex == 0,
            child: FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PurchasePage()),
                );
                EventBus.instance.fire(EventBus.refreshMainDialog);
              },
              label: Text('new-expense'.tr()),
              icon: Icon(Icons.add),
            ),
          ),
          body: kIsWeb
              ? _body(true)
              : ConnectivityWidget(
                  offlineBanner: Container(
                    padding: EdgeInsets.all(8),
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.error,
                    child: Text(
                      'no_connection'.tr(),
                      style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onError, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  builder: (context, isOnline) => ChangeNotifierProvider(
                    create: (_) => IsOnlineProvider(isOnline: isOnline),
                    child: _body(isOnline),
                  ),
                ),
        ),
        MainDialogBuilder(context: context),
      ],
    );
  }

  Widget _body(bool isOnline) {
    ScreenSize size = context.watch<ScreenSize>();
    List<Widget> tabWidgets = _tabWidgets(isOnline);
    return Column(
      children: [
        Expanded(
          child: size.isMobile
              ? TabBarView(
                  physics: NeverScrollableScrollPhysics(),
                  controller: _tabController,
                  children: tabWidgets,
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: tabWidgets.map((child) => Expanded(child: child)).toList(),
                ),
        ),
        AdUnit(site: 'home_screen'),
      ],
    );
  }

  List<Widget> _tabWidgets(bool isOnline) {
    return [
      RefreshIndicator(
        onRefresh: () async {
          final bus = EventBus.instance;
          bus.fire(EventBus.refreshBalances);
          bus.fire(EventBus.refreshPayments);
          bus.fire(EventBus.refreshPurchases);
          bus.fire(EventBus.refreshShopping);
          bus.fire(EventBus.refreshStatistics);
          bus.fire(EventBus.refreshMainDialog);
          bus.fire(EventBus.refreshGroups);
          bus.fire(EventBus.refreshGroupInfo);
          if (isOnline) await clearGroupCache(context);
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          controller: ScrollController(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Balances(),
              History(
                selectedIndex: widget.selectedHistoryIndex,
              ),
              StatisticsDataExport(),
              GroupInfo(),
              if (context.watch<ScreenSize>().isMobile) SizedBox(height: 70), // So the floating button doesn't block info
            ],
          ),
        ),
      ),
      ShoppingList(),
    ];
  }

  Widget _drawer() {
    ThemeName themeName = context.watch<AppThemeState>().themeName;
    return Consumer<UserNotifier>(builder: (context, appStateProvider, _) {
      return Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: ScrollController(),
                children: <Widget>[
                  DrawerHeader(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, themeName.isDodo() && !kIsWeb ? BlendMode.dst : BlendMode.srcIn),
                            child: Image(
                              image: AssetImage('assets/dodo.png'),
                            ),
                          ),
                        ),
                        Text(
                          'title'.tr().toUpperCase(),
                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        if (appStateProvider.user!.username != null && appStateProvider.user!.username != '')
                          Text(
                            'hi'.tr(args: [appStateProvider.user!.username!]),
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
                          ),
                      ],
                    ),
                  ),
                  FutureBuilder(
                    future: _groups,
                    builder: (context, AsyncSnapshot<List<Group>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.symmetric(horizontal: 15),
                              collapsedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              clipBehavior: Clip.antiAlias,
                              title: Text(
                                'groups'.tr(),
                                style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                              leading: Icon(Icons.group, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              children: _generateListTiles(snapshot.data!),
                            ),
                          );
                        } else {
                          return ErrorMessage(
                            error: snapshot.error.toString(),
                            errorLocation: 'home_groups',
                            onTap: () {
                              setState(() {
                                _groups = null;
                                _groups = _getGroups();
                              });
                            },
                          );
                        }
                      }
                      return LinearProgressIndicator(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      );
                    },
                  ),
                  DrawerTile(
                    icon: Icons.group_add,
                    label: 'join_group'.tr(),
                    builder: (context) => JoinGroupPage(),
                    onReturn: () => EventBus.instance.fire(EventBus.refreshMainDialog),
                  ),
                  DrawerTile(
                    icon: Icons.library_add,
                    label: 'create_group'.tr(),
                    builder: (context) => CreateGroupPage(),
                    onReturn: () => EventBus.instance.fire(EventBus.refreshMainDialog),
                  ),
                ],
              ),
            ),
            FutureBuilder(
              future: _sumBalance,
              builder: (context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    Currency currency = Currency.fromCode(snapshot.data!['currency']);
                    double balance = snapshot.data!['balance'] * 1.0;
                    return Text('Σ: ${balance.toMoneyString(currency, withSymbol: true)}', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.secondary));
                  }
                }
                return Text(
                  'Σ: ...',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.secondary),
                );
              },
            ),
            Divider(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
                dense: true,
                onTap: () async {
                  if (!context.read<AppConfig>().isIAPPlatformEnabled) {
                    showDialog(builder: (context) => IAPNotSupportedDialog(), context: context);
                  } else {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => StorePage()));
                    EventBus.instance.fire(EventBus.refreshMainDialog);
                  }
                },
                leading: ColorFiltered(
                  colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
                  child: Image.asset(
                    'assets/dodo.png',
                    width: 25,
                  ),
                ),
                subtitle: Text(
                  'in_app_purchase_description'.tr(),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                title: Text(
                  'in_app_purchase'.tr(),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            DrawerTile(
              icon: Icons.palette,
              label: 'customization'.tr(),
              builder: (context) => CustomizePage(),
              onReturn: () => EventBus.instance.fire(EventBus.refreshMainDialog),
            ),
            DrawerTile(
              dense: true,
              icon: Icons.account_circle,
              label: 'profile'.tr(),
              builder: (context) => UserSettingsPage(),
              onReturn: () => EventBus.instance.fire(EventBus.refreshMainDialog),
            ),
            Divider(),
            DrawerTile(
              dense: true,
              label: 'logout'.tr(),
              icon: Icons.exit_to_app,
              onTap: () async {
                context.read<UserNotifier>().logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginOrRegisterPage()),
                  (r) => false,
                );
              },
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _bottomNavbarItems() {
    return [
      NavigationDestination(
        icon: Icon(
          Icons.bar_chart_rounded,
        ),
        label: 'finances'.tr(),
      ),
      NavigationDestination(
        icon: Icon(Icons.checklist),
        label: 'shopping_list'.tr(),
      ),
    ];
  }
}
