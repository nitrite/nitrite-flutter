import 'package:nitrite/nitrite.dart';

/// Represents options to configure update operation.
class UpdateOptions {
  /// Indicates if the update operation will insert a new document if it
  /// does not find any existing document to update.
  bool insertIfAbsent;

  /// Indicates if only one document will be updated or all of them.
  bool justOnce;

  /// Creates a new instance of [UpdateOptions].
  UpdateOptions({this.insertIfAbsent = false, this.justOnce = false});
}

/// Creates a new instance of [UpdateOptions] with [insertIfAbsent] and
/// [justOnce] set to false.
UpdateOptions updateOptions({insertIfAbsent = false, justOnce = false}) =>
    UpdateOptions(insertIfAbsent: insertIfAbsent, justOnce: justOnce);

/// Creates a new instance of [FindOptions] with sorting order set to
/// [fieldName] and [sortOrder].
FindOptions orderBy(String fieldName,
    [SortOrder sortOrder = SortOrder.ascending]) {
  var sortableFields = SortableFields();
  sortableFields.addSortedField(fieldName, sortOrder);

  var findOptions = FindOptions();
  findOptions.orderBy = sortableFields;
  return findOptions;
}

/// Creates a new instance of [FindOptions] with skip set to [skip].
FindOptions skipBy(int skip) {
  var findOptions = FindOptions();
  findOptions.skip = skip;
  return findOptions;
}

/// Creates a new instance of [FindOptions] with limit set to [limit].
FindOptions limitBy(int limit) {
  var findOptions = FindOptions();
  findOptions.limit = limit;
  return findOptions;
}

/// Creates a new instance of [FindOptions] with distinct flag set to true.
FindOptions distinct() {
  var findOptions = FindOptions();
  findOptions.distinct = true;
  return findOptions;
}

/// The options for find operation.
class FindOptions {
  /// Gets the [SortableFields] for sorting the find results.
  SortableFields? orderBy;

  /// Gets the skip count.
  int? skip;

  /// Gets the limit count.
  int? limit;

  /// Indicates if the find operation should return distinct results.
  bool distinct = false;

  /// Creates a new instance of [FindOptions].
  FindOptions({this.orderBy, this.skip, this.limit});

  /// Set the skip count.
  FindOptions setSkip(int value) {
    skip = value;
    return this;
  }

  /// Set the limit count.
  FindOptions setLimit(int value) {
    limit = value;
    return this;
  }

  /// Set the sorting order for the find results.
  FindOptions thenOrderBy(String fieldName, SortOrder sortOrder) {
    if (orderBy != null) {
      orderBy!.addSortedField(fieldName, sortOrder);
    } else {
      var sortableFields = SortableFields();
      sortableFields.addSortedField(fieldName, sortOrder);
      orderBy = sortableFields;
    }

    return this;
  }

  /// Set the flag if the find operation should return distinct results.
  FindOptions withDistinct(bool value) {
    distinct = value;
    return this;
  }
}
