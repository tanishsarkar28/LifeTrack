import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../models/workout_model.dart';
import '../models/coding_model.dart';
import '../models/meal_model.dart';
import '../models/user_profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../services/supabase_sync_service.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Helper functions for key generation
String _progressKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return 'task_progress_${normalized.toIso8601String().split('T').first}';
}

String _progressDetailsKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return 'task_progress_details_${normalized.toIso8601String().split('T').first}';
}

String _waterProgressKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return 'water_progress_${normalized.toIso8601String().split('T').first}';
}

String _workoutProgressKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return 'workout_progress_${normalized.toIso8601String().split('T').first}';
}

String _workoutCalendarIncludeKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return 'workout_calendar_include_${normalized.toIso8601String().split('T').first}';
}

// Theme Provider
enum AppThemeType { darkBlue, midnightBlack, forestGreen, neonCyberpunk }

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeType>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<AppThemeType> {
  @override
  AppThemeType build() {
    final settingsBox = Hive.box('settings');
    final savedTheme = settingsBox.get('app_theme_string');
    if (savedTheme != null) {
      return AppThemeType.values.firstWhere(
        (e) => e.name == savedTheme,
        orElse: () => AppThemeType.darkBlue,
      );
    }
    return AppThemeType.darkBlue;
  }

  void setTheme(AppThemeType type) {
    if (state != type) {
      final settingsBox = Hive.box('settings');
      settingsBox.put('app_theme_string', type.name);
      state = type;
      SupabaseSyncService.instance.syncDataToSupabase();
    }
  }
}

// Tasks Provider
final taskProvider = NotifierProvider<TaskNotifier, List<TaskModel>>(() {
  return TaskNotifier();
});

class TaskNotifier extends Notifier<List<TaskModel>> {
  @override
  List<TaskModel> build() {
    final box = Hive.box<TaskModel>('tasks');
    final sub = box.watch().listen((_) {
      state = _loadTasks();
    });
    ref.onDispose(() => sub.cancel());
    return _loadTasks();
  }

  List<TaskModel> _loadTasks() {
    final box = Hive.box<TaskModel>('tasks');
    var tasks = box.values.toList();

    // Check reset at 12 AM
    final settingsBox = Hive.box('settings');
    final lastResetStr = settingsBox.get('last_reset');
    DateTime? lastReset = lastResetStr != null
        ? DateTime.tryParse(lastResetStr)
        : null;
    DateTime now = DateTime.now();
    DateTime todayMidnight = DateTime(now.year, now.month, now.day, 0, 0, 0);

    DateTime currentBoundary = todayMidnight;

    if (lastReset == null) {
      // First time launch -> do not fail yesterday, just initialize last_reset
      settingsBox.put('last_reset', now.toIso8601String());
    } else if (lastReset.isBefore(currentBoundary)) {
      _saveDailyProgress(
        currentBoundary.subtract(const Duration(days: 1)),
        tasks,
      );

      final keysToRemove = <dynamic>[];
      for (var task in tasks) {
        if (task.isDaily) {
          task.isCompleted = false;
          task.save();
        } else {
          if (task.notificationHour != null) {
            NotificationService.cancelNotification(task.id.hashCode);
          }
          keysToRemove.add(task.key);
        }
      }
      if (keysToRemove.isNotEmpty) {
        box.deleteAll(keysToRemove);
        tasks = box.values.toList();
      }
      settingsBox.put('last_reset', now.toIso8601String());
    }

    if (tasks.isEmpty) {
      tasks = _seedDummyData(box);
    }
    _sortTasks(tasks);
    return tasks;
  }

  void _sortTasks(List<TaskModel> tasksList) {
    tasksList.sort((a, b) {
      // Put tasks without time at the bottom
      if (a.notificationHour == null && b.notificationHour == null) return 0;
      if (a.notificationHour == null) return 1;
      if (b.notificationHour == null) return -1;

      final timeA = a.notificationHour! * 60 + a.notificationMinute!;
      final timeB = b.notificationHour! * 60 + b.notificationMinute!;
      return timeA.compareTo(timeB);
    });
  }

