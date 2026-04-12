import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 4)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double height;

  @HiveField(2)
  double weight;

  @HiveField(3)
  double targetWeight;

  @HiveField(4)
  DateTime startDate;

  UserProfileModel({
    required this.name,
    required this.height,
    required this.weight,
    required this.targetWeight,
    required this.startDate,
  });
}
