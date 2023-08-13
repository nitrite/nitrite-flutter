/// Represents lookup parameters in join operation of two collections.
class LookUp {
  /// Specifies the field from the records input to the join.
  String localField;

  /// Specifies the field from the foreign records.
  String foreignField;

  /// Specifies the new field of the joined records.
  String targetField;

  LookUp(this.localField, this.foreignField, this.targetField);
}

/// An enum to specify a sort order.
enum SortOrder {
  /// Ascending sort order.
  ascending,

  /// Descending sort order.
  descending,
}
