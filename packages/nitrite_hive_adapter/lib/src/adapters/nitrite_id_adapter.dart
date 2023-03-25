import 'package:hive/hive.dart';
import 'package:nitrite/nitrite.dart';

class NitriteIdAdapter extends TypeAdapter<NitriteId> {
  @override
  int get typeId => 1;

  @override
  NitriteId read(BinaryReader reader) {
    return NitriteId.createId(reader.readString());
  }

  @override
  void write(BinaryWriter writer, NitriteId obj) {
    writer.writeString(obj.idValue);
  }
}