  void _saveDailyProgress(DateTime date, List<TaskModel> tasks) {
    final settingsBox = Hive.box('settings');
    final boxWorkout = Hive.box<WorkoutModel>('workouts');
    final dateOnly = DateTime(date.year, date.month, date.day);
    final completedTasks = tasks
        .where((t) => t.isCompleted)
        .map((t) => t.title)
        .toList();
    final incompleteTasks = tasks
        .where((t) => !t.isCompleted)
        .map((t) => t.title)
        .toList();
    final completedCount = completedTasks.length;
    final totalCount = tasks.length;
    final taskProgress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    final waterTasks = tasks
        .where((t) => t.title.toLowerCase().contains('water'))
        .toList();
    final waterCompleted = waterTasks.where((t) => t.isCompleted).length;
    final waterTotal = waterTasks.length;
    final waterProgress = waterTotal == 0 ? 0.0 : waterCompleted / waterTotal;

    final workoutTasks = boxWorkout.values.where((w) {
      final day = DateTime(w.date.year, w.date.month, w.date.day);
      return day == dateOnly;
    }).toList();
    final workoutCompleted = workoutTasks.where((w) => w.isCompleted).length;
    final workoutTotal = workoutTasks.length;
    final workoutProgress = workoutTotal == 0
        ? 0.0
        : workoutCompleted / workoutTotal;

    settingsBox.put(_progressKey(dateOnly), taskProgress);
    settingsBox.put(_waterProgressKey(dateOnly), waterProgress);
    settingsBox.put(_workoutProgressKey(dateOnly), workoutProgress);
    settingsBox.put(_progressDetailsKey(dateOnly), {
      'completedCount': completedCount,
      'totalCount': totalCount,
      'completedTitles': completedTasks,
      'incompleteTitles': incompleteTasks,
      'waterCompleted': waterCompleted,
      'waterTotal': waterTotal,
      'workoutCompleted': workoutCompleted,
      'workoutTotal': workoutTotal,
    });
  }

  List<TaskModel> _seedDummyData(Box<TaskModel> box) {
    final dummyTasks = [
      TaskModel(
        id: '1',
        title: 'Morning Workout',
        date: DateTime.now(),
        isCustom: false,
      ),
      TaskModel(
        id: '2',
        title: 'Eat Breakfast',
        date: DateTime.now(),
        isCustom: false,
      ),
      TaskModel(
        id: '3',
        title: 'DSA Practice',
        date: DateTime.now(),
        isCustom: false,
      ),
      TaskModel(
        id: '4',
        title: 'AIML Learning',
        date: DateTime.now(),
        isCustom: false,
      ),
      TaskModel(
        id: '5',
        title: 'Full Stack Development',
        date: DateTime.now(),
        isCustom: false,
      ),
      TaskModel(
        id: '6',
        title: 'Drink Water',
        date: DateTime.now(),
        isCustom: false,
      ),
      TaskModel(
        id: '7',
        title: 'Evening Walk',
        date: DateTime.now(),
        isCustom: false,
      ),
      TaskModel(
        id: '8',
        title: 'Review Learning',
        date: DateTime.now(),
        isCustom: false,
      ),
      TaskModel(
        id: '9',
        title: 'Sleep on Time',
        date: DateTime.now(),
        isCustom: false,
      ),
    ];
    for (var task in dummyTasks) {
      box.put(task.id, task);
    }
    return dummyTasks;
  }

  void toggleTaskCompletion(String id) {
    final box = Hive.box<TaskModel>('tasks');
    final task = box.get(id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      task.save();
      var newTasks = box.values.toList();
      _sortTasks(newTasks);
      state = newTasks;
      SupabaseSyncService.instance.syncDataToSupabase();
    }
  }

  void addTask(TaskModel task) {
    final box = Hive.box<TaskModel>('tasks');
    box.put(task.id, task);
    var newTasks = box.values.toList();
    _sortTasks(newTasks);
    state = newTasks;
    SupabaseSyncService.instance.syncDataToSupabase();
  }

