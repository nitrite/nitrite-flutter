import 'package:hive/hive.dart';
import 'package:nitrite/nitrite.dart';

class DBValueAdapter extends TypeAdapter<DBValue> {
  @override
  int get typeId => 5;

  @override
  DBValue read(BinaryReader reader) {
    var value = reader.read();
    return DBValue(value);
  }

  @override
  void write(BinaryWriter writer, DBValue obj) {
    writer.write(obj.value);
  }
}
