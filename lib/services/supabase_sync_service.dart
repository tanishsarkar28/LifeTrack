import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/supabase_config.dart';
import '../models/task_model.dart';
import '../models/workout_model.dart';
import '../models/user_profile_model.dart';
import '../models/coding_model.dart';
import '../models/meal_model.dart';

class SupabaseSyncService {
  SupabaseSyncService._privateConstructor();
  static final SupabaseSyncService instance = SupabaseSyncService._privateConstructor();

  final supabase = Supabase.instance.client;

  bool get isAuthenticated => supabase.auth.currentUser != null;

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final webClientId = SupabaseConfig.webClientId;
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled
      }
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      return await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In Error: $e');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    final webClientId = SupabaseConfig.webClientId;
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
    );
    await googleSignIn.signOut();
    await supabase.auth.signOut();
  }

  // Convert all Hive data to JSON
  Map<String, dynamic> _exportHiveData() {
    final data = <String, dynamic>{};
    
    final tasksBox = Hive.box<TaskModel>('tasks');
    data['tasks'] = tasksBox.values.map((t) => {
      'id': t.id,
      'title': t.title,
      'isCompleted': t.isCompleted,
      'date': t.date.toIso8601String(),
      'isCustom': t.isCustom,
      'notificationHour': t.notificationHour,
      'notificationMinute': t.notificationMinute,
      'isDaily': t.isDaily,
    }).toList();

    final workoutsBox = Hive.box<WorkoutModel>('workouts');
    data['workouts'] = workoutsBox.values.map((w) => {
      'id': w.id,
      'category': w.category,
      'exerciseName': w.exerciseName,
      'setsCompleted': w.setsCompleted,
      'isCompleted': w.isCompleted,
      'date': w.date.toIso8601String(),
    }).toList();

    final profileBox = Hive.box<UserProfileModel>('profile');
    if (profileBox.containsKey('currentUser')) {
      final p = profileBox.get('currentUser')!;
      data['profile'] = {
        'name': p.name,
        'height': p.height,
        'weight': p.weight,
        'targetWeight': p.targetWeight,
        'startDate': p.startDate.toIso8601String(),
      };
    }

    // Try exporting other optional models if registered
    if (Hive.isBoxOpen('coding')) {
      final codingBox = Hive.box<CodingModel>('coding');
      data['coding'] = codingBox.values.map((c) => {
        'id': c.id,
        'category': c.category,
        'topic': c.topic,
        'problemsSolved': c.problemsSolved,
        'hoursSpent': c.hoursSpent,
        'isCompleted': c.isCompleted,
        'date': c.date.toIso8601String(),
      }).toList();
    }

    if (Hive.isBoxOpen('meals')) {
      final mealsBox = Hive.box<MealModel>('meals');
      data['meals'] = mealsBox.values.map((m) => {
        'id': m.id,
        'mealType': m.mealType,
        'notes': m.notes,
        'proteinGrams': m.proteinGrams,
        'isCompleted': m.isCompleted,
        'date': m.date.toIso8601String(),
      }).toList();
    }

    final settingsBox = Hive.box('settings');
    final settingsMap = <String, dynamic>{};
    for (var key in settingsBox.keys) {
      if (key is String) {
        settingsMap[key] = settingsBox.get(key);
      }
    }
    data['settings'] = settingsMap;

    return data;
  }

  // Upload data silently
  Future<void> syncDataToSupabase() async {
    if (!isAuthenticated) return;

    try {
      final userId = supabase.auth.currentUser!.id;
      final payload = _exportHiveData();
      
      // JSON serialization check
      final jsonString = jsonEncode(payload);

      await supabase.from('user_data').upsert({
        'id': userId,
        'hive_payload': jsonDecode(jsonString),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      if (kDebugMode) print("Data synced to Supabase successfully.");
    } catch (e) {
      if (kDebugMode) print("Error syncing to Supabase: $e");
    }
  }

  // Apply downloaded JSON to Hive
  Future<void> restoreDataFromSupabase() async {
    if (!isAuthenticated) return;

    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('user_data')
          .select('hive_payload')
          .eq('id', userId)
          .maybeSingle();

      if (response == null || response['hive_payload'] == null) {
        // No data to restore
        return;
      }

      final payload = response['hive_payload'] as Map<String, dynamic>;

      // Load tasks
      if (payload['tasks'] != null) {
        final box = Hive.box<TaskModel>('tasks');
        await box.clear();
        for (var t in (payload['tasks'] as List)) {
          final task = TaskModel(
            id: t['id'],
            title: t['title'],
            isCompleted: t['isCompleted'],
            date: DateTime.parse(t['date']),
            isCustom: t['isCustom'] ?? true,
            notificationHour: t['notificationHour'],
            notificationMinute: t['notificationMinute'],
            isDaily: t['isDaily'] ?? true,
          );
          await box.put(task.id, task);
        }
      }

      // Load workouts
      if (payload['workouts'] != null) {
        final box = Hive.box<WorkoutModel>('workouts');
        await box.clear();
        for (var w in (payload['workouts'] as List)) {
          final workout = WorkoutModel(
            id: w['id'],
            category: w['category'],
            exerciseName: w['exerciseName'],
            setsCompleted: w['setsCompleted'] ?? 0,
            isCompleted: w['isCompleted'] ?? false,
            date: DateTime.parse(w['date']),
          );
          await box.put(workout.id, workout);
        }
      }

      // Load profile
      if (payload['profile'] != null) {
        final box = Hive.box<UserProfileModel>('profile');
        final p = payload['profile'];
        final profile = UserProfileModel(
          name: p['name'],
          height: (p['height'] as num).toDouble(),
          weight: (p['weight'] as num).toDouble(),
          targetWeight: (p['targetWeight'] as num).toDouble(),
          startDate: DateTime.parse(p['startDate']),
        );
        await box.put('currentUser', profile);
      }

      // Load coding
      if (payload['coding'] != null && Hive.isBoxOpen('coding')) {
        final box = Hive.box<CodingModel>('coding');
        await box.clear();
        for (var c in (payload['coding'] as List)) {
          final coding = CodingModel(
            id: c['id'],
            category: c['category'],
            topic: c['topic'],
            problemsSolved: c['problemsSolved'] ?? 0,
            hoursSpent: c['hoursSpent'] ?? 0,
            isCompleted: c['isCompleted'] ?? false,
            date: DateTime.parse(c['date']),
          );
          await box.put(coding.id, coding);
        }
      }

      // Load meals
      if (payload['meals'] != null && Hive.isBoxOpen('meals')) {
        final box = Hive.box<MealModel>('meals');
        await box.clear();
        for (var m in (payload['meals'] as List)) {
          final meal = MealModel(
            id: m['id'],
            mealType: m['mealType'],
            notes: m['notes'] ?? '',
            proteinGrams: m['proteinGrams'] ?? 0,
            isCompleted: m['isCompleted'] ?? false,
            date: DateTime.parse(m['date']),
          );
          await box.put(meal.id, meal);
        }
      }

      // Load settings
      if (payload['settings'] != null) {
        final settingsBox = Hive.box('settings');
        final settingsMap = payload['settings'] as Map<String, dynamic>;
        for (var entry in settingsMap.entries) {
          await settingsBox.put(entry.key, entry.value);
        }
      }

      // We don't trigger state update here directly because Riverpod providers 
      // will naturally pick up next time they initialize, OR we can invalidate providers.
    } catch (e) {
      if (kDebugMode) print("Error restoring from Supabase: $e");
    }
  }
}
