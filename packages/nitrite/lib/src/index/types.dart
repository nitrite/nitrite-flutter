import 'package:nitrite/nitrite.dart';

/// Represents a bounding box for spatial indexing.
class BoundingBox {
  /// An empty bounding box.
  static final empty = BoundingBox(0, 0, 0, 0);

  /// Returns the minimum x-coordinate of the bounding box.
  final double minX;

  /// Returns the maximum x-coordinate of the bounding box.
  final double minY;

  /// Returns the minimum y-coordinate of the bounding box.
  final double maxX;

  /// Returns the maximum Y coordinate of the bounding box.
  final double maxY;

  /// Creates a new [BoundingBox] with the specified coordinates.
  BoundingBox(this.minX, this.minY, this.maxX, this.maxY);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundingBox &&
          runtimeType == other.runtimeType &&
          minX == other.minX &&
          minY == other.minY &&
          maxX == other.maxX &&
          maxY == other.maxY;

  @override
  int get hashCode =>
      minX.hashCode ^ minY.hashCode ^ maxX.hashCode ^ maxY.hashCode;

  @override
  String toString() {
    return 'BoundingBox{minX: $minX, minY: $minY, maxX: $maxX, maxY: $maxY}';
  }
}

/// Creates an [IndexOptions] with the specified [indexType].
IndexOptions indexOptions(String indexType) => IndexOptions(indexType);

/// Options for configuring an index.
class IndexOptions {
  /// Specifies the type of an index to create.
  String indexType;

  IndexOptions(this.indexType);
}

/// An interface representing the types of indexes supported by Nitrite.
interface class IndexType {
  /// Represents a unique index type.
  static const String unique = "Unique";

  /// Represents a non-unique index type.
  static const String nonUnique = "NonUnique";

  /// Represents a full text index type.
  static const String fullText = "Fulltext";
}

/// @nodoc
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

/// A class representing the descriptor of a Nitrite index.
class IndexDescriptor implements Comparable<IndexDescriptor> {
  final String _indexType;
  final Fields _indexFields;
  final String _collectionName;

  IndexDescriptor(this._indexType, this._indexFields, this._collectionName);

  /// Factory method to create an [IndexDescriptor] from a [Document].
  ///
  /// The [Document] should contain the following fields:
  ///
  /// - `indexFields`: The fields to index.
  /// - `indexType`: The type of index.
  /// - `collectionName`: Name of the collection.
  ///
  /// Throws a [NitriteException] if the [Document] is missing any of the required fields.
  factory IndexDescriptor.fromDocument(Document document) {
    if ('IndexDescriptor' == document[typeId]) {
      var indexType = document['indexType'] as String;
      var indexFields = Fields.withNames(document['indexFields']);
      var collectionName = document['collectionName'] as String;
      return IndexDescriptor(indexType, indexFields, collectionName);
    }
    throw NitriteException('document is not a valid IndexDescriptor');
  }

  /// Converts the [IndexDescriptor] object to a [Document] object.
  ///
  /// Returns a [Document] object representing the [IndexDescriptor] object.
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
