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

/// An enum is used to specify the sort order for sorting operations.
/// 
enum SortOrder {
  /// Represents the ascending sort order.
  ascending,

  /// Represents the descending sort order.
  descending,
}
