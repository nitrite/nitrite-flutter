import 'package:dart_jts/dart_jts.dart';
import 'package:nitrite/nitrite.dart';

const String _geometryId = 'geometry:';
var _writer = WKTWriter();
var _reader = WKTReader();

/// @nodoc
Geometry? geometryFromString(String geometryValue) {
  try {
    if (geometryValue.contains(_geometryId)) {
      var geometry = geometryValue.substring(_geometryId.length);
      return _reader.read(geometry);
    } else {
      throw NitriteIOException(
          'Not a valid WKT geometry string $geometryValue');
    }
  } catch (e) {
    if (e is! NitriteIOException) {
      throw NitriteIOException('Failed to parse WKT geometry string', cause: e);
    } else {
      rethrow;
    }
  }
}

/// @nodoc
String? geometryToString(Geometry? geometry) {
  if (geometry == null) {
    return null;
  }
  return '$_geometryId${_writer.write(geometry)}';
}

/// Serializes and deserializes [Geometry] objects to and from strings.
class GeometrySerializer {
  /// Deserializes a [Geometry] from a string.
  static Geometry? deserialize(String? geometryValue) {
    return geometryFromString(geometryValue ?? '');
  }

  /// Serializes a [Geometry] to a string.
  static String? serialize(Geometry? geometry) {
    return geometryToString(geometry);
  }
}

/// Compares two [Geometry] objects for equality.
bool geometryEquals(Geometry? geometry1, Geometry? geometry2) {
  if (geometry1 == null) {
    return geometry2 == null;
  }
  if (geometry2 == null) {
    return false;
  }
  return geometry1.equalsExactGeom(geometry2);
}
