import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/repository/cursor.dart';
import 'package:nitrite/src/repository/entity_decorator.dart';
import 'package:nitrite/src/repository/nitrite_entity_reader.dart';

class RepositoryOperations<T> {
  final NitriteMapper _nitriteMapper;
  final NitriteCollection _nitriteCollection;
  final EntityDecorator<T>? _entityDecorator;

  EntityId? _objectIdField;
  EntityDecoratorReader<T>? _entityDecoratorReader;
  NitriteEntityReader<T>? _nitriteEntityReader;

  RepositoryOperations(
      this._entityDecorator, this._nitriteMapper, this._nitriteCollection) {
    if (_entityDecorator != null) {
      _entityDecoratorReader =
          EntityDecoratorReader<T>(_entityDecorator!, _nitriteCollection);
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
      var key = pair.first;
      var value = pair.second;
      document.put(key, serialize(value));
    }
  }

  dynamic serialize(dynamic value) {
    dynamic serializedValue;
    if (value is List) {
      serializedValue = serializeList(value);
    } else if (value is Set) {
      serializedValue = serializeSet(value);
    } else if (value is Iterable) {
      serializedValue = serializeList(value.toList());
    } else if (value is Map) {
      serializedValue = serializeMap(value);
    } else {
      serializedValue = _nitriteMapper.convert<Document, dynamic>(value);
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

  Document toDocument(T element, bool bool) {
    var document = _nitriteMapper.convert<Document, T>(element);
    if (document != null) {
      // serializeFields(document);
    } else {
      throw ObjectMappingException('Failed to map object to document');
    }

    if (_objectIdField != null) {
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

    return _objectIdField!.createUniqueFilter(element, _nitriteMapper);
  }

  void removeNitriteId(Document document) {
    document.remove(docId);
    if (_objectIdField != null && !_objectIdField!.isEmbedded) {
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

    return _objectIdField!.createIdFilter(id, _nitriteMapper);
  }

  Filter asObjectFilter(Filter filter) {
    if (filter is NitriteFilter) {
      filter.objectFilter = true;
    }
    return filter;
  }

  Future<Cursor<T>> find(Filter? filter, FindOptions? findOptions) async {
    filter ??= all;
    var documentCursor = await _nitriteCollection.find(
        filter: asObjectFilter(filter), findOptions: findOptions);
    return ObjectCursor<T>(documentCursor, _nitriteMapper);
  }
}
