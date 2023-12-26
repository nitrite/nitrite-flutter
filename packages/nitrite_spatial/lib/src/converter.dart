import 'package:dart_jts/dart_jts.dart' hide Type;
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_spatial/nitrite_spatial.dart';

class GeometryConverter extends EntityConverter<Geometry> {
  @override
  Geometry fromDocument(Document document, NitriteMapper nitriteMapper) {
    var geometryString = document['geometry'] as String;
    return GeometrySerializer.deserialize(geometryString)!;
  }

  @override
  Document toDocument(Geometry entity, NitriteMapper nitriteMapper) {
    var document = emptyDocument();
    document.put('geometry', GeometrySerializer.serialize(entity));
    return document;
  }
}
