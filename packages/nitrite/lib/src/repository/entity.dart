import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:nitrite/nitrite.dart';

/// Represents an entity id declaration.
class EntityId {
  final String _fieldName;
  final bool _isNitriteId;
  final List<String> _fields;

  EntityId(this._fieldName,
      [this._isNitriteId = false, this._fields = const []]);

  String get fieldName => _fieldName;

  bool get isNitriteId => _isNitriteId;

  List<String> get subFields => _fields;

  List<String> get embeddedFieldNames {
    return _fields
        .map((field) => "$_fieldName${NitriteConfig.fieldSeparator}$field")
        .toList();
  }

  bool get isEmbedded => _fields.isNotEmpty;

  Filter createUniqueFilter(dynamic value, NitriteMapper nitriteMapper) {
    if (isEmbedded) {
      var document = nitriteMapper.tryConvert<Document, dynamic>(value);
      if (document == null) {
        throw ObjectMappingException('Failed to map $value to document');
      }

      var filters = <Filter>[];
      for (var field in _fields) {
        var filterField = "$_fieldName${NitriteConfig.fieldSeparator}$field";
        var fieldValue = document[field];
        filters.add(where(filterField).eq(fieldValue));
      }

      var nitriteFilter = and(filters) as NitriteFilter;
      nitriteFilter.objectFilter = true;
      return nitriteFilter;
    } else {
      return where(_fieldName).eq(value);
    }
  }

  Filter createIdFilter(dynamic id, NitriteMapper nitriteMapper) {
    if (isEmbedded) {
      var document = nitriteMapper.tryConvert<Document, dynamic>(id);
      if (document == null) {
        throw ObjectMappingException('Failed to map embedded id to document');
      }

      var filters = <Filter>[];
      for (var field in _fields) {
        var filterField = "$_fieldName${NitriteConfig.fieldSeparator}$field";
        var fieldValue = document[field];
        filters.add(where(filterField).eq(fieldValue));
      }

      var nitriteFilter = and(filters) as NitriteFilter;
      nitriteFilter.objectFilter = true;
      return nitriteFilter;
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
          const ListEquality().equals(_fields, other._fields);

  @override
  int get hashCode =>
      _fieldName.hashCode ^
      _isNitriteId.hashCode ^
      ListEquality().hash(_fields);
}

/// Represents an entity index declaration.
class EntityIndex {
  final List<String> _fields;
  final String _type;

  const EntityIndex(this._fields, [this._type = IndexType.unique]);

  List<String> get fieldNames => _fields;

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

/// For internal use only
@internal
abstract class NitriteEntity {
  String? get entityName;
  List<EntityIndex>? get entityIndexes;
  EntityId? get entityId;
}
