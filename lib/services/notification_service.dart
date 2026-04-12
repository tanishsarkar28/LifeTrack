import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:ui';
import 'dart:isolate';
import '../models/task_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static void _addWaterTaskToHive() async {
    if (!Hive.isBoxOpen('tasks')) {
      await Hive.openBox<TaskModel>('tasks');
    }
    final box = Hive.box<TaskModel>('tasks');
    final task = TaskModel(
      id: 'water_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Drink Water',
      date: DateTime.now(),
      isCustom: true,
    )..isCompleted = true;
    await box.put(task.id, task);
  }

  static void onNotificationTapped(NotificationResponse response) {
    if (response.payload == 'water_reminder' && response.actionId == 'drank_water') {
      _addWaterTaskToHive();
    }
  }

  @pragma('vm:entry-point')
  static void onBackgroundNotificationTapped(NotificationResponse response) async {
    if (response.payload == 'water_reminder' && response.actionId == 'drank_water') {
      final SendPort? sendPort = IsolateNameServer.lookupPortByName('water_task_port');
      if (sendPort != null) {
        sendPort.send('drank_water');
      } else {
        WidgetsFlutterBinding.ensureInitialized();
        await Hive.initFlutter();
        if (!Hive.isAdapterRegistered(0)) { // Assuming TaskModelAdapter is 0, wait, better use proper initialization
          Hive.registerAdapter(TaskModelAdapter());
        }
        _addWaterTaskToHive();
      }
    }
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

    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );

    // changed to named argument.
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
    final AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'daily_task_channel',
      'Daily Task Reminders',
      channelDescription: 'Reminders for your scheduled daily tasks',
      importance: Importance.max,
      priority: Priority.high,
      actions: actions,
    );

    final NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

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
    const waterReminderTimes = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
    const actions = [
      AndroidNotificationAction('drank_water', 'Yes, drank 250ml', showsUserInterface: true),
    ];
    for (var i = 0; i < waterReminderTimes.length; i++) {
      await scheduleDailyTaskNotification(
        id: 1000 + i,
        title: 'Hydration Reminder',
        body: 'Drink 250 ml of water (1 glass) to keep your 3L goal on track.',
        hour: waterReminderTimes[i],
        minute: 0,
        actions: actions,
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
