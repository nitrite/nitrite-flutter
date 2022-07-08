import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/filters/filter.dart';

class FindOptimizer {
  FindPlan optimize(Filter filter, FindOptions? findOptions,
      Iterable<IndexDescriptor> indexDescriptors) {
    var findPlan = _createFilterPlan(indexDescriptors, filter);
    _readSortOption(findOptions, findPlan);
    _readLimitOption(findOptions, findPlan);

    if (findOptions != null) {
      findPlan.distinct = findOptions.distinct;
    }
    return findPlan;
  }

  FindPlan _createFilterPlan(
      Iterable<IndexDescriptor> indexDescriptors, Filter filter) {
    if (filter is AndFilter) {
      var filters = _flattenAndFilter(filter);
      return _createAndPlan(indexDescriptors, filters);
    } else if (filter is OrFilter) {
      return _createOrPlan(indexDescriptors, filter.filters);
    } else {
      var filters = [filter];
      return _createAndPlan(indexDescriptors, filters);
    }
  }

  List<Filter> _flattenAndFilter(AndFilter andFilter) {
    var flattenedFilters = <Filter>[];
    for (var filter in andFilter.filters) {
      if (filter is AndFilter) {
        flattenedFilters.addAll(_flattenAndFilter(filter));
      } else {
        flattenedFilters.add(filter);
      }
    }
    return flattenedFilters;
  }

  FindPlan _createOrPlan(
      Iterable<IndexDescriptor> indexDescriptors, List<Filter> filters) {
    var findPlan = FindPlan();
    var flattenedFilter = <Filter>{};

    // flatten the or filter
    for (var filter in filters) {
      if (filter is OrFilter) {
        flattenedFilter.addAll(filter.filters);
      } else {
        flattenedFilter.add(filter);
      }
    }

    for (var filter in flattenedFilter) {
      var subPLan = _createFilterPlan(indexDescriptors, filter);
      findPlan.subPlans.add(subPLan);
    }

    // check if all sub plan have index support
    for (var subPlan in findPlan.subPlans) {
      if (subPlan.indexDescriptor == null) {
        // if one of the sub plan doesn't have any index support
        // then it can not be optimized, instead the
        // original filter should be set as coll-scan filter
        // for the parent plan
        findPlan.subPlans.clear();
        // set the original or filter as coll scan filter
        findPlan.collectionScanFilter = or(filters);
        return findPlan;
      }
    }
    return findPlan;
  }

  FindPlan _createAndPlan(
      Iterable<IndexDescriptor> indexDescriptors, List<Filter> filters) {
    var findPlan = FindPlan();
    var indexScanFilters = <ComparableFilter>{};
    var columnScanFilters = <Filter>{};

    // find out set id filter (if any)
    _planForIdFilter(findPlan, filters);

    // find out if there are any index only filter with index
    _planForIndexOnlyFilters(
        findPlan, indexScanFilters, indexDescriptors, filters);

    // if no id filter found or no index only filter found,
    // scan for matching index
    if (findPlan.byIdFilter == null && indexScanFilters.isEmpty) {
      _planForIndexScanningFilters(
          findPlan, indexScanFilters, indexDescriptors, filters);
    }

    // plan for column scan filters
    _planForCollectionScanningFilters(
        findPlan, indexScanFilters, columnScanFilters, filters);

    IndexScanFilter? indexScanFilter;
    if (indexScanFilters.length == 1) {
      indexScanFilter = IndexScanFilter([indexScanFilters.first]);
      findPlan.indexScanFilter = indexScanFilter;
    } else if (indexScanFilters.length > 1) {
      indexScanFilter = IndexScanFilter(indexScanFilters);
    }

    if (columnScanFilters.length == 1) {
      findPlan.collectionScanFilter = columnScanFilters.first;
    } else if (columnScanFilters.length > 1) {
      findPlan.collectionScanFilter = and(columnScanFilters.toList());
    }

    return findPlan;
  }

  void _planForIdFilter(FindPlan findPlan, List<Filter> filters) {
    for (var filter in filters) {
      if (filter is EqualsFilter) {
        if (filter.field == docId) {
          // handle byId filter specially
          findPlan.byIdFilter = filter;
          break;
        }
      }
    }
  }

  void _planForIndexOnlyFilters(
      FindPlan findPlan,
      Set<ComparableFilter> indexScanFilters,
      Iterable<IndexDescriptor> indexDescriptors,
      List<Filter> filters) {
    // find out if there are any filter which does not support covered queries
    var indexOnlyFilters = <IndexOnlyFilter>[];
    for (var filter in filters) {
      if (filter is IndexOnlyFilter) {
        if (_isCompatibleFilter(indexOnlyFilters, filter)) {
          // if filter is compatible with already identified index only filter
          // then add
          indexOnlyFilters.add(filter);
        } else {
          throw FilterException(
              'A query can not have multiple index only filters');
        }
      }
    }

    // populate index descriptor for the index only filters
    if (indexOnlyFilters.isNotEmpty) {
      // get any index only filter from the set
      var anyFilter = indexOnlyFilters.first;

      for (var indexDescriptor in indexDescriptors) {
        // check the index type match between filter and index descriptor
        if (anyFilter.supportedIndexType() == indexDescriptor.indexType) {
          // choose the index descriptor and filters
          findPlan.indexDescriptor = indexDescriptor;
          indexScanFilters.addAll(indexOnlyFilters);
          break;
        }
      }

      if (findPlan.indexDescriptor == null) {
        throw FilterException('${anyFilter.field} is not indexed '
            'with ${anyFilter.supportedIndexType()} index');
      }
    }
  }

