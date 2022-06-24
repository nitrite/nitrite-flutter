import 'dart:math';

import 'package:nitrite/nitrite.dart';
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
  String get encodedName => _fieldNames.join(internalNameSeparator);

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

/// Represents a list of document field with
/// sorting direction for find query.
class SortableFields extends Fields {
  final List<Pair<String, SortOrder>> _sortingOrders = [];

  SortableFields();

  /// Creates a [SortableFields] instance with field names.
  factory SortableFields.withNames(List<String> fields) {
    fields.notNullOrEmpty("fields cannot null or empty");

    var sortableFields = SortableFields();
    for (var field in fields) {
      sortableFields.addSortedField(field, SortOrder.ascending);
    }
    return sortableFields;
  }

  /// Adds the sort order for a field.
  SortableFields addSortedField(String fieldName, SortOrder sortOrder) {
    super.fieldNames.add(fieldName);
    _sortingOrders.add(Pair(fieldName, sortOrder));
    return this;
  }

  /// Gets the sort by field specifications.
  List<Pair<String, SortOrder>> get sortingOrders =>
      List.unmodifiable(_sortingOrders);
}

class FieldValues {
  final List<Pair<String, dynamic>> values = [];

  NitriteId? nitriteId;
  Fields? _fields;

  FieldValues();

  dynamic get(String field) {
    if (fields.fieldNames.contains(field)) {
      for (var value in values) {
        if (value.first == field) {
          return value.second;
        }
      }
    }
    return null;
  }

  Fields get fields {
    if (_fields != null) {
      return _fields!;
    }

    var fieldNames = <String>[];
    for (var value in values) {
      if (!value.first.isNullOrEmpty) {
        fieldNames.add(value.first);
      }
    }
    _fields = Fields.withNames(fieldNames);
    return _fields!;
  }

  set fields(Fields fields) {
    _fields = fields;
  }
}
