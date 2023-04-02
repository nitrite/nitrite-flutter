import 'package:hive/hive.dart';
import 'package:nitrite/nitrite.dart';

class DBValueAdapter extends TypeAdapter<DBValue> {
  @override
  int get typeId => 4;

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

class DBNullAdapter extends TypeAdapter<DBNull> {
  @override
  int get typeId => 5;

  @override
  void write(BinaryWriter writer, DBNull obj) {
    writer.write(null);
  }

  @override
  DBNull read(BinaryReader reader) {
    reader.read();
    return DBNull.instance;
  }
}
