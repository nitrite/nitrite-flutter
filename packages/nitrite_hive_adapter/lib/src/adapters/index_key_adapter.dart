import 'package:hive/hive.dart';
import 'package:nitrite/nitrite.dart';

/// @nodoc
///
/// Serializes the composite `(value, id)` keys used by non-unique indexes.
class IndexKeyAdapter extends TypeAdapter<IndexKey> {
  @override
  int get typeId => 7;

  @override
  IndexKey read(BinaryReader reader) {
    var value = reader.read() as DBValue;
    var id = reader.read() as NitriteId;
    return IndexKey(value, id);
  }

  @override
  void write(BinaryWriter writer, IndexKey obj) {
    writer.write(obj.value);
    writer.write(obj.id);
  }
}
