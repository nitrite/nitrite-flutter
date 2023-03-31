import 'package:hive/hive.dart';
import 'package:nitrite/nitrite.dart';

class FieldsAdapter extends TypeAdapter<Fields> {
  @override
  int get typeId => 7;

  @override
  Fields read(BinaryReader reader) {
    var fields = reader.readStringList();
    return Fields.withNames(fields);
  }

  @override
  void write(BinaryWriter writer, Fields obj) {
    writer.writeStringList(obj.fieldNames);
  }
}
