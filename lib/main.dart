import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:connectivity_widget/connectivity_widget.dart';

import 'balances.dart';
import 'config.dart';
import 'group_objects.dart';
import 'http_handler.dart';
import 'app_state_notifier.dart';
import 'package:csocsort_szamla/auth/login_or_register_page.dart';
import 'package:csocsort_szamla/user_settings/user_settings_page.dart';
import 'package:csocsort_szamla/history/history.dart';
import 'package:csocsort_szamla/groups/join_group.dart';
import 'package:csocsort_szamla/groups/create_group.dart';
import 'package:csocsort_szamla/groups/group_settings.dart';
import 'package:csocsort_szamla/shopping/shopping_list.dart';
import 'main/report_a_bug.dart';
import 'main/tutorial_dialog.dart';
import 'main/speed_dial.dart';


FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) async {
  if (message.containsKey('data')) {

  }

  print(message);

  if (message.containsKey('notification')) {
  }

  // Or do other work.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences preferences = await SharedPreferences.getInstance();
  String themeName = '';
  if (!preferences.containsKey('theme')) {
    preferences.setString('theme', 'greenLightTheme');
    themeName = 'greenLightTheme';
  } else {
    themeName = preferences.getString('theme');
  }
  if (preferences.containsKey('current_username')) {
    currentUsername = preferences.getString('current_username');
    currentUserId = preferences.getInt('current_user_id');
    apiToken = preferences.getString('api_token');
  }
  if (preferences.containsKey('current_group_name')) {
    currentGroupName = preferences.getString('current_group_name');
    currentGroupId = preferences.getInt('current_group_id');
  }


  String initURL;
  try {
    initURL = await getInitialLink();
  } catch (_) {}

  runApp(
      EasyLocalization(
        child: ChangeNotifierProvider<AppStateNotifier>(
            create: (context) => AppStateNotifier(),
            child: LenderApp(
              themeName: themeName,
              initURL: initURL,
            )),
        supportedLocales: [Locale('en'), Locale('de'), Locale('hu'), Locale('it')],
        path: 'assets/translations',
        fallbackLocale: Locale('en'),
        useOnlyLangCode: true,
        saveLocale: true,
        preloaderColor: (themeName.contains('Light')) ? Colors.white : Colors.black,
        preloaderWidget: MaterialApp(
          home: Material(
            type: MaterialType.transparency,
            child: Center(
              child: Text(
                'LENDER',
                style: TextStyle(
                    color:
                        (themeName.contains('Light')) ? Colors.black : Colors.white,
                    letterSpacing: 2.5,
                    fontSize: 35),
              ),
            ),
          ),
        ),
      )
  );
}

class LenderApp extends StatefulWidget {
  final String themeName;
  final String initURL;

  const LenderApp({@required this.themeName, this.initURL});

  @override
  State<StatefulWidget> createState() => _LenderAppState();
}

class _LenderAppState extends State<LenderApp> {
  bool _first = true;

  StreamSubscription _sub;
  String _link;


  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();


  Future<Null> initUniLinks() async {
    _sub = getLinksStream().listen((String link) {
      setState(() {
        _link = link;
      });
    }, onError: (err) {
      log('asd');
    });
  }

  initPlatformState() async {
    await initUniLinks();
  }

  Future onSelectNotification(String payload) async {
    //TODO: this
  }

