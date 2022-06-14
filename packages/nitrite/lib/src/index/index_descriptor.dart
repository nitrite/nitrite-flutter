import 'package:nitrite/nitrite.dart';

/// Represents a nitrite database index.
class IndexDescriptor implements Comparable<IndexDescriptor> {
  final String _indexType;
  final Fields _indexFields;
  final String _collectionName;

  IndexDescriptor(this._indexType, this._indexFields, this._collectionName);

  /// Specifies the type of the index.
  String get indexType => _indexType;

  /// Gets the target fields for the index.
  Fields get indexFields => _indexFields;

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
