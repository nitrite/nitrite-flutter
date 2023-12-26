import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/filters/filter.dart';
import 'package:nitrite/src/repository/cursor.dart';
import 'package:nitrite/src/repository/entity_decorator.dart';
import 'package:nitrite/src/repository/nitrite_entity_reader.dart';

/// @nodoc
class RepositoryOperations<T> {
  final NitriteConfig _nitriteConfig;
  final NitriteMapper _nitriteMapper;
  final NitriteCollection _nitriteCollection;
  final EntityDecorator<T>? _entityDecorator;

  EntityId? _objectIdField;
  EntityDecoratorReader<T>? _entityDecoratorReader;
  NitriteEntityReader<T>? _nitriteEntityReader;

  RepositoryOperations(
      this._entityDecorator, this._nitriteCollection, this._nitriteConfig)
      : _nitriteMapper = _nitriteConfig.nitriteMapper {
    if (_entityDecorator != null) {
      _entityDecoratorReader =
          EntityDecoratorReader<T>(_entityDecorator, _nitriteCollection);
    } else {
      _nitriteEntityReader =
          NitriteEntityReader<T>(_nitriteMapper, _nitriteCollection);
    }
  }

  Future<void> createIndices() async {
    if (_entityDecoratorReader != null) {
      await _entityDecoratorReader!.readAndExecute();
      _objectIdField = _entityDecoratorReader!.objectIdField;
    } else if (isSubtype<T, NitriteEntity>()) {
      await _nitriteEntityReader!.readAndExecute();
      _objectIdField = _nitriteEntityReader!.objectIdField;
    }
  }

  void serializeFields(Document document) {
    for (var pair in document) {
      var key = pair.$1;
      var value = pair.$2;
      document.put(key, serialize(value));
    }
  }

  dynamic serialize(dynamic value) {
    dynamic serializedValue;
    if (value is Document) return value;

    if (value is List) {
      serializedValue = serializeList(value);
    } else if (value is Set) {
      serializedValue = serializeSet(value);
    } else if (value is Iterable) {
      serializedValue = serializeList(value.toList());
    } else if (value is Map) {
      serializedValue = serializeMap(value);
    } else {
      serializedValue = _nitriteMapper.tryConvert<Document, dynamic>(value);
    }
    return serializedValue;
  }

  List<dynamic> serializeList(List<dynamic> value) {
    var newList = [];
    for (var item in value) {
      newList.add(serialize(item));
    }
    return newList;
  }

  Set<dynamic> serializeSet(Set<dynamic> value) {
    var newSet = <dynamic>{};
    for (var item in value) {
      newSet.add(serialize(item));
    }
    return newSet;
  }

  Map serializeMap(Map value) {
    var newMap = <dynamic, dynamic>{};
    for (var entry in value.entries) {
      newMap[serialize(entry.key)] = serialize(entry.value);
    }
    return newMap;
  }

  List<Document> toDocuments(List<T> elements) {
    if (elements.isEmpty) return [];
    var documents = <Document>[];
    for (var element in elements) {
      var document = toDocument(element, false);
      documents.add(document);
    }
    return documents;
  }

  Document toDocument(T element, bool update) {
    var document = _nitriteMapper.tryConvert<Document, T>(element);
    if (document == null) {
      throw ObjectMappingException('Failed to map object to document');
    }

    if (_objectIdField != null) {
      var idFieldValue = document[_objectIdField!.fieldName];

      if (_objectIdField!.isNitriteId) {
        if (idFieldValue == null) {
          var nitriteId = document.id;
          document[_objectIdField!.fieldName] = nitriteId;
        } else if (!update) {
          // if it is an insert, then we should not allow to insert the
          // document with user provided id
          throw InvalidIdException(
              "Auto generated id should not be set manually");
        }
      }

      var idValue = document.get(_objectIdField!.fieldName);
      if (idValue == null) {
        throw InvalidIdException('Id cannot be null');
      }

      if (idValue is String && idValue.isEmpty) {
        throw InvalidIdException('Id value cannot be empty string');
      }
    }

    return document;
  }

  Filter createUniqueFilter(T element) {
    if (_objectIdField == null) {
      throw NotIdentifiableException('No id value found for the object');
    }

    var document = _nitriteMapper.tryConvert<Document, T>(element);
    if (document == null) {
      throw ObjectMappingException('Failed to map object to document');
    }

    var idValue = document[_objectIdField!.fieldName];

    return _objectIdField!.createUniqueFilter(idValue, _nitriteMapper);
  }

  void removeNitriteId(Document document) {
    document.remove(docId);
    if (_objectIdField != null &&
        !_objectIdField!.isEmbedded &&
        _objectIdField!.isNitriteId) {
      document.remove(_objectIdField!.fieldName);
    }
  }

  Filter createIdFilter<I>(I id) {
    if (_objectIdField == null) {
      throw NotIdentifiableException(
          '${T.runtimeType} does not have any id field');
    }

    if (id == null) {
      throw InvalidIdException('Id cannot be null');
    }

    return _objectIdField!.createUniqueFilter(id, _nitriteMapper);
  }

  Filter asObjectFilter(Filter filter) {
    if (filter is NitriteFilter) {
      filter.objectFilter = true;
      filter.nitriteConfig = _nitriteConfig;

      if (filter is FieldBasedFilter) {
        return _createObjectFilter(filter);
      }
    }
    return filter;
  }

  Cursor<T> find(Filter? filter, FindOptions? findOptions) {
    filter ??= all;
    var documentCursor = _nitriteCollection.find(
        filter: asObjectFilter(filter), findOptions: findOptions);
    return ObjectCursor<T>(documentCursor, _nitriteMapper);
  }

  Filter _createObjectFilter(FieldBasedFilter filter) {
    if (_objectIdField != null && _objectIdField!.fieldName == filter.field) {
      if (filter is EqualsFilter) {
        return _objectIdField!.createUniqueFilter(filter.value, _nitriteMapper);
      } else if (filter is ComparableFilter) {
        var fieldValue = filter.value;
        var converted =
            _nitriteMapper.tryConvert<Document, dynamic>(fieldValue);
        if (converted is Document) {
          throw InvalidOperationException('Cannot compare object of type '
              '${fieldValue.runtimeType} with id field');
        }
      }
    }
    return filter;
  }
}