  void removeTask(String id) {
    final box = Hive.box<TaskModel>('tasks');
    box.delete(id);
    var newTasks = box.values.toList();
    _sortTasks(newTasks);
    state = newTasks;
    SupabaseSyncService.instance.syncDataToSupabase();
  }

  void updateTask(TaskModel updatedTask) {
    final box = Hive.box<TaskModel>('tasks');
    box.put(updatedTask.id, updatedTask);
    updatedTask.save();
    var newTasks = box.values.toList();
    _sortTasks(newTasks);
    state = newTasks;
    SupabaseSyncService.instance.syncDataToSupabase();
  }

  int get completedTasks => state.where((t) => t.isCompleted).length;
  double get completionPercentage =>
      state.isEmpty ? 0 : completedTasks / state.length;
}

// Workouts Provider
final workoutProvider = NotifierProvider<WorkoutNotifier, List<WorkoutModel>>(
  () {
    return WorkoutNotifier();
  },
);

class WorkoutNotifier extends Notifier<List<WorkoutModel>> {
  @override
  List<WorkoutModel> build() {
    return _loadWorkouts();
  }

  List<WorkoutModel> _loadWorkouts() {
    final box = Hive.box<WorkoutModel>('workouts');
    var workouts = box.values.toList();
    // If empty or has old category format, re-seed
    if (workouts.isEmpty ||
        workouts.any(
          (w) => [
            'Chest',
            'Arms',
            'Abs',
            'Legs',
            'Full Body',
          ].contains(w.category),
        )) {
      return _seedDummyData(box);
    }
    return workouts;
  }

