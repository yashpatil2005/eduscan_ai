import 'package:hive/hive.dart';

part 'todo_model.g.dart';

@HiveType(typeId: 2)
class TodoModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String description;

  @HiveField(2)
  DateTime taskDateTime;

  @HiveField(3)
  String category;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  int colorHex;

  @HiveField(6)
  int? reminderDaysBefore;

  // **NEW**: Field to enable/disable the reminder for this task.
  @HiveField(8)
  bool reminderEnabled;

  TodoModel({
    required this.title,
    required this.description,
    required this.taskDateTime,
    required this.category,
    this.isCompleted = false,
    required this.colorHex,
    this.reminderDaysBefore,
    this.reminderEnabled = true, // Default to true
  });
}
