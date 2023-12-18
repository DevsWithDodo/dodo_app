import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:collection/collection.dart';
import 'package:connectivity_widget/connectivity_widget.dart';
import 'package:csocsort_szamla/helpers/app_theme.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/app_theme_provider.dart';
import 'package:csocsort_szamla/pages/app/store_page.dart';
import 'package:csocsort_szamla/pages/app/join_group_page.dart';
import 'package:csocsort_szamla/pages/app/user_settings_page.dart';
import 'package:csocsort_szamla/pages/auth/login_or_register_page.dart';
import 'package:csocsort_szamla/helpers/event_bus.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/helpers/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/pages/app/create_group_page.dart';
import 'package:csocsort_szamla/components/groups/group_settings.dart';
import 'package:csocsort_szamla/components/history/history.dart';
import 'package:csocsort_szamla/components/main/main_dialog_builder.dart';
import 'package:csocsort_szamla/components/main/statistics_export_card.dart';
import 'package:csocsort_szamla/components/shopping/shopping_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:provider/provider.dart';

import '../../components/balance/balances.dart';
import '../../components/helpers/ad_unit.dart';
import '../../helpers/currencies.dart';
import '../../helpers/http.dart';
import '../../helpers/models.dart';
import '../../components/helpers/error_message.dart';
import '../../components/main/dialogs/iapp_not_supported_dialog.dart';
import '../../components/main/main_speed_dial.dart';
import '../../components/main/dialogs/trial_version_dialog.dart';

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

  MainPage({this.selectedHistoryIndex = 0, this.selectedIndex = 0, this.scrollTo});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  SharedPreferences? prefs;
  Future<List<Group>>? _groups;
  Future<dynamic>? _sumBalance;

  TabController? _tabController;
  int _selectedIndex = 0;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? scrollTo;

  Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<List<Group>> _getGroups() async {
    if (!this.mounted) {
      return [];
    }
    Response response = await Http.get(uri: generateUri(GetUriKeys.groups, context), overwriteCache: true);
    Map<String, dynamic> decoded = jsonDecode(response.body);
    UserState userProvider = context.read<UserState>();
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
      (group) => (group.id == userProvider.currentGroup!.id &&
          (group.name != userProvider.currentGroup!.name || group.currency != userProvider.currentGroup!.currency)),
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
      throw _;
    }
  }

  List<Widget> _generateListTiles(List<Group> groups) {
    String currentGroupName = context.watch<UserState>().user!.group!.name;
    return groups.map((group) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            tileColor: (group.name == currentGroupName)
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            title: Text(
              group.name,
              style: (group.name == currentGroupName)
                  ? Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .copyWith(color: Theme.of(context).colorScheme.onSecondaryContainer)
                  : Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            onTap: () async {
              context.read<UserState>().setGroup(group);
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
            },
          ),
        ),
      );
    }).toList();
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

  @override
  void initState() {
    super.initState();

    _selectedIndex = widget.selectedIndex;
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.selectedIndex);
    _groups = _getGroups();
    _sumBalance = _getSumBalance();
    final bus = EventBus.instance;
    bus.register(EventBus.refreshBalances, onRefreshBalancesEvent);
    bus.register(EventBus.refreshGroups, onRefreshGroupsEvent);
    scrollTo = widget.scrollTo;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Future.delayed(Duration(seconds: 1)).then((value) => scrollTo = null);
    });
  }

  void dispose() {
    _tabController!.dispose();
    final bus = EventBus.instance;
    bus.unregister(EventBus.refreshBalances, onRefreshBalancesEvent);
    bus.unregister(EventBus.refreshGroups, onRefreshGroupsEvent);
    super.dispose();
  }

  void _handleDrawer() {
    if (context.read<ScreenWidth>().isMobile) {
      _scaffoldKey.currentState!.openEndDrawer();
    } else {
      _scaffoldKey.currentState!.openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = context.watch<ScreenWidth>().isMobile;
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
                : null,
            centerTitle: true,
            title: Text(
              context.watch<UserState>().user!.group?.name ?? '',
              style: TextStyle(letterSpacing: 0.25, fontSize: 24),
            ),
          ),
          bottomNavigationBar: !isMobile
              ? null
              : NavigationBar(
                  onDestinationSelected: (_index) {
                    if (_index != 3) {
                      setState(() {
                        _selectedIndex = _index;
                        _tabController!.animateTo(_index);
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
            child: MainPageSpeedDial(
              onReturn: () => EventBus.instance.fire(EventBus.refreshMainDialog),
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
                      style: TextStyle(
                          fontSize: 16, color: Theme.of(context).colorScheme.onError, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  builder: (context, isOnline) {
                    return ChangeNotifierProvider(
                      create: (_) => IsOnlineProvider(isOnline: isOnline),
                      child: _body(isOnline),
                    );
                  },
                ),
        ),
        MainDialogBuilder(context: context),
      ],
    );
  }

  Widget _body(bool isOnline) {
    ScreenWidth screenWidth = context.watch<ScreenWidth>();
    bool bigScreen = !screenWidth.isMobile;
    List<Widget> tabWidgets = _tabWidgets(isOnline);
    return Row(
      children: [
        if (bigScreen)
          NavigationRail(
            labelType: NavigationRailLabelType.all,
            destinations: _navigationRailItems(),
            onDestinationSelected: (_index) => setState(() {
              _selectedIndex = _index;
              _tabController!.animateTo(_index);
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
            }),
            selectedIndex: _selectedIndex,
          )
        else
          Container(),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(),
                  controller: _tabController,
                  children: !bigScreen
                      ? tabWidgets
                      : [
                          Row(
                            children: tabWidgets.take(2).map((child) => Expanded(child: child)).toList(),
                          ),
                          tabWidgets.reversed.first,
                          Container(),
                        ],
                ),
              ),
              AdUnit(site: 'home_screen'),
            ],
          ),
        ),
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
              Visibility(
                visible: context.watch<ScreenWidth>().isMobile,
                child: SizedBox(height: 70),
              ), // So the floating button doesn't block info
            ],
          ),
        ),
      ),
      ShoppingList(),
      GroupSettings(scrollTo: scrollTo),
    ];
  }

  Widget _drawer() {
    ThemeName themeName = context.watch<AppThemeState>().themeName;
    return Consumer<UserState>(builder: (context, appStateProvider, _) {
      return Ink(
        decoration: BoxDecoration(
          color: ElevationOverlay.applyOverlay(context, Theme.of(context).colorScheme.surface, 1),
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
                            colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary,
                                themeName.isDodo() && !kIsWeb ? BlendMode.dst : BlendMode.srcIn),
                            child: Image(
                              image: AssetImage('assets/dodo.png'),
                            ),
                          ),
                        ),
                        Text(
                          'title'.tr().toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          'hi'.tr() + ' ' + appStateProvider.user!.username + '!',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder(
                    future: _groups,
                    builder: (context, AsyncSnapshot<List<Group>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData) {
                          return Card(
                            color: Colors.transparent,
                            elevation: 0,
                            margin: EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(28)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ExpansionTile(
                              title: Text('groups'.tr(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(28)),
                      ),
                      leading: Icon(
                        Icons.group_add,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        'join_group'.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge!
                            .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => JoinGroupPage()),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(28)),
                      ),
                      leading: Icon(
                        Icons.library_add,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        'create_group'.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge!
                            .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateGroupPage(),
                          ),
                        );
                      },
                    ),
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
                    return Text('Σ: ' + balance.toMoneyString(currency, withSymbol: true),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: Theme.of(context).colorScheme.secondary));
                  }
                }
                return Text(
                  'Σ: ...',
                  style:
                      Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.secondary),
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
                onTap: () {
                  if (appStateProvider.user!.trialVersion) {
                    showDialog(builder: (context) => TrialVersionDialog(), context: context);
                  } else if (!context.read<AppConfig>().isIAPPlatformEnabled) {
                    showDialog(builder: (context) => IAPNotSupportedDialog(), context: context);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => StorePage()));
                  }
                },
                leading: ColorFiltered(
                  colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
                  child: Image.asset(
                    'assets/dodo.png',
                    width: 25,
                  ),
                ),
                subtitle: appStateProvider.user!.trialVersion
                    ? Text(
                        'trial_version'.tr().toUpperCase(),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall!
                            .copyWith(color: Theme.of(context).colorScheme.secondary),
                      )
                    : Text(
                        'in_app_purchase_description'.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge!
                            .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                title: Text(
                  'in_app_purchase'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            Visibility(
              visible: !kIsWeb,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                  ),
                  leading: Icon(
                    Icons.rate_review,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  dense: true,
                  title: Text(
                    'rate_app'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge!
                        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  onTap: () {
                    String url = "";
                    String platform = kIsWeb ? "web" : Platform.operatingSystem;
                    switch (platform) {
                      case "android":
                        url = "market://details?id=csocsort.hu.machiato32.csocsort_szamla";
                        break;
                      case "windows":
                        url = "ms-windows-store://pdp/?productid=9NVB4CZJDSQ7";
                        break;
                      case "ios":
                        url = "itms-apps://itunes.apple.com/app/id1558223634?action=write-review";
                        break;
                      default:
                        url = "https://play.google.com/store/apps/details?id=csocsort.hu.machiato32.csocsort_szamla";
                        break;
                    }
                    launchUrlString(url);
                    context.read<UserState>().setRatedApp(true);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
                dense: true,
                leading: Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  'settings'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => UserSettingsPage()));
                },
              ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
                leading: Icon(
                  Icons.exit_to_app,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                dense: true,
                title: Text(
                  'logout'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                onTap: () async {
                  context.read<UserState>().logout();
                  Navigator.pushAndRemoveUntil(
                      context, MaterialPageRoute(builder: (context) => LoginOrRegisterPage()), (r) => false);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  List<NavigationRailDestination> _navigationRailItems() {
    return [
      NavigationRailDestination(
        icon: Icon(
          Icons.home,
        ),
        label: Text('home'.tr()),
      ),
      NavigationRailDestination(
        icon: Stack(
          children: [
            Container(
              margin: EdgeInsets.only(right: 5),
              child: Icon(
                Icons.group,
                size: 22,
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 17),
              child: Icon(
                Icons.settings,
                size: 12,
              ),
            ),
          ],
        ),
        label: Text('group'.tr()),
      ),
    ];
  }

  List<Widget> _bottomNavbarItems() {
    return [
      NavigationDestination(
        icon: Icon(
          Icons.home,
        ),
        label: 'home'.tr(),
      ),
      NavigationDestination(icon: Icon(Icons.receipt_long), label: 'shopping_list'.tr()),
      NavigationDestination(
        icon: Stack(
          children: [
            Container(
              margin: EdgeInsets.only(right: 5),
              child: Icon(
                Icons.group,
                size: 22,
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 17),
              child: Icon(
                Icons.settings,
                size: 12,
              ),
            ),
          ],
        ),
        label: 'group'.tr(),
      ),
    ];
  }
}
