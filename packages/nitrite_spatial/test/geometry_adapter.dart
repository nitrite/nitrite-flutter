import 'package:dart_jts/dart_jts.dart';
import 'package:hive/hive.dart';
import 'package:nitrite_spatial/nitrite_spatial.dart';

class GeometryAdapter extends TypeAdapter<Geometry> {
  @override
  Geometry read(BinaryReader reader) {
    var geomString = reader.readString();
    return GeometrySerializer.deserialize(geomString)!;
  }

  @override
  int get typeId => 21;

  @override
  void write(BinaryWriter writer, Geometry obj) {
    var geomString = GeometrySerializer.serialize(obj);
    writer.writeString(geomString!);
  }
}
