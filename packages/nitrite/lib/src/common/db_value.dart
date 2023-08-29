import 'package:nitrite/src/common/util/object_utils.dart';

/// @nodoc
class DBValue implements Comparable<DBValue> {
  final Comparable? _value;

  DBValue(this._value);

  Comparable? get value => _value;

  @override
  int compareTo(DBValue? other) {
    if (other == null || other._value == null) {
      return 1;
    }

    if (_value == null) {
      return -1;
    }

    return compare(_value!, other._value!);
  }

  @override
  toString() => _value == null ? "null" : _value.toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DBValue &&
          runtimeType == other.runtimeType &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;
}

/// @nodoc
class DBNull extends DBValue {
  static final DBNull _instance = DBNull._();

  DBNull._() : super(null);

  static DBNull get instance => _instance;

  @override
  int compareTo(DBValue? other) {
    if (other == null || other is DBNull) {
      return 0;
    }

    // null value always comes first
    return -1;
  }

  @override
  String toString() => "null";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DBNull && runtimeType == other.runtimeType;

  @override
  int get hashCode => _value.hashCode;
}

/// @nodoc
class UnknownType implements Comparable<UnknownType> {
  @override
  int compareTo(UnknownType other) {
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnknownType && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;
}
