import 'package:hive/hive.dart';
import 'package:nitrite/nitrite.dart';

class SpatialKeyAdapter extends TypeAdapter<SpatialKey> {
  // BUG: 64bit integers are not supported by BinaryReader/Writer, so we have to use a string for the id

  @override
  final int typeId = 19;

  @override
  SpatialKey read(BinaryReader reader) {
    final minMax = reader.readDoubleList();
    final id = reader.readString();
    return SpatialKey(int.parse(id), minMax);
  }

  @override
  void write(BinaryWriter writer, SpatialKey obj) {
    writer.writeDoubleList(obj.minMax);
    writer.writeString(obj.id.toString());
  }
}

class BoundingBoxAdapter extends TypeAdapter<BoundingBox> {
  @override
  final int typeId = 20;

  @override
  BoundingBox read(BinaryReader reader) {
    final minX = reader.readDouble();
    final minY = reader.readDouble();
    final maxX = reader.readDouble();
    final maxY = reader.readDouble();
    return BoundingBox(minX, minY, maxX, maxY);
  }

  @override
  void write(BinaryWriter writer, BoundingBox obj) {
    writer.writeDouble(obj.minX);
    writer.writeDouble(obj.minY);
    writer.writeDouble(obj.maxX);
    writer.writeDouble(obj.maxY);
  }
}
