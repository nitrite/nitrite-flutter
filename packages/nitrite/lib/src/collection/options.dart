import 'package:nitrite/nitrite.dart';

class UpdateOptions {
  bool insertIfAbsent;
  bool justOnce;

  UpdateOptions({this.insertIfAbsent = false, this.justOnce = false});
}

UpdateOptions updateOptions({insertIfAbsent = false, justOnce = false}) =>
    UpdateOptions(insertIfAbsent: insertIfAbsent, justOnce: justOnce);

FindOptions orderBy(String fieldName,
    [SortOrder sortOrder = SortOrder.ascending]) {
  var sortableFields = SortableFields();
  sortableFields.addSortedField(fieldName, sortOrder);

  var findOptions = FindOptions();
  findOptions.orderBy = sortableFields;
  return findOptions;
}

FindOptions skipBy(int skip) {
  var findOptions = FindOptions();
  findOptions.skip = skip;
  return findOptions;
}

FindOptions limitBy(int limit) {
  var findOptions = FindOptions();
  findOptions.limit = limit;
  return findOptions;
}

FindOptions distinct() {
  var findOptions = FindOptions();
  findOptions.distinct = true;
  return findOptions;
}

/// The options for find operation.
class FindOptions {
  SortableFields? orderBy;
  int? skip;
  int? limit;
  bool distinct = false;

  FindOptions({this.orderBy, this.skip, this.limit});

  FindOptions setSkip(int value) {
    skip = value;
    return this;
  }

  FindOptions setLimit(int value) {
    limit = value;
    return this;
  }

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

  FindOptions withDistinct(bool value) {
    distinct = value;
    return this;
  }
}
