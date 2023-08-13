import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/filters/filter.dart';

/// A plan for finding documents in a collection.
class FindPlan {
  /// Gets the [FieldBasedFilter] for byId search if any.
  FieldBasedFilter? byIdFilter;

  /// Gets the [IndexScanFilter] for index scan if any.
  IndexScanFilter? indexScanFilter;

  /// Gets the [Filter] for collection scan if any.
  Filter? collectionScanFilter;

  /// Gets the [IndexDescriptor] for index scan if any.
  IndexDescriptor? indexDescriptor;

  /// Gets the index scan order.
  Map<String, bool> indexScanOrder = {};

  /// Gets the blocking sort order.
  List<(String, SortOrder)> blockingSortOrder = [];

  /// Gets the skip count.
  int? skip;

  /// Gets the limit count.
  int? limit;

  /// Gets the distinct flag.
  bool distinct = false;

  /// Gets the sub plans.
  List<FindPlan> subPlans = [];
}
