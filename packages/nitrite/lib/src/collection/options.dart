import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/sort_order.dart';

class UpdateOptions {
  bool insertIfAbsent;
  bool justOnce;

  UpdateOptions({this.insertIfAbsent = false, this.justOnce = false});
}

UpdateOptions updateOptions({insertIfAbsent = false, justOnce = false}) =>
    UpdateOptions(insertIfAbsent: insertIfAbsent, justOnce: justOnce);

/// The options for find operation.
class FindOptions {
  SortableFields? _orderBy;
  int? _skip;
  int? _limit;

  FindOptions([this._orderBy, this._skip, this._limit]);

  /// Order by find options.
  factory FindOptions.orderBy(String fieldName, SortOrder sortOrder) {
    var sortableFields = SortableFields();
    sortableFields.addSortedField(fieldName, sortOrder);

    var findOptions = FindOptions();
    findOptions._orderBy = sortableFields;
    return findOptions;
  }

  factory FindOptions.skipBy(int skip) {
    var findOptions = FindOptions();
    findOptions._skip = skip;
    return findOptions;
  }

  factory FindOptions.limitBy(int limit) {
    var findOptions = FindOptions();
    findOptions._limit = limit;
    return findOptions;
  }

  SortableFields? get orderBy => _orderBy;
  int? get skip => _skip;
  int? get limit => _limit;

  FindOptions setSkip(int skip) {
    _skip = skip;
    return this;
  }

  FindOptions setLimit(int limit) {
    _limit = limit;
    return this;
  }

  FindOptions thenOrderBy(String fieldName, SortOrder sortOrder) {
    if (_orderBy != null) {
      _orderBy.addSortedField(fieldName, sortOrder);
    } else {
      var sortableFields = SortableFields();
      sortableFields.addSortedField(fieldName, sortOrder);
      _orderBy = sortableFields;
    }

    return this;
  }
}