  List<WorkoutModel> _seedDummyData(Box<WorkoutModel> box) {
    final dummyWorkouts = [
      // Monday
      WorkoutModel(
        id: 'w1',
        category: 'Monday',
        exerciseName: 'Push-ups 12 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w2',
        category: 'Monday',
        exerciseName: 'Incline Push-ups 10 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w3',
        category: 'Monday',
        exerciseName: 'Decline Push-ups 8 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w4',
        category: 'Monday',
        exerciseName: 'Crunches 20 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w5',
        category: 'Monday',
        exerciseName: 'Plank 30 sec',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      // Tuesday
      WorkoutModel(
        id: 'w6',
        category: 'Tuesday',
        exerciseName: 'Backpack Curls 15 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w7',
        category: 'Tuesday',
        exerciseName: 'Towel Curls 15 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w8',
        category: 'Tuesday',
        exerciseName: 'Diamond Push-ups 8 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w9',
        category: 'Tuesday',
        exerciseName: 'Leg Raises 15 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      // Wednesday
      WorkoutModel(
        id: 'w10',
        category: 'Wednesday',
        exerciseName: 'Squats 20 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w11',
        category: 'Wednesday',
        exerciseName: 'Lunges 15 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w12',
        category: 'Wednesday',
        exerciseName: 'Jump Squats 12 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w13',
        category: 'Wednesday',
        exerciseName: 'Calf Raises 25 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      // Thursday
      WorkoutModel(
        id: 'w14',
        category: 'Thursday',
        exerciseName: 'Push-ups 12 reps',
        setsCompleted: 4,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w15',
        category: 'Thursday',
        exerciseName: 'Incline Push-ups 12 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w16',
        category: 'Thursday',
        exerciseName: 'Backpack Curls 15 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      // Friday
      WorkoutModel(
        id: 'w17',
        category: 'Friday',
        exerciseName: 'Crunches 25 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w18',
        category: 'Friday',
        exerciseName: 'Bicycle Crunch 20 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w19',
        category: 'Friday',
        exerciseName: 'Plank 45 sec',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      // Saturday
      WorkoutModel(
        id: 'w20',
        category: 'Saturday',
        exerciseName: 'Push-ups 12 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w21',
        category: 'Saturday',
        exerciseName: 'Squats 20 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w22',
        category: 'Saturday',
        exerciseName: 'Lunges 15 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w23',
        category: 'Saturday',
        exerciseName: 'Plank 30 sec',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
      WorkoutModel(
        id: 'w24',
        category: 'Saturday',
        exerciseName: 'Mountain Climbers 20 reps',
        setsCompleted: 3,
        date: DateTime.now(),
      ),
    ];

    // Using Future.microtask ensures the clear awaits on disk asynchronously,
    // avoiding the wipe-out that happens if it is called synchronously alongside puts.
    Future.microtask(() async {
      await box.clear();
      for (var w in dummyWorkouts) {
        await box.put(w.id, w);
      }
    });

    return dummyWorkouts;
  }

  void toggleWorkoutCompletion(String id) {
    // Highly resilient check via the Riverpod state directly
    final index = state.indexWhere((w) => w.id == id);
    if (index != -1) {
      final workout = state[index];
      workout.isCompleted = !workout.isCompleted;

      // Resave to Hive box
      final box = Hive.box<WorkoutModel>('workouts');
      box.put(workout.id, workout);
      workout.save();

      // Trigger rebuild
      state = [...state];
      SupabaseSyncService.instance.syncDataToSupabase();
    }
  }
}

// Score Logic
final dailyScoreProvider = Provider<int>((ref) {
  final tasks = ref.watch(taskProvider);
  // Add other models here to calculate score accurately based on user criteria.
  int score = 0;
  for (var task in tasks) {
    if (task.isCompleted) score += 10;
  }
  return score > 100 ? 100 : score;
});

final taskProgressProvider = Provider<Map<DateTime, double>>((ref) {
  final tasks = ref.watch(taskProvider);
  final workouts = ref.watch(workoutProvider);
  final workoutInclusion = ref.watch(workoutCalendarInclusionProvider);
  final settingsBox = Hive.box('settings');
  final history = <DateTime, double>{};

  String _waterProgressKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return 'water_progress_${normalized.toIso8601String().split('T').first}';
  }

  String _workoutProgressKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return 'workout_progress_${normalized.toIso8601String().split('T').first}';
  }

  String _workoutCalendarIncludeKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return 'workout_calendar_include_${normalized.toIso8601String().split('T').first}';
  }

  for (var key in settingsBox.keys) {
    if (key is String &&
        key.startsWith('task_progress_') &&
        !key.startsWith('task_progress_details_')) {
      final taskValue = settingsBox.get(key);
      if (taskValue is num) {
        final dateStr = key.replaceFirst('task_progress_', '');
        try {
          final date = DateTime.parse(dateStr);
          final dateOnly = DateTime(date.year, date.month, date.day);
          final taskProgress = taskValue.toDouble();

          final waterValue = settingsBox.get(_waterProgressKey(dateOnly));
          final workoutValue = settingsBox.get(_workoutProgressKey(dateOnly));
          final bool workoutEnabled =
              settingsBox.get(_workoutCalendarIncludeKey(dateOnly)) as bool? ??
              true;

          final values = <double>[taskProgress];
          if (waterValue is num) {
            values.add(waterValue.toDouble());
          }
          if (workoutEnabled && workoutValue is num) {
            values.add(workoutValue.toDouble());
          }

          final combined = values.isNotEmpty
              ? values.reduce((a, b) => a + b) / values.length
              : 0.0;
          history[dateOnly] = combined.clamp(0.0, 1.0);
        } catch (_) {}
      }
    }
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayTasks = tasks
      .where((t) => DateTime(t.date.year, t.date.month, t.date.day) == today)
      .toList();
  if (todayTasks.isNotEmpty) {
    final completedTaskCount = todayTasks.where((t) => t.isCompleted).length;
    final taskProgress = todayTasks.isEmpty
        ? 0.0
        : completedTaskCount / todayTasks.length;
    final waterTasks = todayTasks
        .where((t) => t.title.toLowerCase().contains('water'))
        .toList();
    final waterCompleted = waterTasks.where((t) => t.isCompleted).length;
    final waterProgress = waterTasks.isEmpty
        ? 0.0
        : waterCompleted / waterTasks.length;

    final todayWorkouts = workouts.where((w) {
      final dateOnly = DateTime(w.date.year, w.date.month, w.date.day);
      return dateOnly == today;
    }).toList();
    final workoutCompleted = todayWorkouts.where((w) => w.isCompleted).length;
    final workoutProgress = todayWorkouts.isEmpty
        ? 0.0
        : workoutCompleted / todayWorkouts.length;
    final workoutEnabled = workoutInclusion[today] ?? true;

    final values = <double>[taskProgress];
    if (waterTasks.isNotEmpty) values.add(waterProgress);
    if (workoutEnabled && todayWorkouts.isNotEmpty) values.add(workoutProgress);
    history[today] = (values.reduce((a, b) => a + b) / values.length).clamp(
      0.0,
      1.0,
    );
  }

  return history;
});

final taskProgressDetailsProvider =
    Provider<Map<DateTime, Map<String, dynamic>>>((ref) {
      ref.watch(taskProvider);
      final settingsBox = Hive.box('settings');
      final history = <DateTime, Map<String, dynamic>>{};

      for (var key in settingsBox.keys) {
        if (key is String && key.startsWith('task_progress_details_')) {
          final value = settingsBox.get(key);
          if (value is Map) {
            final dateStr = key.replaceFirst('task_progress_details_', '');
            try {
              final date = DateTime.parse(dateStr);
              history[DateTime(date.year, date.month, date.day)] =
                  Map<String, dynamic>.from(value.cast<String, dynamic>());
            } catch (_) {}
          }
        }
      }

      return history;
    });

final workoutCalendarInclusionProvider =
    NotifierProvider<WorkoutCalendarInclusionNotifier, Map<DateTime, bool>>(() {
      return WorkoutCalendarInclusionNotifier();
    });

class WorkoutCalendarInclusionNotifier extends Notifier<Map<DateTime, bool>> {
  @override
  Map<DateTime, bool> build() {
    return _loadInclusions();
  }

  Map<DateTime, bool> _loadInclusions() {
    final settingsBox = Hive.box('settings');
    final history = <DateTime, bool>{};
    for (var key in settingsBox.keys) {
      if (key is String && key.startsWith('workout_calendar_include_')) {
        final value = settingsBox.get(key);
        if (value is bool) {
          final dateStr = key.replaceFirst('workout_calendar_include_', '');
          try {
            final date = DateTime.parse(dateStr);
            history[DateTime(date.year, date.month, date.day)] = value;
          } catch (_) {}
        }
      }
    }
    return history;
  }

  bool isIncluded(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return state[dateOnly] ?? true;
  }

  void toggle(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final current = state[dateOnly] ?? true;
    final newValue = !current;
    final settingsBox = Hive.box('settings');
    settingsBox.put(_workoutCalendarIncludeKey(dateOnly), newValue);
    state = {...state, dateOnly: newValue};
    SupabaseSyncService.instance.syncDataToSupabase();
  }
}

// User Profile Provider
final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfileModel?>(() {
      return UserProfileNotifier();
    });

class UserProfileNotifier extends Notifier<UserProfileModel?> {
  @override
  UserProfileModel? build() {
    return _loadProfile();
  }

  UserProfileModel? _loadProfile() {
    final box = Hive.box<UserProfileModel>('profile');
    if (box.isNotEmpty) {
      return box.get('currentUser');
    }

    // Default dummy profile until configured
    return UserProfileModel(
      name: 'User',
      height: 175.0,
      weight: 75.0,
      targetWeight: 68.0,
      startDate: DateTime.now(),
    );
  }

  void saveProfile({
    required String name,
    required double height,
    required double weight,
    required double targetWeight,
    required DateTime startDate,
  }) {
    final box = Hive.box<UserProfileModel>('profile');
    final profile = UserProfileModel(
      name: name,
      height: height,
      weight: weight,
      targetWeight: targetWeight,
      startDate: startDate,
    );
    box.put('currentUser', profile);
    state = profile;
    SupabaseSyncService.instance.syncDataToSupabase();
  }
}
