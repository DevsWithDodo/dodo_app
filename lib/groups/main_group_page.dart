import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:connectivity_widget/connectivity_widget.dart';
import 'package:csocsort_szamla/auth/login_or_register_page.dart';
import 'package:csocsort_szamla/essentials/save_preferences.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:csocsort_szamla/groups/create_group.dart';
import 'package:csocsort_szamla/groups/dialogs/download_export_dialog.dart';
import 'package:csocsort_szamla/groups/group_settings_page.dart';
import 'package:csocsort_szamla/groups/join_group.dart';
import 'package:csocsort_szamla/history/history.dart';
import 'package:csocsort_szamla/main/in_app_purchase_page.dart';
import 'package:csocsort_szamla/main/statistics_page.dart';
import 'package:csocsort_szamla/main/trial_ended_dialog.dart';
import 'package:csocsort_szamla/shopping/shopping_list.dart';
import 'package:csocsort_szamla/user_settings/user_settings_page.dart';
import 'package:csocsort_szamla/main/statistics_export_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../balance/balances.dart';
import '../config.dart';
import '../essentials/ad_management.dart';
import '../essentials/currencies.dart';
import '../essentials/models.dart';
import '../essentials/http_handler.dart';
import '../essentials/widgets/error_message.dart';
import '../main/iapp_not_supported_dialog.dart';
import '../main/like_app_dialog.dart';
import '../main/main_speed_dial.dart';
import '../main/trial_version_dialog.dart';

class MainPage extends StatefulWidget {
  final int selectedHistoryIndex;
  final int selectedIndex;
  final String scrollTo;

  MainPage(
      {this.selectedHistoryIndex = 0, this.selectedIndex = 0, this.scrollTo});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  SharedPreferences prefs;
  Future<List<Group>> _groups;

  TabController _tabController;
  int _selectedIndex = 0;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<State> _isGuestBannerKey = GlobalKey<State>();

  String scrollTo;

  Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<List<Group>> _getGroups() async {
    http.Response response =
        await httpGet(context: context, uri: generateUri(GetUriKeys.groups));
    Map<String, dynamic> decoded = jsonDecode(response.body);
    List<Group> groups = [];
    for (var group in decoded['data']) {
      groups.add(Group(
        groupName: group['group_name'],
        groupId: group['group_id'],
        groupCurrency: group['currency'],
      ));
    }
    usersGroups = groups.map<String>((group) => group.groupName).toList();
    usersGroupIds = groups.map<int>((group) => group.groupId).toList();
    saveUsersGroups();
    saveUsersGroupIds();
    //The group ID cannot change, but the group name and currency can change
    if (groups.any((element) => element.groupId == currentGroupId)) {
      var group =
          groups.firstWhere((element) => element.groupId == currentGroupId);
      saveGroupName(group.groupName);
      saveGroupCurrency(group.groupCurrency);
    }
    return groups;
  }

  Future<String> _getCurrentGroup() async {
    http.Response response = await httpGet(
      context: context,
      uri: generateUri(GetUriKeys.groupCurrent,
          args: [currentGroupId.toString()]),
    );
    Map<String, dynamic> decoded = jsonDecode(response.body);
    saveGroupName(decoded['data']['group_name']);
    return currentGroupName;
  }

  Future<dynamic> _getSumBalance() async {
    try {
      http.Response response = await httpGet(
          context: context, uri: generateUri(GetUriKeys.userBalanceSum));
      Map<String, dynamic> decoded = jsonDecode(response.body);
      return decoded['data'];
    } catch (_) {
      throw _;
    }
  }

  Future _logout() async {
    try {
      await httpPost(uri: '/logout', context: context, body: {});
      await clearAllCache();
      deleteUserId();
      deleteUserCurrency();
      deleteUsesPassword();
      deleteGroupId();
      deleteGroupName();
      deleteGroupCurrency();
      deleteApiToken();
      deleteUsersGroups();
      deleteUsersGroupIds();
    } catch (_) {
      throw _;
    }
  }

