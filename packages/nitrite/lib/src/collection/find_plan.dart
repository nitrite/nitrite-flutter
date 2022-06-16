import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/filters/filter.dart';

class FindPlan {
  FieldBasedFilter? byIdFilter;
  IndexScanFilter? indexScanFilter;
  Filter? collectionScanFilter;
  IndexDescriptor? indexDescriptor;
  int? skip;
  int? limit;
  bool distinct = false;

  Map<String, bool> indexScanOrder = {};
  List<Pair<String, SortOrder>> blockingSortOrder = [];
  List<FindPlan> subPlans = [];
}
