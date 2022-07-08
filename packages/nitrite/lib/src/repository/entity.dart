import 'package:nitrite/nitrite.dart';

class Id {
  final String _fieldName;
  final List<String> _fields;

  const Id(this._fieldName, [this._fields = const []]);

  String get fieldName => _fieldName;

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
      for (var field in embeddedFieldNames) {
        var docFieldName = _embeddedFieldName(field);
        var fieldValue = document[docFieldName];
        filters.add(where(field).eq(fieldValue));
      }

      var nitriteFilter = and(filters) as NitriteFilter;
      nitriteFilter.objectFilter = true;
      return nitriteFilter;
    } else {
      return where(_fieldName).eq(value);
    }
  }

  String _embeddedFieldName(String fieldName) {
    if (fieldName.contains(NitriteConfig.fieldSeparator)) {
      return fieldName
          .substring(fieldName.indexOf(NitriteConfig.fieldSeparator) + 1);
    } else {
      return fieldName;
    }
  }
}

class Index {
  final List<String> _fields;
  final String _type;

  const Index(this._fields, [this._type = "unique"]);

  List<String> get fieldNames => _fields;

  String get indexType => _type;
}

abstract class Entity {
  String? get entityName => null;
  List<Index>? get indexes => null;
  Id? get id => null;
}

abstract class MappableEntity extends Entity implements Mappable {}
