import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';
import 'dart:isolate';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static ReceivePort? _receivePort;

  static void onNotificationTapped(NotificationResponse response) {
    // Handle foreground taps if needed
  }

  @pragma('vm:entry-point')
  static void onBackgroundNotificationTapped(NotificationResponse response) async {
    // Handle background taps if needed
  }

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      // Ensure we use the exact alias (identifier) for timezone package 
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      if (kDebugMode) print('Could not get local timezone');
    }

    _receivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping('water_task_port');
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, 'water_task_port');

    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationTapped,
    );

    _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleDailyTaskNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    List<AndroidNotificationAction>? actions,
    String? payload,
  }) async {
    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'daily_task_channel',
      'Daily Task Reminders',
      channelDescription: 'Reminders for your scheduled daily tasks',
      importance: Importance.max,
      priority: Priority.high,
      actions: actions,
    );

    NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  static Future<void> scheduleWaterReminderNotifications() async {
    const waterReminderTimes = [9, 11, 13, 15, 17, 19, 21, 23];
    for (var i = 0; i < waterReminderTimes.length; i++) {
      await scheduleDailyTaskNotification(
        id: 1000 + i,
        title: 'Hydration Reminder',
        body: 'Drink some water and keep your 2L goal on track.',
        hour: waterReminderTimes[i],
        minute: 0,
        payload: 'water_reminder',
      );
    }
  }

  static Future<void> cancelNotification(int id) async {
    // converted to named argument
    await _notificationsPlugin.cancel(id: id);
  }

  static Future<void> showNotification({required int id, required String title, required String body}) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'lifetrack_channel',
      'LifeTrack Notifications',
      channelDescription: 'Reminders for Tasks and Workouts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

    // converted to named arguments
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}
