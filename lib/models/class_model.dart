import 'package:hive/hive.dart';

part 'class_model.g.dart';

@HiveType(typeId: 1)
class ClassModel extends HiveObject {
  @HiveField(0)
  String subject;

  @HiveField(1)
  String courseCode;

  @HiveField(2)
  String instructor;

  @HiveField(3)
  String location;

  @HiveField(4)
  String category;

  @HiveField(5)
  String day;

  @HiveField(6)
  String startTime;

  @HiveField(7)
  String endTime;

  @HiveField(8)
  int colorHex;

  @HiveField(9)
  bool repeatWeekly;

  ClassModel({
    required this.subject,
    required this.courseCode,
    required this.instructor,
    required this.location,
    required this.category,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.colorHex,
    required this.repeatWeekly,
  });

  /// Converts a ClassModel instance into a Map (JSON object).
  Map<String, dynamic> toJson() => {
    'subject': subject,
    'courseCode': courseCode,
    'instructor': instructor,
    'location': location,
    'category': category,
    'day': day,
    'startTime': startTime,
    'endTime': endTime,
    'colorHex': colorHex,
    'repeatWeekly': repeatWeekly,
  };

  /// Creates a ClassModel instance from a Map (JSON object).
  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
    subject: json['subject'],
    courseCode: json['courseCode'],
    instructor: json['instructor'],
    location: json['location'],
    category: json['category'],
    day: json['day'],
    startTime: json['startTime'],
    endTime: json['endTime'],
    colorHex: json['colorHex'],
    repeatWeekly: json['repeatWeekly'],
  );
}
