import 'dart:io';

import 'package:csocsort_szamla/bootstrap.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'helpers/navigator_service.dart';

final getIt = GetIt.instance;

// Needed for HTTPS
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

// Future onSelectNotification(String? payload, UserState userProvider) async {
//   print("Payload: " + payload!);
//   try {
//     Map<String, dynamic> decoded = jsonDecode(payload);
//     int? groupId = decoded['group_id'];
//     String? groupName = decoded['group_name'];
//     String? groupCurrency = decoded['currency'];
//     String? page = decoded['screen'];
//     String? details = decoded['details'];

//     if (userProvider.user != null) {
//       if (groupId != null) {
//         userProvider.setGroup(Group(id: groupId, name: groupName!, currency: groupCurrency!));
//       }
//       clearAllCache();
//       if (page == 'home') {
//         int selectedIndex = 0;
//         if (details == 'payment') {
//           selectedIndex = 1;
//         }
//         getIt
//             .get<NavigationService>()
//             .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => MainPage(selectedHistoryIndex: selectedIndex)));
//       } else if (page == 'shopping') {
//         int selectedTab = 1;
//         getIt
//             .get<NavigationService>()
//             .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => MainPage(selectedIndex: selectedTab)));
//       } else if (page == 'store') {
//         getIt.get<NavigationService>().pushAndRemoveUntil(MaterialPageRoute(builder: (context) => StorePage()));
//       } else if (page == 'group_settings') {
//         int selectedTab = 2;
//         getIt
//             .get<NavigationService>()
//             .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => MainPage(selectedIndex: selectedTab)));
//       }
//     }
//   } catch (e) {
//     print(e.toString());
//   }
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  getIt.registerSingleton<NavigationService>(NavigationService());
  HttpOverrides.global = new MyHttpOverrides();
  runApp(Bootstrap());
}

// class LenderApp extends StatefulWidget {
//   const LenderApp();

//   @override
//   State<StatefulWidget> createState() => _LenderAppState();
// }

// class _LenderAppState extends State<LenderApp> {
//   //deeplink
//   StreamSubscription? _sub;
//   String? _link;
//   //in-app purchase
//   late StreamSubscription<List<PurchaseDetails>> _subscription;

//   void initUniLinks() {
//     _sub = linkStream.listen((String? link) {
//       _link = link;
//       print(link);
//       setState(() {
//         if (context.read<UserState>().user?.id != null) {
//           getIt.get<NavigationService>().push(MaterialPageRoute(
//               builder: (context) => JoinGroupPage(
//                   inviteURL: _link, fromAuth: (context.read<UserState>().user?.group == null) ? true : false)));
//         } else {
//           getIt.get<NavigationService>().push(MaterialPageRoute(builder: (context) => LoginOrRegisterPage()));
//         }
//       });
//     }, onError: (err) {
//       log(err);
//     });
//   }

//   void _createNotificationChannels(String groupId, List<String> channels) async {
//     AndroidNotificationChannelGroup androidNotificationChannelGroup =
//         AndroidNotificationChannelGroup(groupId, (groupId + '_notification').tr());
//     flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
//         .createNotificationChannelGroup(androidNotificationChannelGroup);

//     for (String channel in channels) {
//       flutterLocalNotificationsPlugin
//           .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
//           .createNotificationChannel(AndroidNotificationChannel(
//             channel,
//             (channel + '_notification').tr(),
//             description: (channel + '_notification_explanation').tr(),
//             groupId: groupId,
//           ));
//     }
//   }

//   Future setupInitialMessage() async {
//     RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