  bool _isCompatibleFilter(
      List<IndexOnlyFilter> indexOnlyFilters, IndexOnlyFilter filter) {
    if (indexOnlyFilters.isEmpty) {
      return true;
    } else {
      var comparableFilter = indexOnlyFilters.first;
      return comparableFilter.canBeGrouped(filter);
    }
  }

  void _planForIndexScanningFilters(
      FindPlan findPlan,
      Set<ComparableFilter> indexScanFilters,
      Iterable<IndexDescriptor> indexDescriptors,
      List<Filter> filters) {
    // descending sort based on cardinality of indices,
    // consider the higher cardinality index first
    var indexFilterMap = <IndexDescriptor, List<ComparableFilter>>{};

    for (var indexDescriptor in indexDescriptors) {
      var fieldNames = indexDescriptor.indexFields.fieldNames;
      var indexFilters = <ComparableFilter>[];
      for (var fieldName in fieldNames) {
        var matchFound = false;
        for (var filter in filters) {
          if (filter is ComparableFilter) {
            var filterFieldName = filter.field;
            if (filterFieldName == fieldName) {
              indexFilters.add(filter);
              matchFound = true;
              break;
            }
          }
        }

        if (!matchFound) {
          // match not found, so can't consider this index
          break;
        }
      }

      if (indexFilters.isNotEmpty) {
        indexFilterMap[indexDescriptor] = indexFilters;
      }
    }

    for (var entry in indexFilterMap.entries) {
      // consider the filter combination if it encompasses more fields
      // than the previously selected filter
      if (entry.value.length > indexScanFilters.length) {
        // maintain the order in set
        indexScanFilters.addAll(entry.value);
        findPlan.indexDescriptor = entry.key;
      }
    }
  }

  void _planForCollectionScanningFilters(
      FindPlan findPlan,
      Set<ComparableFilter> indexScanFilters,
      Set<Filter> columnScanFilters,
      List<Filter> filters) {
    for (var filter in filters) {
      // ignore the elected filters for index scan and
      // insert rest of the filters for column scan
      // NOTE: for byId filter, index scan filters will always be empty
      if (filter is! ComparableFilter || !indexScanFilters.contains(filter)) {
        // ignore the byId filter (if any) for column scan
        if (filter != findPlan.byIdFilter) {
          columnScanFilters.add(filter);
        }
      }
    }

    // validate whether column scanning is supported for each filter,
    // if there is no index scan available
    if (indexScanFilters.isEmpty) {
      _validateCollectionScanFilters(columnScanFilters);
    }
  }

  void _validateCollectionScanFilters(Iterable<Filter> filters) {
    for (var filter in filters) {
      if (filter is IndexOnlyFilter) {
        throw FilterException(
            'Collection scan is not supported for the filter $filter');
      } else if (filter is TextFilter) {
        throw FilterException('${filter.field} is not full-text indexed');
      }
    }
  }

  void _readSortOption(FindOptions? findOptions, FindPlan findPlan) {
    var indexDescriptor = findPlan.indexDescriptor;
    if (findOptions != null && findOptions.orderBy != null) {
      // get sort spec for find
      var findSortSpec = findOptions.orderBy!.sortingOrders;

      if (indexDescriptor != null) {
        // get index field names
        var indexedFieldNames = indexDescriptor.indexFields.fieldNames;

        var canUseIndex = false;
        var indexScanOrder = <String, bool>{};

        if (indexedFieldNames.length >= findSortSpec.length) {
          // if all fields of the sort spec is covered by index, then only
          // sorting can take help of index

          var length = findSortSpec.length;
          for (var i = 0; i < length; i++) {
            var indexFieldName = indexedFieldNames[i];
            var findPair = findSortSpec[i];
            if (indexFieldName != findPair.first) {
              // field mismatch in sort spec, can't use index for sorting
              canUseIndex = false;
              break;
            } else {
              canUseIndex = true;
              bool reverseScan = false;

              var findSortOrder = findPair.second;
              if (findSortOrder != SortOrder.ascending) {
                // if sort order is different, reverse scan in index
                reverseScan = true;
              }

              // add to index scan order
              indexScanOrder[indexFieldName] = reverseScan;
            }
          }
        }

        if (canUseIndex) {
          findPlan.indexScanOrder = indexScanOrder;
        } else {
          findPlan.blockingSortOrder = findSortSpec;
        }
      } else {
        // no find options, so consider the index sorting order
        findPlan.blockingSortOrder = findSortSpec;
      }
    }
  }

  void _readLimitOption(FindOptions? findOptions, FindPlan findPlan) {
    if (findOptions != null) {
      findPlan.limit = findOptions.limit;
      findPlan.skip = findOptions.skip;
    }
  }
}
