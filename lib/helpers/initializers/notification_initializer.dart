import 'dart:convert';
import 'dart:io';

import 'package:csocsort_szamla/common.dart';
import 'package:csocsort_szamla/helpers/http.dart';
import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/navigator_service.dart';
import 'package:csocsort_szamla/helpers/providers/app_config_provider.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:csocsort_szamla/main.dart';
import 'package:csocsort_szamla/pages/app/main_page.dart';
import 'package:csocsort_szamla/pages/app/store_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

class NotificationInitializer extends StatelessWidget {
  NotificationInitializer({required BuildContext context, required this.builder, super.key}) {
    init(context);
  }

  final Widget Function(BuildContext context) builder;

  void onSelectNotification(NotificationResponse response, BuildContext context) {
    String? payload = response.payload;
    if (payload == null) {
      return;
    }
    var userState = context.read<UserNotifier>();
    try {
      Map<String, dynamic> decoded = jsonDecode(payload);
      int? groupId = decoded['group_id'];
      String? page = decoded['screen'];
      String? details = decoded['details'];

      if (userState.user != null) {
        if (groupId != null) {
          userState.setGroup(Group.fromJson(decoded, true));
        }
        clearAllCache();
        if (page == 'home') {
          int selectedIndex = 0;
          if (details == 'payment') {
            selectedIndex = 1;
          }
          getIt.get<NavigationService>().pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => MainPage(selectedHistoryIndex: selectedIndex)),
              );
        } else if (page == 'shopping') {
          int selectedTab = 1;
          getIt.get<NavigationService>().pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => MainPage(selectedIndex: selectedTab)),
              );
        } else if (page == 'store') {
          getIt.get<NavigationService>().pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => StorePage()),
              );
        } else if (page == 'group_settings') {
          int selectedTab = 2;
          getIt.get<NavigationService>().pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => MainPage(selectedIndex: selectedTab)),
              );
        }
      }
    } catch (e) {
      log("Error at notification selection.", error: e);
    }
  }

  void _createNotificationChannels(String groupId, List<String> channels, FlutterLocalNotificationsPlugin plugin) async {
    AndroidNotificationChannelGroup androidNotificationChannelGroup = AndroidNotificationChannelGroup(groupId, ('${groupId}_notification').tr());
    plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!.createNotificationChannelGroup(androidNotificationChannelGroup);

    for (String channel in channels) {
      plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!.createNotificationChannel(AndroidNotificationChannel(
            channel,
            ('${channel}_notification').tr(),
            description: ('${channel}_notification_explanation').tr(),
            groupId: groupId,
          ));
    }
  }

  void init(BuildContext context) async {
    if (!context.read<AppConfig>().isFirebasePlatformEnabled) {
      return;
    }
    await Firebase.initializeApp();
    var notifications = FlutterLocalNotificationsPlugin();
    notifications.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@drawable/dodo'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (message) => onSelectNotification(message, context),
    );

    if (Platform.isAndroid) {
      notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!.requestNotificationsPermission();
    }
    Future.delayed(Duration(seconds: 1)).then((value) {
      if (Platform.isAndroid) {
        Future.delayed(Duration(seconds: 2)).then((value) {
          _createNotificationChannels('group_system', ['other', 'group_update'], notifications);
          _createNotificationChannels('purchase', ['purchase_created', 'purchase_modified', 'purchase_deleted'], notifications);
          _createNotificationChannels('payment', ['payment_created', 'payment_modified', 'payment_deleted'], notifications);
          _createNotificationChannels('shopping', ['shopping_created', 'shopping_fulfilled', 'shopping_shop'], notifications);
        });
      }
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          onSelectNotification(
            NotificationResponse(
              notificationResponseType: NotificationResponseType.selectedNotification,
              payload: message.data['payload'],
            ),
            context,
          );
        }
      });
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        Map<String, dynamic> decoded = jsonDecode(message.data['payload']);
        var androidPlatformChannelSpecifics = AndroidNotificationDetails(
          decoded['channel_id'], //only this is needed
          (decoded['channel_id'] + '_notification'), // these don't do anything
          channelDescription: (decoded['channel_id'] + '_notification_explanation'),
          styleInformation: BigTextStyleInformation(''),
        );
        var iOSPlatformChannelSpecifics = DarwinNotificationDetails(presentSound: false);
        var platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics,
        );
        notifications.show(
          int.tryParse(message.data['id'] ?? '0') ?? 0,
          message.notification!.title,
          message.notification!.body,
          platformChannelSpecifics,
          payload: message.data['payload'],
        );
      });
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => onSelectNotification(
          NotificationResponse(
            notificationResponseType: NotificationResponseType.selectedNotification,
            payload: message.data['payload'],
          ),
          // ignore: use_build_context_synchronously
          context,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => builder(context);
}
