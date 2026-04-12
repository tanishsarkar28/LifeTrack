import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'utils/app_theme.dart';
import 'screens/main_screen.dart';
import 'providers/data_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';

import 'models/task_model.dart';
import 'models/workout_model.dart';
import 'models/coding_model.dart';
import 'models/meal_model.dart';
import 'models/user_profile_model.dart';
import 'services/notification_service.dart';
import 'services/supabase_sync_service.dart';

import 'dart:isolate';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Register Adapters
  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(WorkoutModelAdapter());
  Hive.registerAdapter(CodingModelAdapter());
  Hive.registerAdapter(MealModelAdapter());
  Hive.registerAdapter(UserProfileModelAdapter());

  // Open Boxes
  await Hive.openBox<TaskModel>('tasks');
  await Hive.openBox<WorkoutModel>('workouts');
  await Hive.openBox<CodingModel>('coding');
  await Hive.openBox<MealModel>('meals');
  await Hive.openBox<UserProfileModel>('profile');
  await Hive.openBox('settings');

  // Register Isolate Port for background notifications
  final ReceivePort port = ReceivePort();
  IsolateNameServer.removePortNameMapping('water_task_port');
  IsolateNameServer.registerPortWithName(port.sendPort, 'water_task_port');
  port.listen((dynamic data) {
    if (data == 'drank_water') {
      final box = Hive.box<TaskModel>('tasks');
      final task = TaskModel(
        id: 'water_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Drink Water',
        date: DateTime.now(),
        isCustom: true,
      )..isCompleted = true;
      box.put(task.id, task);
    }
  });

  // Initialize Notifications
  await NotificationService.initialize();
  await NotificationService.scheduleWaterReminderNotifications();

  runApp(const ProviderScope(child: LifeTrackApp()));
}

class LifeTrackApp extends ConsumerStatefulWidget {
  const LifeTrackApp({super.key});

  @override
  ConsumerState<LifeTrackApp> createState() => _LifeTrackAppState();
}

class _LifeTrackAppState extends ConsumerState<LifeTrackApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      SupabaseSyncService.instance.syncDataToSupabase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeThemeType = ref.watch(themeProvider);
    return MaterialApp(
      title: 'LifeTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(activeThemeType),
      home: const MainScreen(),
    );
  }
}
