import 'package:nitrite/nitrite.dart';
import 'package:nitrite_support/src/exchange/convert/binary_reader.dart';
import 'package:nitrite_support/src/exchange/convert/binary_writer.dart';
import 'package:nitrite_support/src/exchange/convert/converter.dart';

/// @nodoc
class DateTimeConverter extends Converter<DateTime> {
  @override
  DateTime decode(BinaryReader reader) {
    return DateTime.parse(reader.readString());
  }

  @override
  void encode(DateTime value, BinaryWriter writer) {
    writer.writeString(value.toIso8601String());
  }

  @override
  int get typeId => 12;
}

/// @nodoc
class NitriteIdConverter extends Converter<NitriteId> {
  @override
  NitriteId decode(BinaryReader reader) {
    return NitriteId.createId(reader.readString());
  }

  @override
  void encode(NitriteId value, BinaryWriter writer) {
    writer.writeString(value.idValue);
  }

  @override
  int get typeId => 13;
}

/// @nodoc
class DocumentConverter extends Converter<Document> {
  @override
  Document decode(BinaryReader reader) {
    var map = reader.readMap();
    var documentMap = Map<String, dynamic>.from(map);
    return documentFromMap(documentMap);
  }

  @override
  void encode(Document value, BinaryWriter writer) {
    writer.writeMap(value.toMap());
  }

  @override
  int get typeId => 14;
}
