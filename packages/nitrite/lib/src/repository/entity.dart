import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:nitrite/nitrite.dart';

/// Represents the unique identifier for an entity in an [ObjectRepository].
///
/// An entity ID consists of a field name and optional sub-fields.
/// If sub-fields are present, the ID is considered to be embedded.
class EntityId {
  final String _fieldName;
  final bool _isNitriteId;
  final List<String> _embeddedFields;

  EntityId(this._fieldName,
      [this._isNitriteId = false, this._embeddedFields = const []]);

  /// Returns the name of the id field.
  String get fieldName => _fieldName;

  /// Returns true if the entity ID is a [NitriteId].
  bool get isNitriteId => _isNitriteId;

  /// Returns a list of embedded fields of the id field.
  List<String> get embeddedFields => _embeddedFields;

  /// Returns a list of encoded field names.
  List<String> get encodedFieldNames {
    return _embeddedFields
        .map((field) => "$_fieldName${NitriteConfig.fieldSeparator}$field")
        .toList();
  }

  /// Checks if the entity id is embedded.
  bool get isEmbedded => _embeddedFields.isNotEmpty;

  /// @nodoc
  Filter createUniqueFilter(dynamic value, NitriteMapper nitriteMapper) {
    if (isEmbedded) {
      var document = nitriteMapper.tryConvert<Document, dynamic>(value);
      if (document == null) {
        throw ObjectMappingException('Failed to map $value to document');
      }

      var filters = <Filter>[];
      if (_embeddedFields.length == 1 && document is! Document) {
        // in case of single embedded field, the value is directly passed
        // as the value of the field
        var filterField =
            "$_fieldName${NitriteConfig.fieldSeparator}${_embeddedFields[0]}";

        var nitriteFilter = where(filterField).eq(document);
        nitriteFilter.objectFilter = true;
        return nitriteFilter;
      } else {
        for (var field in _embeddedFields) {
          var filterField = "$_fieldName${NitriteConfig.fieldSeparator}$field";
          var fieldValue = document[field];
          filters.add(where(filterField).eq(fieldValue));
        }

        var nitriteFilter = and(filters) as NitriteFilter;
        nitriteFilter.objectFilter = true;
        return nitriteFilter;
      }
    } else {
      return where(_fieldName).eq(value);
    }
  }

  /// @nodoc
  Filter createIdFilter(dynamic id, NitriteMapper nitriteMapper) {
    if (isEmbedded) {
      var document = nitriteMapper.tryConvert<Document, dynamic>(id);
      if (document == null) {
        throw ObjectMappingException('Failed to map embedded id to document');
      }

      var filters = <Filter>[];
      if (_embeddedFields.length == 1 && document is! Document) {
        // in case of single embedded field, the value is directly passed
        // as the value of the field
        var filterField =
            "$_fieldName${NitriteConfig.fieldSeparator}${_embeddedFields[0]}";

        var nitriteFilter = where(filterField).eq(document);
        nitriteFilter.objectFilter = true;
        return nitriteFilter;
      } else {
        for (var field in _embeddedFields) {
          var filterField = "$_fieldName${NitriteConfig.fieldSeparator}$field";
          var fieldValue = document[field];
          filters.add(where(filterField).eq(fieldValue));
        }

        var nitriteFilter = and(filters) as NitriteFilter;
        nitriteFilter.objectFilter = true;
        return nitriteFilter;
      }
    } else {
      if (isNitriteId) {
        return where(docId).eq(id.idValue);
      } else {
        return where(_fieldName).eq(id);
      }
    }
  }

  @override
  operator ==(Object other) =>
      identical(this, other) ||
      other is EntityId &&
          runtimeType == other.runtimeType &&
          _fieldName == other._fieldName &&
          _isNitriteId == other._isNitriteId &&
          const ListEquality().equals(_embeddedFields, other._embeddedFields);

  @override
  int get hashCode =>
      _fieldName.hashCode ^
      _isNitriteId.hashCode ^
      ListEquality().hash(_embeddedFields);
}

/// Represents an index for an entity in the Nitrite database.
class EntityIndex {
  final List<String> _fields;
  final String _type;

  const EntityIndex(this._fields, [this._type = IndexType.unique]);

  /// The list of field names on which index is created.
  List<String> get fieldNames => _fields;

  /// The type of index to be used for the entity field.
  String get indexType => _type;

  @override
  operator ==(Object other) =>
      identical(this, other) ||
      other is EntityIndex &&
          runtimeType == other.runtimeType &&
          ListEquality().equals(_fields, other._fields) &&
          _type == other._type;

  @override
  int get hashCode => ListEquality().hash(_fields) ^ _type.hashCode;

  @override
  String toString() {
    return "EntityIndex(_fields = $_fields, _type = $_type)";
  }
}

@internal

/// Represents an entity in the Nitrite database with metadata.
abstract class NitriteEntity {
  /// Gets the name of the entity.
  String? get entityName;

  /// Gets the list of indexes for the entity.
  List<EntityIndex>? get entityIndexes;

  /// Gets the id field for the entity.
  EntityId? get entityId;
}
