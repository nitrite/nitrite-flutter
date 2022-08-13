import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/repository/cursor.dart';
import 'package:nitrite/src/repository/entity.dart';

class RepositoryOperations<T> {
  final NitriteMapper _nitriteMapper;
  final NitriteCollection _nitriteCollection;

  EntityId? _objectIdField;
  List<EntityIndex>? _indexes;

  RepositoryOperations(this._nitriteMapper, this._nitriteCollection);

  Future<void> createIndices() async {
    if (isSubtype<T, NitriteEntity>()) {
      NitriteEntity dummy = _nitriteMapper.newInstance<T>() as NitriteEntity;
      if (dummy.entityId != null) {
        _objectIdField = dummy.entityId;
        var hasIndex = await _nitriteCollection
            .hasIndex(_objectIdField!.embeddedFieldNames);
        if (!hasIndex) {
          await _nitriteCollection
              .createIndex(_objectIdField!.embeddedFieldNames);
        }
      }

      if (dummy.entityIndexes != null) {
        _indexes = dummy.entityIndexes;

        var futures = <Future<void>>[];
        for (var index in _indexes!) {
          var hasIndex = await _nitriteCollection.hasIndex(index.fieldNames);
          if (!hasIndex) {
            futures.add(_nitriteCollection.createIndex(
                index.fieldNames, indexOptions(index.indexType)));
          }
        }
        await Future.wait(futures);
      }
    } else if (isSubtype<T, Mappable>()) {
      // to test if a MappableFactory has been registered for this type
      // if no registered factory found, it will throw an exception
      _nitriteMapper.newInstance<T>() as Mappable;
    }
  }

  void serializeFields(Document document) {
    for (var pair in document) {
      var key = pair.first;
      var value = pair.second;
      var serializedValue = _nitriteMapper.convert<Document, dynamic>(value);
      document.put(key, serializedValue);
    }
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
      serializeFields(document);
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

    return _objectIdField!.createUniqueFilter(id, _nitriteMapper);
  }

  Filter asObjectFilter(Filter filter) {
    if (filter is NitriteFilter) {
      filter.objectFilter = true;
    }
    return filter;
  }

  Future<Cursor<T>> find(Filter? filter, FindOptions? findOptions) async {
    filter ??= all;
    var documentCursor =
        await _nitriteCollection.find(asObjectFilter(filter), findOptions);
    return ObjectCursor<T>(documentCursor, _nitriteMapper);
  }
}
