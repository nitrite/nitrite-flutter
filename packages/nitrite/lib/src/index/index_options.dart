
/// Creates an [IndexOptions] with the specified [indexType].
IndexOptions indexOptions(String indexType) => IndexOptions(indexType);

/// Represents options to apply while creating an index.
class IndexOptions {
  String indexType;

  IndexOptions(this.indexType);
}
