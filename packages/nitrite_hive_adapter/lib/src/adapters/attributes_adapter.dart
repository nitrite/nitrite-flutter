import 'package:hive/hive.dart';
import 'package:nitrite/nitrite.dart';

class AttributesAdapter extends TypeAdapter<Attributes> {
  @override
  int get typeId => 3;

  @override
  Attributes read(BinaryReader reader) {
    var map = reader.readMap();
    Attributes attr = Attributes();
    for (var element in map.entries) {
      attr.set(element.key, element.value);
    }
    return attr;
  }

  @override
  void write(BinaryWriter writer, Attributes obj) {
    var map = obj.toMap();
    writer.writeMap(map);
  }
}