//     if (initialMessage != null) {
//       onSelectNotification(initialMessage.data['payload'], context.read<UserState>());
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     UserState userProvider = context.read<UserState>();
//     // if (isIAPPlatformEnabled) {
//     //   final Stream purchaseUpdates = InAppPurchase.instance.purchaseStream;
//     //   _subscription = purchaseUpdates.listen((purchases) {
//     //     // List<PurchaseDetails> purchasesList = purchases as List<PurchaseDetails>;
//     //     for (PurchaseDetails details in purchases) {
//     //       if (details.status == PurchaseStatus.purchased) {
//     //         String url = (!useTest ? APP_URL : TEST_URL) + '/user';
//     //         Map<String, String> header = {
//     //           "Content-Type": "application/json",
//     //           "Authorization": "Bearer " + userProvider.user!.apiToken,
//     //         };
//     //         Map<String, dynamic> body = {};
//     //         switch (details.productID) {
//     //           case 'remove_ads':
//     //             userProvider.setShownAds(false);
//     //             body['ad_free'] = 1;
//     //             break;
//     //           case 'gradients':
//     //             userProvider.setUseGradients(true);
//     //             body['gradients_enabled'] = 1;
//     //             break;
//     //           case 'ad_gradient_bundle':
//     //             userProvider.setShownAds(false);
//     //             body['ad_free'] = 1;
//     //             userProvider.setUseGradients(true);
//     //             body['gradients_enabled'] = 1;
//     //             break;
//     //           case 'group_boost':
//     //             body['boosts'] = 2;
//     //             break;
//     //           case 'big_lender_bundle':
//     //             userProvider.setShownAds(false);
//     //             body['ad_free'] = 1;
//     //             userProvider.setUseGradients(true);
//     //             body['gradients_enabled'] = 1;
//     //             body['boosts'] = 1;
//     //             break;
//     //         }
//     //         try {
//     //           http.put(Uri.parse(url), headers: header, body: jsonEncode(body));
//     //         } catch (_) {
//     //           throw _;
//     //         }
//     //         InAppPurchase.instance.completePurchase(details);
//     //       }
//     //     }
//     //     // _handlePurchaseUpdates(purchases);
//     //   }) as StreamSubscription<List<PurchaseDetails>>;
//     // }
//     if (isFirebasePlatformEnabled) {
//       initUniLinks();
//       _link = context.read<InviteUrlState>().inviteUrl;

//       var initializationSettingsAndroid = new AndroidInitializationSettings('@drawable/dodo');
//       final IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings();
//       var initializationSettings =
//           new InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

//       flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
//       flutterLocalNotificationsPlugin.initialize(initializationSettings,
//           onSelectNotification: (payload) => onSelectNotification(payload, userProvider));

//       Future.delayed(Duration(seconds: 1)).then((value) {
//         if (Platform.isAndroid) {
//           Future.delayed(Duration(seconds: 2)).then((value) {
//             _createNotificationChannels('group_system', ['other', 'group_update']);
//             _createNotificationChannels('purchase', ['purchase_created', 'purchase_modified', 'purchase_deleted']);
//             _createNotificationChannels('payment', ['payment_created', 'payment_modified', 'payment_deleted']);
//             _createNotificationChannels('shopping', ['shopping_created', 'shopping_fulfilled', 'shopping_shop']);
//             flutterLocalNotificationsPlugin
//                 .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
//                 .requestPermission();
//           });
//         }
//         setupInitialMessage();
//         FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//           print("onMessage: $message");
//           Map<String, dynamic> decoded = jsonDecode(message.data['payload']);
//           print(decoded);
//           var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
//               decoded['channel_id'], //only this is needed
//               (decoded['channel_id'] + '_notification'), // these don't do anything
//               channelDescription: (decoded['channel_id'] + '_notification_explanation'),
//               styleInformation: BigTextStyleInformation(''));
//           var iOSPlatformChannelSpecifics = new IOSNotificationDetails(presentSound: false);
//           var platformChannelSpecifics =
//               new NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
//           flutterLocalNotificationsPlugin.show(int.tryParse(message.data['id'] ?? '0') ?? 0,
//               message.notification!.title, message.notification!.body, platformChannelSpecifics,
//               payload: message.data['payload']);
//         });
//         FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//           onSelectNotification(message.data['payload'], userProvider);
//         });
//       });
//     }
//     // if (user != null) {
//     //   _getUserData(user);
//     // }
//     // _getExchangeRates();
//     // _supportedVersion().then((value) {
//     //   if (!(value ?? true)) {
//     //     getIt.get<NavigationService>().pushAndRemoveUntil(MaterialPageRoute(
//     //           builder: (context) => VersionNotSupportedPage(),
//     //         ));
//     //   }
//     // });
//   }

//   @override
//   dispose() {
//     if (_sub != null) _sub!.cancel();
//     _subscription.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ShowCaseWidget(
//       builder: Builder(builder: (context) {
//         return Consumer<UserState>(builder: (context, userProvider, _) {
//           return MaterialApp(
//             debugShowCheckedModeBanner: false,
//             title: 'Dodo',
//             theme: userProvider.theme,
//             localizationsDelegates: context.localizationDelegates,
//             supportedLocales: context.supportedLocales,
//             locale: context.locale,
//             builder: FToastBuilder(),
//             navigatorKey: getIt.get<NavigationService>().navigatorKey,
//             home: userProvider.user == null
//                 ? LoginOrRegisterPage()
//                 : (_link != null)
//                     ? JoinGroupPage(
//                         inviteURL: _link,
//                         fromAuth: (userProvider.user?.group == null) ? true : false,
//                       )
//                     : (userProvider.user?.group == null)
//                         ? JoinGroupPage(
//                             fromAuth: true,
//                           )
//                         : MainPage(),
//           );
//         });
//       }),
//     );
//   }
// }
