import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _notificationsEnabled = false;

  static bool get notificationsEnabled {
    return _notificationsEnabled;
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      _notificationsEnabled = await _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              ) ??
          false;
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();
      final bool? grantedScheduledNotificationPermission =
          await androidImplementation?.requestExactAlarmsPermission();
      _notificationsEnabled = grantedNotificationPermission ?? false;
      _notificationsEnabled = grantedScheduledNotificationPermission ?? false;
    }
  }

  static Future<void> init() async {
    await _requestPermissions();

    final currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    const androidInit = AndroidInitializationSettings("app_icon");
    final iosInit = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          'demoCategory',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain('id_1', 'Action 1'),
            DarwinNotificationAction.plain(
              'id_2',
              'Action 2',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.destructive,
              },
            ),
            DarwinNotificationAction.plain(
              'id_3',
              'Action 3',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
          options: <DarwinNotificationCategoryOption>{
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
          },
        )
      ],
    );
    final initNotification = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initNotification,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        print(notificationResponse.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static void showNotification({
    int id = 0,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      "GoodChannelId",
      "GoodChannelName",
      sound: RawResourceAndroidNotificationSound("slow_spring_board"),
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: "ticker",
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('id_1', 'Action 1'),
        AndroidNotificationAction('id_2', 'Action 2'),
        AndroidNotificationAction('id_3', 'Action 3'),
      ],
    );
    const iosDetails = DarwinNotificationDetails(
      sound: "slow_spring_board.aiff",
      categoryIdentifier: "demoCategory",
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: "Hello World",
    );
  }

  static void scheduleNotification({
    int id = 0,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      "GoodChannelId",
      "GoodChannelName",
      sound: RawResourceAndroidNotificationSound("slow_spring_board"),
      importance: Importance.max,
    );
    const iosDetails = DarwinNotificationDetails(
      sound: "slow_spring_board.aiff",
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: "Hello World",
    );
  }

  static void periodicallyShowNotification({
    int id = 0,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      "GoodChannelId",
      "GoodChannelName",
      sound: RawResourceAndroidNotificationSound("slow_spring_board"),
      importance: Importance.max,
    );
    const iosDetails = DarwinNotificationDetails(
      sound: "slow_spring_board.aiff",
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.periodicallyShowWithDuration(
      id,
      title,
      body,
      const Duration(seconds: 60),
      notificationDetails,
      payload: "Hello World",
    );
  }

  static Future<NotificationDetails> _groupedNotificationDetails() async {
    const List<String> lines = <String>[
      'Team 1 Play Badminton',
      'Team 1   Play Volleyball',
      'Team 1   Play Cricket',
      'Team 2 Play Badminton',
      'Team 2   Play Volleyball'
    ];
    const InboxStyleInformation inboxStyleInformation = InboxStyleInformation(
      lines,
      contentTitle: '5 messages',
      summaryText: 'missed messages',
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
      'channel id',
      'channel name',
      sound: RawResourceAndroidNotificationSound("slow_spring_board"),
      groupKey: 'com.example.flutter_push_notifications',
      channelDescription: 'channel description',
      setAsGroupSummary: true,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      ticker: 'ticker',
      styleInformation: inboxStyleInformation,
      color: Color(0xff2196f3),
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(threadIdentifier: "thread2");

    final details = await _flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();

    NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iosNotificationDetails);

    return platformChannelSpecifics;
  }

  static Future<void> showGroupedNotifications({
    required String title,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      "GoodChannelId",
      "GoodChannelName",
      sound: RawResourceAndroidNotificationSound("slow_spring_board"),
      importance: Importance.max,
    );
    const iosDetails = DarwinNotificationDetails(
      sound: "slow_spring_board.aiff",
    );
    const platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final groupedPlatformChannelSpecifics = await _groupedNotificationDetails();
    await _flutterLocalNotificationsPlugin.show(
      0,
      "Team 1",
      "Play Badminton ",
      platformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      1,
      "Team 1",
      "Play Volleyball",
      platformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      3,
      "Team 1",
      "Play Cricket",
      platformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      4,
      "Team 2",
      "Play Badminton",
      Platform.isIOS
          ? groupedPlatformChannelSpecifics
          : platformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      5,
      "Team 2",
      "Play Volleyball",
      Platform.isIOS
          ? groupedPlatformChannelSpecifics
          : platformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      6,
      Platform.isIOS ? "Team 2" : "Attention",
      Platform.isIOS ? "Play Cricket" : "5 missed messages",
      groupedPlatformChannelSpecifics,
    );
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(
    NotificationResponse notificationResponse,
  ) {
    print("on background tap");
  }
}
