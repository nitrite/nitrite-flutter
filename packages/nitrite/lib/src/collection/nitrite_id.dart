import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/snowflake_id.dart';

/// A unique identifier across the Nitrite database. Each document in a
/// collection is associated with a unique [NitriteId].
///
/// During insertion if a unique object is supplied in the '_id' field
/// of the document, then the value of the '_id' field will be used to
/// create a new [NitriteId]. If the '_id' field is not supplied, then
/// nitrite will generate a new [NitriteId] and will add it to the
/// document.
class NitriteId implements Comparable<NitriteId> {
  static final SnowflakeIdGenerator _generator = SnowflakeIdGenerator();

  String _idValue = "";

  /// Gets the underlying value of the [NitriteId].
  ///
  /// The value is a string representation of a 64bit integer number.
  String get idValue => _idValue;

  NitriteId._();

  /// Creates a new auto-generated [NitriteId].
  static NitriteId newId() {
    var nitriteId = NitriteId._();
    var id = _generator.id;
    nitriteId._idValue = id.toString();
    return nitriteId;
  }

  /// Creates a new [NitriteId] from a value.
  ///
  /// The value must be a string representation of a 64bit integer number.
  static NitriteId createId(String value) {
    validId(value);
    var nitriteId = NitriteId._();
    nitriteId._idValue = value;
    return nitriteId;
  }

  /// Validates a value to be used as a [NitriteId].
  ///
  /// The value must be a string representation of a 64bit integer number.
  static bool validId(dynamic value) {
    if (value == null) {
      throw InvalidIdException("id cannot be null");
    }

    try {
      int.parse(value.toString());
      return true;
    } on FormatException catch (e, stackTrace) {
      throw InvalidIdException(
          "Id must be a string representation "
          "of 64bit integer number $value",
          stackTrace: stackTrace,
          cause: e);
    }
  }

  @override
  int compareTo(NitriteId other) =>
      int.parse(_idValue).compareTo(int.parse(other._idValue));

  @override
  String toString() => idPrefix + _idValue + idSuffix;

  @override
  bool operator ==(dynamic other) =>
      other is NitriteId && other._idValue == _idValue;

  @override
  int get hashCode => _idValue.hashCode;
}
