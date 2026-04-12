// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coding_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CodingModelAdapter extends TypeAdapter<CodingModel> {
  @override
  final int typeId = 2;

  @override
  CodingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CodingModel(
      id: fields[0] as String,
      category: fields[1] as String,
      topic: fields[2] as String,
      problemsSolved: fields[3] as int,
      hoursSpent: fields[4] as int,
      isCompleted: fields[5] as bool,
      date: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CodingModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.topic)
      ..writeByte(3)
      ..write(obj.problemsSolved)
      ..writeByte(4)
      ..write(obj.hoursSpent)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
