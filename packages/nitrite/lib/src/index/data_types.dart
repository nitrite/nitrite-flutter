import 'package:nitrite/nitrite.dart';

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
  String indexType;

  IndexOptions(this.indexType);
}

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
}
