import 'package:hive/hive.dart';

part 'meal_model.g.dart';

@HiveType(typeId: 3)
class MealModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String mealType; // Breakfast, Lunch, Snacks, Dinner, Night Milk

  @HiveField(2)
  String notes;

  @HiveField(3)
  int proteinGrams;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  DateTime date;

  MealModel({
    required this.id,
    required this.mealType,
    this.notes = '',
    this.proteinGrams = 0,
    this.isCompleted = false,
    required this.date,
  });
}
