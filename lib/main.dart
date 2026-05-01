import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'utils/app_theme.dart';
import 'screens/main_screen.dart';

import 'models/task_model.dart';
import 'models/workout_model.dart';
import 'models/coding_model.dart';
import 'models/meal_model.dart';
import 'models/user_profile_model.dart';
import 'services/notification_service.dart';
import 'providers/data_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(WorkoutModelAdapter());
  Hive.registerAdapter(CodingModelAdapter());
  Hive.registerAdapter(MealModelAdapter());
  Hive.registerAdapter(UserProfileModelAdapter());

  // Set up Encryption
  const secureStorage = FlutterSecureStorage();
  String? encryptionKeyStr = await secureStorage.read(key: 'hive_encryption_key');
  List<int> encryptionKey;
  
  if (encryptionKeyStr == null) {
    // Generation and migration logic
    final key = Hive.generateSecureKey();
    await secureStorage.write(key: 'hive_encryption_key', value: base64UrlEncode(key));
    encryptionKey = key;

    // Open unencrypted FIRST to check for existing data
    final tasksBox = await Hive.openBox<TaskModel>('tasks');
    final workoutsBox = await Hive.openBox<WorkoutModel>('workouts');
    final codingBox = await Hive.openBox<CodingModel>('coding');
    final mealsBox = await Hive.openBox<MealModel>('meals');
    final profileBox = await Hive.openBox<UserProfileModel>('profile');
    final settingsBox = await Hive.openBox('settings');

    final hasData = tasksBox.isNotEmpty || workoutsBox.isNotEmpty || profileBox.isNotEmpty || settingsBox.isNotEmpty;

    if (hasData) {
      // 1. We have existing unencrypted data, copy it to memory by creating new instances
      final tasksData = tasksBox.toMap().map((key, value) => MapEntry(key, TaskModel(
        id: value.id,
        title: value.title,
        date: value.date,
        isCompleted: value.isCompleted,
        isCustom: value.isCustom,
        notificationHour: value.notificationHour,
        notificationMinute: value.notificationMinute,
        isDaily: value.isDaily,
      )));

      final workoutsData = workoutsBox.toMap().map((key, value) => MapEntry(key, WorkoutModel(
        id: value.id,
        category: value.category,
        exerciseName: value.exerciseName,
        setsCompleted: value.setsCompleted,
        isCompleted: value.isCompleted,
        date: value.date,
      )));

      final codingData = codingBox.toMap().map((key, value) => MapEntry(key, CodingModel(
        id: value.id,
        category: value.category,
        topic: value.topic,
        problemsSolved: value.problemsSolved,
        hoursSpent: value.hoursSpent,
        isCompleted: value.isCompleted,
        date: value.date,
      )));

      final mealsData = mealsBox.toMap().map((key, value) => MapEntry(key, MealModel(
        id: value.id,
        mealType: value.mealType,
        notes: value.notes,
        proteinGrams: value.proteinGrams,
        isCompleted: value.isCompleted,
        date: value.date,
      )));

      final profileData = profileBox.toMap().map((key, value) => MapEntry(key, UserProfileModel(
        name: value.name,
        height: value.height,
        weight: value.weight,
        targetWeight: value.targetWeight,
        startDate: value.startDate,
      )));

      final settingsData = settingsBox.toMap();

      // 2. Close and delete old unencrypted boxes
      await tasksBox.close();
      await workoutsBox.close();
      await codingBox.close();
      await mealsBox.close();
      await profileBox.close();
      await settingsBox.close();

      await Hive.deleteBoxFromDisk('tasks');
      await Hive.deleteBoxFromDisk('workouts');
      await Hive.deleteBoxFromDisk('coding');
      await Hive.deleteBoxFromDisk('meals');
      await Hive.deleteBoxFromDisk('profile');
      await Hive.deleteBoxFromDisk('settings');

      // 3. Open new boxes with encryption
      final cipher = HiveAesCipher(encryptionKey);
      final newTasksBox = await Hive.openBox<TaskModel>('tasks', encryptionCipher: cipher);
      final newWorkoutsBox = await Hive.openBox<WorkoutModel>('workouts', encryptionCipher: cipher);
      final newCodingBox = await Hive.openBox<CodingModel>('coding', encryptionCipher: cipher);
      final newMealsBox = await Hive.openBox<MealModel>('meals', encryptionCipher: cipher);
      final newProfileBox = await Hive.openBox<UserProfileModel>('profile', encryptionCipher: cipher);
      final newSettingsBox = await Hive.openBox('settings', encryptionCipher: cipher);

      // 4. Write data back
      await newTasksBox.putAll(tasksData);
      await newWorkoutsBox.putAll(workoutsData);
      await newCodingBox.putAll(codingData);
      await newMealsBox.putAll(mealsData);
      await newProfileBox.putAll(profileData);
      await newSettingsBox.putAll(settingsData);
    } else {
      // It was a new install, but we just created empty unencrypted boxes. 
      // We must delete them and reopen encrypted.
      await tasksBox.close();
      await workoutsBox.close();
      await codingBox.close();
      await mealsBox.close();
      await profileBox.close();
      await settingsBox.close();

      await Hive.deleteBoxFromDisk('tasks');
      await Hive.deleteBoxFromDisk('workouts');
      await Hive.deleteBoxFromDisk('coding');
      await Hive.deleteBoxFromDisk('meals');
      await Hive.deleteBoxFromDisk('profile');
      await Hive.deleteBoxFromDisk('settings');

      final cipher = HiveAesCipher(encryptionKey);
      await Hive.openBox<TaskModel>('tasks', encryptionCipher: cipher);
      await Hive.openBox<WorkoutModel>('workouts', encryptionCipher: cipher);
      await Hive.openBox<CodingModel>('coding', encryptionCipher: cipher);
      await Hive.openBox<MealModel>('meals', encryptionCipher: cipher);
      await Hive.openBox<UserProfileModel>('profile', encryptionCipher: cipher);
      await Hive.openBox('settings', encryptionCipher: cipher);
    }
  } else {
    // Key exists, open boxes normally with encryption
    encryptionKey = base64Url.decode(encryptionKeyStr);
    final cipher = HiveAesCipher(encryptionKey);
    await Hive.openBox<TaskModel>('tasks', encryptionCipher: cipher);
    await Hive.openBox<WorkoutModel>('workouts', encryptionCipher: cipher);
    await Hive.openBox<CodingModel>('coding', encryptionCipher: cipher);
    await Hive.openBox<MealModel>('meals', encryptionCipher: cipher);
    await Hive.openBox<UserProfileModel>('profile', encryptionCipher: cipher);
    await Hive.openBox('settings', encryptionCipher: cipher);
  }

  // Initialize Notifications
  await NotificationService.initialize();
  await NotificationService.scheduleWaterReminderNotifications();

  runApp(
    const ProviderScope(
      child: LifeTrackApp(),
    ),
  );
}

class LifeTrackApp extends ConsumerWidget {
  const LifeTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    return MaterialApp(
      title: 'LifeTrack AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(currentTheme),
      home: const MainScreen(),
    );
  }
}
