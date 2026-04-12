import 'package:hive/hive.dart';

part 'coding_model.g.dart';

@HiveType(typeId: 2)
class CodingModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String category; // DSA, AIML, Full Stack

  @HiveField(2)
  String topic; // Arrays, Strings, etc.

  @HiveField(3)
  int problemsSolved; // For DSA

  @HiveField(4)
  int hoursSpent; // For AIML / Full Stack

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  DateTime date;

  CodingModel({
    required this.id,
    required this.category,
    required this.topic,
    this.problemsSolved = 0,
    this.hoursSpent = 0,
    this.isCompleted = false,
    required this.date,
  });
}
