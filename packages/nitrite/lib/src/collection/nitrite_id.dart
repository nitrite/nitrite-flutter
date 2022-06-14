import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/snowflake_id.dart';
import 'package:nitrite/src/common/constants.dart';

class NitriteId implements Comparable<NitriteId> {
  static final SnowflakeIdGenerator _generator = SnowflakeIdGenerator();

  String _idValue = "";

  String get idValue => _idValue;

  NitriteId._();

  static NitriteId newId() {
    var nitriteId = NitriteId._();
    var id = _generator.id;
    nitriteId._idValue = id.toString();
    return nitriteId;
  }

  static NitriteId createId(String value) {
    validId(value);
    var nitriteId = NitriteId._();
    nitriteId._idValue = value;
    return nitriteId;
  }

  static bool validId(dynamic value) {
    if (value == null) {
      throw InvalidIdException("id cannot be null");
    }

    try {
      int.parse(value.toString());
      return true;
    } on FormatException {
      throw InvalidIdException("id must be a string representation "
          "of 64bit integer number $value");
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