  List<Widget> _generateListTiles(List<Group> groups) {
    return groups.map((group) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            tileColor: (group.groupName == currentGroupName)
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            title: Text(
              group.groupName,
              style: (group.groupName == currentGroupName)
                  ? Theme.of(context).textTheme.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer)
                  : Theme.of(context).textTheme.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            onTap: () async {
              saveGroupName(group.groupName);
              saveGroupId(group.groupId);
              saveGroupCurrency(group.groupCurrency);
              setState(() {
                _selectedIndex = 0;
                _tabController.animateTo(_selectedIndex);
              });
            },
          ),
        ),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.selectedIndex);
    _groups = null;
    _groups = _getGroups();
    scrollTo = widget.scrollTo;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Future.delayed(Duration(seconds: 1)).then((value) => scrollTo = null);
    });
  }

  void _handleDrawer(bool bigScreen) {
    if (!bigScreen) {
      _scaffoldKey.currentState.openEndDrawer();
    } else {
      _scaffoldKey.currentState.openDrawer();
    }
    _groups = null;
    _groups = _getGroups();
  }

  Future<void> callback() async {
    await clearGroupCache();
    await deleteCache(uri: generateUri(GetUriKeys.groups));
    await deleteCache(uri: generateUri(GetUriKeys.userBalanceSum));
    setState(() {
      _groups = null;
      _groups = _getGroups();
    });

    if (!kIsWeb && !ratedApp && !trialVersion) {
      double r = Random().nextDouble();
      print(r);
      if (r < 0.15) {
        showDialog(context: context, builder: (context) => LikeTheAppDialog());
        // Don't show the dialog multiple times in one session. Value is not saved in the memory
        ratedApp = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((timeStamp) {
      //TODO: for new version: save version code in storage, if version code is newer than the one in the storage, show dialog with news
      if (trialJustEnded) {
        showDialog(context: context, builder: (context) => TrialEndedDialog());
        trialJustEnded = false;
      }
    });

    double width = MediaQuery.of(context).size.width;
    bool bigScreen = width > tabletViewWidth;
    if (bigScreen && _selectedIndex > 1) {
      _selectedIndex = 0;
      _tabController.animateTo(_selectedIndex);
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
    }
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: bigScreen
            ? IconButton(
                onPressed: () {
                  _handleDrawer(bigScreen);
                },
                icon: Icon(Icons.menu),
              )
            : null,
        actions: [Container()],
        centerTitle: true,
        title: FutureBuilder(
          future: _getCurrentGroup(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                return Text(
                  snapshot.data,
                  style: TextStyle(letterSpacing: 0.25, fontSize: 24),
                );
              }
            }
            return Text(
              currentGroupName ?? 'error'.tr(),
              style: TextStyle(letterSpacing: 0.25, fontSize: 24),
            );
          },
        ),
      ),
      bottomNavigationBar: bigScreen
          ? null
          : NavigationBar(
              onDestinationSelected: (_index) {
                if (_index != 3) {
                  setState(() {
                    _selectedIndex = _index;
                    _tabController.animateTo(_index);
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  });
                } else {
                  _handleDrawer(bigScreen);
                }
              },
              selectedIndex: _selectedIndex,
              destinations: _bottomNavbarItems(),
            ),
      drawer: bigScreen
          ? Drawer(
              child: _drawer(),
            )
          : null,
      endDrawer: !bigScreen
          ? Drawer(
              child: _drawer(),
            )
          : null,
      floatingActionButton: Visibility(
        visible: _selectedIndex == 0,
        child: MainPageSpeedDial(
          onReturn: this.callback,
        ),
      ),
      body: kIsWeb
          ? _body(true, bigScreen)
          : ConnectivityWidget(
              offlineBanner: kIsWeb
                  ? Container()
                  : Container(
                      padding: EdgeInsets.all(8),
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.error,
                      child: Text(
                        'no_connection'.tr(),
                        style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onError,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
              builder: (context, isOnline) {
                isOnline = isOnline || kIsWeb;
                return _body(isOnline, bigScreen);
              },
            ),
    );
  }

  Widget _body(bool isOnline, bool bigScreen) {
    double width = MediaQuery.of(context).size.width - (bigScreen ? 80 : 0);
    double height = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        56 - //appbar
        (bigScreen ? 0 : 56) - //bottomNavbar
        adHeight();
    List<Widget> tabWidgets = _tabWidgets(isOnline, bigScreen, height, width);
    return Row(
      children: [
        bigScreen
            ? NavigationRail(
                labelType: NavigationRailLabelType.all,
                destinations: _navigationRailItems(),
                onDestinationSelected: (_index) {
                  // print(_selectedIndex);
                  setState(() {
                    _selectedIndex = _index;
                    _tabController.animateTo(_index);
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  });
                },
                selectedIndex: _selectedIndex)
            : Container(),
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
                          Table(
                            columnWidths: {
                              0: FractionColumnWidth(1 / 2),
                              1: FractionColumnWidth(1 / 2),
                            },
                            children: [
                              TableRow(
                                children: tabWidgets
                                    .take(2)
                                    .map(
                                      (e) => AspectRatio(
                                        aspectRatio: width / 2 / height,
                                        child: e,
                                      ),
                                    )
                                    .toList(),
                              )
                            ],
                          ),
                          tabWidgets.reversed.first,
                          Container(),
                        ],
                ),
              ),
              AdUnitForSite(site: 'home_screen'),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _tabWidgets(
      bool isOnline, bool bigScreen, double height, double width) {
    return [
      RefreshIndicator(
        onRefresh: () async {
          if (isOnline) await callback();
          setState(() {});
        },
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          controller: ScrollController(),
          shrinkWrap: true,
          children: [
            Balances(
              callback: callback,
              bigScreen: bigScreen,
            ),
            History(
              selectedIndex: widget.selectedHistoryIndex,
              callback: callback,
            ),
            StatisticsDataExport(),
            SizedBox(height: 70), // So the floating button doesn't block info
          ],
        ),
      ),
      ShoppingList(
        isOnline: isOnline,
        bigScreen: bigScreen,
      ),
      GroupSettings(
        bannerKey: _isGuestBannerKey,
        scrollTo: scrollTo,
        bigScreen: bigScreen,
        height: height,
        width: width,
      ),
    ];
  }

  Widget _drawer() {
    return Ink(
      decoration: BoxDecoration(
        color: ElevationOverlay.applyOverlay(
            context, Theme.of(context).colorScheme.surface, 1),
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
                          colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.primary,
                              currentThemeName.toLowerCase().contains('dodo') &&
                                      !kIsWeb
                                  ? BlendMode.dst
                                  : BlendMode.srcIn),
                          child: Image(
                            image: AssetImage('assets/dodo.png'),
                          ),
                        ),
                      ),
                      Text(
                        'title'.tr().toUpperCase(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            .copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                      ),
                      Text(
                        'hi'.tr() + ' ' + currentUsername + '!',
                        style: Theme.of(context).textTheme.bodyLarge.copyWith(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                FutureBuilder(
                  future: _groups,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                            cardTheme: CardTheme(
                              elevation: 0,
                              color: Colors.transparent,
                              margin: EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(28)),
                              ),
                            ),
                          ),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: ExpansionTile(
                              title: Text('groups'.tr(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                              leading: Icon(Icons.group,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                              children: _generateListTiles(snapshot.data),
                            ),
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
                      style: Theme.of(context).textTheme.labelLarge.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => JoinGroup()));
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
                      style: Theme.of(context).textTheme.labelLarge.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateGroup(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder(
            future: _getSumBalance(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  String currency = snapshot.data['currency'];
                  double balance = snapshot.data['balance'] * 1.0;
                  return Text(
                      'Σ: ' + balance.toMoneyString(currency, withSymbol: true),
                      style: Theme.of(context).textTheme.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.secondary));
                }
              }
              return Text(
                'Σ: ...',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    .copyWith(color: Theme.of(context).colorScheme.secondary),
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
                if (trialVersion) {
                  showDialog(
                      builder: (context) => TrialVersionDialog(),
                      context: context);
                } else if (!isIAPPlatformEnabled) {
                  showDialog(
                      builder: (context) => IAPPNotSupportedDialog(),
                      context: context);
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => InAppPurchasePage()));
                }
              },
              leading: ColorFiltered(
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurfaceVariant,
                    BlendMode.srcIn),
                child: Image.asset(
                  'assets/dodo.png',
                  width: 25,
                ),
              ),
              subtitle: trialVersion
                  ? Text(
                      'trial_version'.tr().toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall.copyWith(
                          color: Theme.of(context).colorScheme.secondary),
                    )
                  : Text(
                      'in_app_purchase_description'.tr(),
                      style: Theme.of(context).textTheme.labelLarge.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
              title: Text(
                'in_app_purchase'.tr(),
                style: Theme.of(context).textTheme.labelLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                  style: Theme.of(context).textTheme.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                onTap: () {
                  String url = "";
                  String platform = kIsWeb ? "web" : Platform.operatingSystem;
                  switch (platform) {
                    case "android":
                      url =
                          "market://details?id=csocsort.hu.machiato32.csocsort_szamla";
                      break;
                    case "windows":
                      url = "ms-windows-store://pdp/?productid=9NVB4CZJDSQ7";
                      break;
                    case "ios":
                      url =
                          "itms-apps://itunes.apple.com/app/id1558223634?action=write-review";
                      break;
                    default:
                      url =
                          "https://play.google.com/store/apps/details?id=csocsort.hu.machiato32.csocsort_szamla";
                      break;
                  }
                  launchUrlString(url);
                  saveRatedApp(true);
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
                style: Theme.of(context).textTheme.labelLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Settings()));
              },
            ),
          ),
          // Padding(//TODO: report bug
          //   padding: const EdgeInsets.symmetric(horizontal: 12.0),
          //   child: ListTile(
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.all(Radius.circular(28)),
          //     ),
          //     leading: Icon(
          //       Icons.bug_report,
          //       color: Theme.of(context).colorScheme.error,
          //     ),
          //     dense: true,
          //     title: Text(
          //       'report_a_bug'.tr(),
          //       style: Theme.of(context)
          //           .textTheme
          //           .labelLarge
          //           .copyWith(color: Theme.of(context).colorScheme.error),
          //     ),
          //     onTap: () {
          //       Navigator.push(context, MaterialPageRoute(builder: (context) => ReportABugPage()));
          //     },
          //   ),
          // ),
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
                style: Theme.of(context).textTheme.labelLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              onTap: () async {
                _logout();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LoginOrRegisterPage()),
                    (r) => false);
              },
            ),
          ),
        ],
      ),
    );
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
      NavigationDestination(
          icon: Icon(Icons.receipt_long), label: 'shopping_list'.tr()),
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
          label: 'group'.tr()),
      NavigationDestination(
        icon: Icon(Icons.menu),
        label: 'more'.tr(),
      )
    ];
  }
}
