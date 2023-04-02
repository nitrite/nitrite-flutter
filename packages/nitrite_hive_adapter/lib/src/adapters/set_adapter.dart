import 'package:hive/hive.dart';

class SetAdapter implements TypeAdapter<Set<dynamic>> {
  @override
  int get typeId => 3;

  @override
  Set read(BinaryReader reader) {
    var list = reader.readList();
    return list.toSet();
  }

  @override
  void write(BinaryWriter writer, Set<dynamic> obj) {
    writer.writeList(obj.toList());
  }
}
