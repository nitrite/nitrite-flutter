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

  /// Gets the index whose keys can supply [blockingSortOrder] without reading
  /// any document.
  ///
  /// This is a hint, not a decision: the reader still has to confirm that the
  /// index holds exactly one entry per stored document (a multi-valued field
  /// breaks that) and falls back to the blocking sort when it does not. When
  /// the hint holds, only the documents actually returned are fetched, instead
  /// of every document in the collection.
  IndexDescriptor? sortIndexDescriptor;

  /// Gets the skip count.
  int? skip;

  /// Gets the limit count.
  int? limit;

  /// Gets the sub plans.
  List<FindPlan> subPlans = [];
}
