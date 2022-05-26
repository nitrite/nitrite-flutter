import 'dart:math';

import 'package:nitrite/src/common/constants.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

/// Represents a list of document fields.
class Fields implements Comparable<Fields> {
  List<String> _fieldNames = [];

  Fields();

  /// Creates a [Fields] instance with field names.
  factory Fields.withNames(List<String> fields) {
    fields.notNullOrEmpty('Fields cannot null or empty');

    var f = Fields();
    f._fieldNames = fields;
    return f;
  }

  /// Gets the field names.
  List<String> get fieldNames => List.unmodifiable(_fieldNames);

  /// Gets the encoded name for this [Fields].
  String get encodedName => _fieldNames.join(Constants.internalNameSeparator);

  /// Adds a new field name.
  Fields addField(String fieldName) {
    fieldName.notNullOrEmpty('Field name cannot null or empty');
    _fieldNames.add(fieldName);
    return this;
  }

  /// Check if a [Fields] is a subset of the current [Fields];
  bool startWith(Fields other) {
    other.notNullOrEmpty('Fields cannot null');

    var length = min(_fieldNames.length, other._fieldNames.length);

    // if other is greater then it is not a prefix of this field
    if (other.fieldNames.length > length) {
      return false;
    }

    for (var i = 0; i < length; i++) {
      if (other.fieldNames[i] != _fieldNames[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  toString() => _fieldNames.toString();

  @override
  int compareTo(Fields other) {
    var fieldSize = _fieldNames.length;
    var otherFieldSize = other._fieldNames.length;
    var result = fieldSize.compareTo(otherFieldSize);
    if (result == 0) {
      for (var i = 0; i < fieldSize; i++) {
        result = _fieldNames[i].compareTo(other._fieldNames[i]);
        if (result != 0) {
          return result;
        }
      }
    }
    return result;
  }

}