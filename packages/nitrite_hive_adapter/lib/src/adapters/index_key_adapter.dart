import 'package:hive/hive.dart';
import 'package:nitrite/nitrite.dart';

/// @nodoc
///
/// Serializes the composite `(values…, id)` keys used by non-unique indexes
/// (single-field and compound).
class IndexKeyAdapter extends TypeAdapter<IndexKey> {
  @override
  int get typeId => 7;

  @override
  IndexKey read(BinaryReader reader) {
    var n = reader.readByte();
    var values = [for (var i = 0; i < n; i++) reader.read() as DBValue];
    var id = reader.read() as NitriteId;
    return IndexKey.compound(values, id);
  }

  @override
  void write(BinaryWriter writer, IndexKey obj) {
    writer.writeByte(obj.values.length);
    for (var v in obj.values) {
      writer.write(v);
    }
    writer.write(obj.id);
  }
}
