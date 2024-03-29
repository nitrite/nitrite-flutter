import 'package:hive/hive.dart';
import 'package:nitrite/nitrite.dart';

/// @nodoc
class DocumentAdapter extends TypeAdapter<Document> {
  @override
  int get typeId => 2;

  @override
  Document read(BinaryReader reader) {
    var map = reader.readMap().cast<String, dynamic>();
    var document = emptyDocument();
    map.forEach((key, value) {
      document.put(key, value);
    });
    return document;
  }

  @override
  void write(BinaryWriter writer, Document obj) {
    var map = <String, dynamic>{};
    for (var pair in obj) {
      map[pair.$1] = pair.$2;
    }
    writer.writeMap(map);
  }
}
