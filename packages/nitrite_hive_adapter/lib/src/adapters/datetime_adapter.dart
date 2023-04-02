import 'package:hive/hive.dart';

class DateTimeAdapter extends TypeAdapter<DateTime> {
  @override
  int get typeId => 18;

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeString(obj.toIso8601String());
  }

  @override
  DateTime read(BinaryReader reader) {
    return DateTime.parse(reader.readString());
  }
}
