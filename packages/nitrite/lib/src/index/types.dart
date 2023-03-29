import 'package:nitrite/nitrite.dart';

/// Represents a bounding box for spatial indexing.
abstract class BoundingBox {
  double get minX;
  double get minY;
  double get maxX;
  double get maxY;
}

/// Creates an [IndexOptions] with the specified [indexType].
IndexOptions indexOptions(String indexType) => IndexOptions(indexType);

/// Represents options to apply while creating an index.
class IndexOptions {
  /// Specifies the type of an index to create.
  String indexType;

  IndexOptions(this.indexType);
}

/// Represents a type of nitrite index.
abstract class IndexType {
  static const String unique = "Unique";
  static const String nonUnique = "NonUnique";
  static const String fullText = "Fulltext";
}

/// Represents index metadata.
class IndexMeta {
  IndexDescriptor? indexDescriptor;
  String? indexMap;
  bool isDirty = false;

  IndexMeta();

  factory IndexMeta.fromDocument(Document document) {
    if ('IndexMeta' == document[typeId]) {
      var indexDescriptor =
          IndexDescriptor.fromDocument(document['indexDescriptor']);
      var indexMap = document['indexMap'];
      var isDirty = document['isDirty'];
      return IndexMeta()
        ..indexDescriptor = indexDescriptor
        ..indexMap = indexMap
        ..isDirty = isDirty;
    }
    throw NitriteException('document is not a valid IndexMeta');
  }

  Document toDocument() => createDocument(typeId, 'IndexMeta')
      .put('indexDescriptor', indexDescriptor?.toDocument())
      .put('indexMap', indexMap)
      .put('isDirty', isDirty);
}

/// Represents a nitrite database index.
class IndexDescriptor implements Comparable<IndexDescriptor> {
  final String _indexType;
  final Fields _indexFields;
  final String _collectionName;

  IndexDescriptor(this._indexType, this._indexFields, this._collectionName);

  factory IndexDescriptor.fromDocument(Document document) {
    if ('IndexDescriptor' == document[typeId]) {
      var indexType = document['indexType'] as String;
      var indexFields = Fields.withNames(document['indexFields']);
      var collectionName = document['collectionName'] as String;
      return IndexDescriptor(indexType, indexFields, collectionName);
    }
    throw NitriteException('document is not a valid IndexDescriptor');
  }

  Document toDocument() => createDocument(typeId, 'IndexDescriptor')
      .put('indexType', _indexType)
      .put('indexFields', _indexFields.fieldNames)
      .put('collectionName', _collectionName);

  /// Specifies the type of the index.
  String get indexType => _indexType;

  /// Gets the target fields for the index.
  Fields get fields => _indexFields;

  /// Gets the collection name.
  String get collectionName => _collectionName;

  @override
  int compareTo(IndexDescriptor other) {
    // compound index have the highest cardinality
    if (isCompoundIndex && !other.isCompoundIndex) return 1;

    // unique index has the next highest cardinality
    if (isUniqueIndex && !isUniqueIndex) return 1;

    // for two unique indices, the one with encompassing higher
    // number of fields has the higher cardinality
    if (isUniqueIndex) {
      return _indexFields.compareTo(other._indexFields);
    }

    // for two non-unique indices, the one with encompassing higher
    // number of fields has the higher cardinality
    if (!other.isUniqueIndex) {
      return _indexFields.compareTo(other._indexFields);
    }

    return -1;
  }

  /// Indicates if this descriptor is for a compound index.
  bool get isCompoundIndex {
    return _indexFields.fieldNames.length > 1;
  }

  /// Indicates if this descriptor is for a unique index.
  bool get isUniqueIndex {
    return _indexType == IndexType.unique;
  }
}
