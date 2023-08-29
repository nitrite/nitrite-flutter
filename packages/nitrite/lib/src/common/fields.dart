import 'dart:math';

import 'package:collection/collection.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

/// Represents a collection of document field names and provides methods for
/// manipulating and comparing them.
class Fields implements Comparable<Fields> {
  List<String> _fieldNames = [];

  Fields();

  /// Creates a [Fields] instance with field names.
  factory Fields.withNames(List<String> fields) {
    fields.notNullOrEmpty('Fields cannot be empty');

    var f = Fields();
    f._fieldNames = fields;
    return f;
  }

  /// Gets the field names.
  List<String> get fieldNames => List.unmodifiable(_fieldNames);

  /// Gets the encoded name for this [Fields].
  String get encodedName => _fieldNames.join(internalNameSeparator);

  /// Adds a field name to a list of field names and returns the updated list.
  Fields addField(String fieldName) {
    fieldName.notNullOrEmpty('Field name cannot be empty');
    _fieldNames.add(fieldName);
    return this;
  }

  /// Check if a [Fields] is a subset of the current [Fields];
  bool startWith(Fields other) {
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fields &&
          runtimeType == other.runtimeType &&
          DeepCollectionEquality().equals(_fieldNames, other._fieldNames);

  @override
  int get hashCode => DeepCollectionEquality().hash(_fieldNames);
}

/// Represents a collection of fields that can be sorted, with each field
/// having a specified sort order.
class SortableFields extends Fields {
  final List<(String, SortOrder)> _sortingOrders = [];

  SortableFields();

  /// Creates a [SortableFields] instance with field names.
  factory SortableFields.withNames(List<String> fields) {
    fields.notNullOrEmpty("fields cannot be empty");

    var sortableFields = SortableFields();
    for (var field in fields) {
      sortableFields.addSortedField(field, SortOrder.ascending);
    }
    return sortableFields;
  }

  factory SortableFields.from(List<(String, SortOrder)> specs) {
    var sortableFields = SortableFields();
    for (var spec in specs) {
      sortableFields.addSortedField(spec.$1, spec.$2);
    }
    return sortableFields;
  }

  /// Adds the sort order for a field.
  SortableFields addSortedField(String fieldName, SortOrder sortOrder) {
    super._fieldNames.add(fieldName);
    _sortingOrders.add((fieldName, sortOrder));
    return this;
  }

  /// Gets the sort by field specifications.
  List<(String, SortOrder)> get sortingOrders =>
      List.unmodifiable(_sortingOrders);
}

/// Represents a collection of field-value pairs, with methods to retrieve
/// values by field name.
class FieldValues {
  final List<(String, dynamic)> values = [];

  NitriteId? nitriteId;
  Fields? _fields;

  /// Retrieves the value associated with a given field name.
  dynamic get(String field) {
    if (fields.fieldNames.contains(field)) {
      for (var value in values) {
        if (value.$1 == field) {
          return value.$2;
        }
      }
    }
    return null;
  }

  /// Returns the [Fields] object associated with this instance.
  Fields get fields {
    if (_fields != null) {
      return _fields!;
    }

    var fieldNames = <String>[];
    for (var value in values) {
      if (!value.$1.isNullOrEmpty) {
        fieldNames.add(value.$1);
      }
    }
    _fields = Fields.withNames(fieldNames);
    return _fields!;
  }

  /// Sets the [fields] property in the [FieldValues] class. 
  set fields(Fields fields) {
    _fields = fields;
  }
}
