import 'package:nitrite/src/common/util/object_utils.dart';

class DBValue implements Comparable<DBValue> {
  final Comparable? _value;

  DBValue(this._value);

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
}

class DBNull extends DBValue {
  static final DBNull _instance = DBNull._();

  DBNull._(): super(null);

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
}
