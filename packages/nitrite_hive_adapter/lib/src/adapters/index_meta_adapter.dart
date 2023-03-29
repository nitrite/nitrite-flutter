import 'package:hive/hive.dart';
import 'package:nitrite/nitrite.dart';

class IndexMetaAdapter extends TypeAdapter<IndexMeta> {
  @override
  int get typeId => 7;

  @override
  IndexMeta read(BinaryReader reader) {
    var isDirty = reader.readBool();
    var indexMap = reader.read() as String?;
    var indexDescriptor = reader.read() as IndexDescriptor?;
    return IndexMeta()
      ..indexDescriptor = indexDescriptor
      ..indexMap = indexMap
      ..isDirty = isDirty;
  }

  @override
  void write(BinaryWriter writer, IndexMeta obj) {
    writer.writeBool(obj.isDirty);
    writer.write(obj.indexMap);
    writer.write(obj.indexDescriptor);
  }
}

class IndexDescriptorAdapter extends TypeAdapter<IndexDescriptor> {
  @override
  int get typeId => 8;

  @override
  IndexDescriptor read(BinaryReader reader) {
    var indexType = reader.readString();
    var collectionName = reader.readString();
    var fields = reader.read();
    return IndexDescriptor(indexType, fields, collectionName);
  }

  @override
  void write(BinaryWriter writer, IndexDescriptor obj) {
    writer.writeString(obj.indexType);
    writer.writeString(obj.collectionName);
    writer.write(obj.fields);
  }
}
