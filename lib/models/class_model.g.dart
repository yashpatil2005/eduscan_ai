// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClassModelAdapter extends TypeAdapter<ClassModel> {
  @override
  final int typeId = 1;

  @override
  ClassModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassModel(
      subject: fields[0] as String,
      courseCode: fields[1] as String,
      instructor: fields[2] as String,
      location: fields[3] as String,
      category: fields[4] as String,
      day: fields[5] as String,
      startTime: fields[6] as String,
      endTime: fields[7] as String,
      colorHex: fields[8] as int,
      repeatWeekly: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ClassModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.subject)
      ..writeByte(1)
      ..write(obj.courseCode)
      ..writeByte(2)
      ..write(obj.instructor)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.day)
      ..writeByte(6)
      ..write(obj.startTime)
      ..writeByte(7)
      ..write(obj.endTime)
      ..writeByte(8)
      ..write(obj.colorHex)
      ..writeByte(9)
      ..write(obj.repeatWeekly);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
