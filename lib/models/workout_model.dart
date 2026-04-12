import 'package:hive/hive.dart';

part 'workout_model.g.dart';

@HiveType(typeId: 1)
class WorkoutModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String category; // Chest, Arms, Abs, Legs, Full Body

  @HiveField(2)
  String exerciseName;

  @HiveField(3)
  int setsCompleted;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  DateTime date;

  WorkoutModel({
    required this.id,
    required this.category,
    required this.exerciseName,
    this.setsCompleted = 0,
    this.isCompleted = false,
    required this.date,
  });
}
