import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:nitrite/nitrite.dart';

/// Represents an entity id declaration.
class EntityId {
  final String _fieldName;
  final List<String> _fields;

  EntityId(this._fieldName, [this._fields = const []]);

  String get fieldName => _fieldName;

  List<String> get subFields => _fields;

  List<String> get embeddedFieldNames {
    return _fields
        .map((field) => "$_fieldName${NitriteConfig.fieldSeparator}$field")
        .toList();
  }

  bool get isEmbedded => _fields.isNotEmpty;

  Filter createUniqueFilter(dynamic value, NitriteMapper nitriteMapper) {
    if (isEmbedded) {
      var document = nitriteMapper.convert<Document, dynamic>(value);
      if (document == null) {
        throw ObjectMappingException('Failed to map object to document');
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

  @override
  operator ==(Object other) =>
      identical(this, other) ||
      other is EntityId &&
          runtimeType == other.runtimeType &&
          _fieldName == other._fieldName &&
          const ListEquality().equals(_fields, other._fields);

  @override
  int get hashCode => _fieldName.hashCode ^ _fields.hashCode;
}

/// Represents an entity index declaration.
class EntityIndex {
  final List<String> _fields;
  final String _type;

  const EntityIndex(this._fields, [this._type = "unique"]);

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
  int get hashCode => _fields.hashCode ^ _type.hashCode;
}

/// For internal use only
@internal
abstract class NitriteEntity {
  String? get entityName;
  List<EntityIndex>? get entityIndexes;
  EntityId? get entityId;
}
