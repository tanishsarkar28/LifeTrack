import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  bool isCustom;

  @HiveField(5)
  int? notificationHour;

  @HiveField(6)
  int? notificationMinute;

  @HiveField(7, defaultValue: true)
  bool isDaily;

  TaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.date,
    this.isCustom = true,
    this.notificationHour,
    this.notificationMinute,
    this.isDaily = true,
  });
}
