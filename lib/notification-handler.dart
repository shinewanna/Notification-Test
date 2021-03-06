import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notitest/app-constant.dart';
import 'package:notitest/base-network.dart';
import 'package:notitest/resp.dart';
import 'package:notitest/shared-pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    new FlutterLocalNotificationsPlugin();

void showNotification(RemoteNotification? noti) async {
  if (noti == null) return;
  SharedPreferences pref = await SharedPreferences.getInstance();

  if (pref.getBool(SharedPref.isRecivingNoti) ?? true) {
    String title, body;

    title = noti.title ?? "";
    body = noti.body ?? "";

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      'your channel description',
      importance: Importance.max,
      priority: Priority.high,
    );

    var iOSPlatformChannelSpecifics = IOSNotificationDetails();

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      1,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}

class NotificationHandler extends BaseNetwork {
  final _firebaseMessaging = FirebaseMessaging.instance;

  configLocalNotification() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = IOSInitializationSettings();
    NotificationDetails();
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future<void> onSelectNotification(String? payload) async {
    if (payload != null) {
      //On Select Notification
    }
  }

  //!Can't stop showing foreground notification
  void registerNotification() async {
    var token = await _firebaseMessaging.getToken();
    if (token == null) return;
    FirebaseConstant.token = token;
    print(token);
    await _firebaseMessaging.requestPermission(provisional: true);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(message.notification!.body);
      showNotification(message.notification!);
    });

    //FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
  }

  test() {
    _firebaseMessaging.sendMessage(
      to: FirebaseConstant.token,
      data: {'title': 'tt', 'body': 'bb'},
      messageId: FirebaseConstant.token,
    );
  }

  Future<void> sendNotification({String? title, String? subtitle}) async {
    await Future.delayed(Duration(seconds: 2));
    var data = {
      "notification": {"body": subtitle, "title": title},
      "priority": "high",
      "content_available": true,
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "id": "1",
        "status": "done"
      },
      "to": FirebaseConstant.token
    };
    final headers = {
      'content-type': 'application/json',
      'Authorization': FirebaseConstant.serverToken,
    };

    Resp resp = await postReq(
      FirebaseConstant.sendUrl,
      "",
      fd: data,
      headers: headers,
      isReturnFuture: true,
    );

    if (resp.message.isError) {
      print(resp.data);
    } else {
      print('success');
    }
  }
}

final notificationHandler = NotificationHandler();