  @override
  void initState() {
    var initializationSettingsAndroid =
    new AndroidInitializationSettings('@drawable/dodo_white');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);

    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: onSelectNotification);
    initPlatformState();
    _link = widget.initURL;
    super.initState();



    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
          '1234',
          'Lender',
          'Lender',
          playSound: false,
          importance: Importance.High,
          priority: Priority.Default,
          styleInformation: BigTextStyleInformation('')
        );
        var iOSPlatformChannelSpecifics =
        new IOSNotificationDetails(presentSound: false);
        var platformChannelSpecifics = new NotificationDetails(
            androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
        flutterLocalNotificationsPlugin.show(
          int.parse(message['data']['id'])??0,
          message['notification']['title'],
          message['notification']['body'],
          platformChannelSpecifics,
        );
      },
      onBackgroundMessage: myBackgroundMessageHandler,
      onLaunch: (Map<String, dynamic> message) async {
        print(message);
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print(message);
        print("onResume: $message");
      },
    );
  }

  @override
  dispose() {
    if (_sub != null) _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(
      builder: (context, appState, child) {
        if (_first) {
          appState.updateThemeNoNotify(widget.themeName);
          _first = false;
        }
        return FeatureDiscovery(
          child: MaterialApp(
            title: 'Lender',
            theme: appState.theme,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: currentUserId == null
                ? LoginOrRegisterPage()
                : (_link != null)
                    ? JoinGroup(
                        inviteURL: _link,
                        fromAuth: (currentGroupId == null) ? true : false,
                      )
                    : (currentGroupId == null)
                        ? JoinGroup(
                            fromAuth: true,
                          )
                        : MainPage(),
          ),
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({int drawerIndex=-1});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  SharedPreferences prefs;
  Future<List<Group>> _groups;

  TabController _tabController;
  int _selectedIndex = 0;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<List<Group>> _getGroups() async {
    http.Response response = await httpGet(context: context, uri: '/groups');
    Map<String, dynamic> decoded = jsonDecode(response.body);
    List<Group> groups = [];
    for (var group in decoded['data']) {
      groups.add(Group(
          groupName: group['group_name'], groupId: group['group_id']));
    }
    return groups;
  }

  Future<String> _getCurrentGroup() async {
    http.Response response = await httpGet(context: context, uri: '/groups/' + currentGroupId.toString(), useCache: false);
    Map<String, dynamic> decoded = jsonDecode(response.body);
    currentGroupName = decoded['data']['group_name'];
    SharedPreferences.getInstance().then((_prefs) {
      _prefs.setString('current_group_name', currentGroupName);
    });
    return currentGroupName;
  }

  Future<double> _getSumBalance() async {
    try{
      http.Response response = await httpGet(context: context, uri: '/user', useCache: false);
      Map<String, dynamic> decoded = jsonDecode(response.body);
      return decoded['data']['total_balance']*1.0;
    }catch(_){
      throw _;
    }
  }
  
  Future _logout() async {
    try {
      await clearAllCache();
      await httpPost(uri: '/logout', context: context, body: {});
      currentUserId = null;
      currentGroupId = null;
      currentGroupName = null;
      apiToken = null;
      SharedPreferences.getInstance().then((_prefs) {
        _prefs.remove('current_user_id');
        _prefs.remove('current_group_name');
        _prefs.remove('current_group_id');
        _prefs.remove('api_token');
      });
    } catch (_) {
      throw _;
    }
  }

  List<Widget> _generateListTiles(List<Group> groups) {
    return groups.map((group) {
      return ListTile(
        title: Text(
          group.groupName,
          style: (group.groupName == currentGroupName)
              ? Theme.of(context)
                  .textTheme
                  .bodyText1
                  .copyWith(color: Theme.of(context).colorScheme.secondary)
              : Theme.of(context).textTheme.bodyText1,
        ),
        onTap: () {
          currentGroupName = group.groupName;
          currentGroupId = group.groupId;
          SharedPreferences.getInstance().then((_prefs) {
            _prefs.setString('current_group_name', group.groupName);
            _prefs.setInt('current_group_id', group.groupId);
          });
          setState(() {
            _selectedIndex = 0;
            _tabController.animateTo(_selectedIndex);
          });
        },
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _groups = null;
    _groups = _getGroups();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool showTutorial=true;
      await SharedPreferences.getInstance().then((prefs) {
        if(prefs.containsKey('show_tutorial')){
          showTutorial=prefs.getBool('show_tutorial');
        }
      });
      if(showTutorial){
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('show_tutorial', false);
        });
        await showDialog(
          context: context,
          builder: (context){
            return TutorialDialog();
          },
        );
      }

    });
  }

  void _handleDrawer() {
    FeatureDiscovery.discoverFeatures(context, <String>['drawer', 'settings']);
    _scaffoldKey.currentState.openDrawer();
    _groups = null;
    _groups = _getGroups();
  }

  void callback() async {
    await clearCache();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
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
              currentGroupName ?? 'asd',
              style: TextStyle(letterSpacing: 0.25, fontSize: 24),
            );
          },
        ),
        leading: DescribedFeatureOverlay(
          tapTarget: Icon(Icons.menu, color: Colors.black),
          featureId: 'drawer',
          backgroundColor: Theme.of(context).colorScheme.primary,
          overflowMode: OverflowMode.extendBackground,
          title: Text('discovery_drawer_title'.tr()),
          description: Text('discovery_drawer_description'.tr()),
          barrierDismissible: false,
          child: IconButton(
            icon: Icon(Icons.menu),
            onPressed: _handleDrawer,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (_index) {
          setState(() {
            _selectedIndex = _index;
            _tabController.animateTo(_index);
          });
          if(_selectedIndex==1){
            FeatureDiscovery.discoverFeatures(context, ['shopping_list']);
          }else if(_selectedIndex==2){
            FeatureDiscovery.discoverFeatures(context, ['group_settings']);
          }
        },
        currentIndex: _selectedIndex,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), title: Text('home'.tr())),
          BottomNavigationBarItem(
              icon: DescribedFeatureOverlay(
                  featureId: 'shopping_list',
                  tapTarget: Icon(Icons.add_shopping_cart, color: Colors.black),
                  title: Text('discover_shopping_title'.tr()),
                  description: Text('discover_shopping_description'.tr()),
                  overflowMode: OverflowMode.extendBackground,
                  child: Icon(Icons.add_shopping_cart)
              ),
              title: Text('shopping_list'.tr())
          ),
          BottomNavigationBarItem(
              icon: DescribedFeatureOverlay(
                  featureId: 'group_settings',
                  tapTarget: Icon(Icons.settings, color: Colors.black),
                  title: Text('discover_group_settings_title'.tr()),
                  description: Text('discover_group_settings_description'.tr()),
                  overflowMode: OverflowMode.extendBackground,
                  child: Icon(Icons.settings)),
              title: Text('group'.tr())
          )
        ],
      ),
      drawer: Drawer(
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
                        Expanded(
                          child: Image(
                            image: AssetImage('assets/dodo_color.png'),
                          ),
                        ),
                        Text(
                          'LENDER',
                          style: Theme.of(context)
                              .textTheme
                              .headline6
                              .copyWith(letterSpacing: 2.5),
                        ),
                        Text(
                          'hi'.tr()+' '+currentUsername+'!',
                          style: Theme.of(context).textTheme.bodyText1.copyWith(
                              color: Theme.of(context).colorScheme.secondary),
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
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              title: Text('groups'.tr(),
                                  style: Theme.of(context).textTheme.bodyText1),
                              leading: Icon(Icons.group,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyText1
                                      .color),
                              children: _generateListTiles(snapshot.data),
                            ),
                          );
                        } else {
                          return InkWell(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text(snapshot.error.toString()),
                              ),
                              onTap: () {
                                setState(() {
                                  _groups = null;
                                  _groups = _getGroups();
                                });
                              });
                        }
                      }
                      return LinearProgressIndicator();
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.group_add,
                      color: Theme.of(context).textTheme.bodyText1.color,
                    ),
                    title: Text(
                      'join_group'.tr(),
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => JoinGroup()));
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.create,
                      color: Theme.of(context).textTheme.bodyText1.color,
                    ),
                    title: Text(
                      'create_group'.tr(),
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CreateGroup()));
                    },
                  ),
                ],
              ),
            ),

            FutureBuilder(
              future: _getSumBalance(),
              builder: (context, snapshot){
                if(snapshot.connectionState==ConnectionState.done){
                  if(snapshot.hasData){
                    return Text(
                        'Σ: '+snapshot.data.toString(),
                        style: Theme.of(context).textTheme.bodyText1
                    );
                  }
                }
                return Text('Σ: ...',
                  style: Theme.of(context).textTheme.bodyText1.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 16
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: DescribedFeatureOverlay(
                tapTarget: Icon(Icons.settings, color: Colors.black),
                featureId: 'settings',
                backgroundColor: Theme.of(context).colorScheme.primary,
                overflowMode: OverflowMode.extendBackground,
                allowShowingDuplicate: true,
                contentLocation: ContentLocation.above,
                title: Text('discovery_settings_title'.tr()),
                description: Text('discovery_settings_description'.tr()),
                child: Icon(
                  Icons.settings,
                  color: Theme.of(context).textTheme.bodyText1.color,
                ),
              ),
              title: Text(
                'settings'.tr(),
                style: Theme.of(context).textTheme.bodyText1,
              ),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Settings()));
              },
            ),
            ListTile(
              leading: Icon(
                Icons.exit_to_app,
                color: Theme.of(context).textTheme.bodyText1.color,
              ),
              title: Text(
                'logout'.tr(),
                style: Theme.of(context).textTheme.bodyText1,
              ),
              onTap: () {
                _logout();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LoginOrRegisterPage()),
                        (r) => false);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(
                Icons.bug_report,
                color: Colors.red,
              ),
              title: Text(
                'report_a_bug'.tr(),
                style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>ReportABugPage()));
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Visibility(
        visible: _selectedIndex == 0,
        child: MainPageSpeedDial(callback: this.callback,),
      ),
      body: ConnectivityWidget(
        offlineBanner: Container(
            padding: EdgeInsets.all(8),
            width: double.infinity,
            color: Colors.red,
            child: Text(
              'no_connection'.tr(),
              style: TextStyle(
                  fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )
        ),
        builder: (context, isOnline){
          return TabBarView(
              physics: NeverScrollableScrollPhysics(),
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    await clearCache();
                    setState(() {

                    });
                  },
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      Balances(
                        callback: callback,
                      ),
                      History(
                        callback: callback,
                      )
                    ],
                  ),
                ),
                ShoppingList(),
                GroupSettings(),
              ]
          );
        }
      ),
    );
  }
  Future clearCache() async {
    await deleteCache(uri: '/groups/' + currentGroupId.toString());
    await deleteCache(uri: '/groups');
    await deleteCache(uri: '/user');
    await deleteCache(uri: '/payments?group=' + currentGroupId.toString());
    await deleteCache(uri: '/transactions?group=' + currentGroupId.toString());
  }
}
