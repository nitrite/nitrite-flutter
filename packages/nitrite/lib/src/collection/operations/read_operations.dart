import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/document_cursor.dart';
import 'package:nitrite/src/collection/operations/find_optimizer.dart';
import 'package:nitrite/src/collection/operations/index_operations.dart';
import 'package:nitrite/src/common/processors/processor.dart';
import 'package:nitrite/src/common/stream/filtered_stream.dart';
import 'package:nitrite/src/common/stream/indexed_stream.dart';
import 'package:nitrite/src/common/stream/processed_document_stream.dart';
import 'package:nitrite/src/common/stream/sorted_document_stream.dart';
import 'package:rxdart/rxdart.dart';

/// Maximum safe integer value for JavaScript (2^53 - 1).
/// This is used instead of int64MaxValue to ensure compatibility with Flutter web.
const int _maxSafeInteger = 9007199254740991;

/// @nodoc
class ReadOperations {
  final String _collectionName;
  final NitriteConfig _nitriteConfig;
  final NitriteMap<NitriteId, Document> _nitriteMap;
  final IndexOperations _indexOperations;
  final ProcessorChain _processorChain;

  late FindOptimizer _findOptimizer;

  ReadOperations(
    this._collectionName,
    this._indexOperations,
    this._nitriteConfig,
    this._nitriteMap,
    this._processorChain,
  ) {
    _findOptimizer = FindOptimizer();
  }

  DocumentCursor find(Filter? filter, FindOptions? findOptions) {
    filter ??= all;
    _prepareFilter(filter);

    return _createCursor(() async {
      Iterable<IndexDescriptor> indexDescriptors =
          await _indexOperations.listIndexes();

      var findPlan = _findOptimizer.optimize(
        filter!,
        findOptions,
        indexDescriptors,
      );
      return findPlan;
    });
  }

  Future<Document?> getById(NitriteId nitriteId) async {
    var doc = await _nitriteMap[nitriteId];
    if (doc == null) return null;
    // Hand out a copy, as the cursor does. The in-memory store returns the very
    // instance it holds, so without this a caller's `doc.put(...)` edits the
    // store directly and bypasses every index.
    var copy = doc.clone();
    return _processorChain.processAfterRead(copy);
  }

  void _prepareFilter(Filter filter) {
    if (filter is NitriteFilter) {
      _prepareNitriteFilter(filter);

      if (filter is LogicalFilter) {
        _prepareLogicalFilter(filter);
      }
    }
  }

  void _prepareNitriteFilter(NitriteFilter filter) {
    filter.nitriteConfig = _nitriteConfig;
    filter.collectionName = _collectionName;
  }

  void _prepareLogicalFilter(LogicalFilter logicalFilter) {
    var filters = logicalFilter.filters;
    for (var filter in filters) {
      if (filter is NitriteFilter) {
        filter.objectFilter = logicalFilter.objectFilter;
      }
      _prepareFilter(filter);
    }
  }

  DocumentCursor _createCursor(FutureFactory<FindPlan> findPlanFunction) {
    // a defer stream is used so that we can defer the
    // calculation till the subscription.
    return DocumentStream(
      () => _findSuitableStream(findPlanFunction),
      _processorChain,
      findPlanFunction,
      () => _count(findPlanFunction),
    );
  }

  Future<int> _count(FutureFactory<FindPlan> findPlanFunction) async {
    var findPlan = await findPlanFunction();

    // The id count is the exact match count only when nothing downstream drops
    // or changes cardinality (a post-filter, skip, or limit). Sort does not
    // change the count.
    if (findPlan.collectionScanFilter != null ||
        findPlan.skip != null ||
        findPlan.limit != null ||
        findPlan.subPlans.isNotEmpty ||
        findPlan.byIdFilter != null) {
      // fall back to streaming the documents and counting
      return _findSuitableStream(() async => findPlan).length;
    }

    var indexDescriptor = findPlan.indexDescriptor;
    if (indexDescriptor != null) {
      // index supplies the exact matching id set; count it without fetching docs
      var indexer = await _nitriteConfig.findIndexer(indexDescriptor.indexType);
      return indexer.findByFilter(findPlan, _nitriteConfig).length;
    }

    // unfiltered whole-collection scan: answer from the map size
    return _nitriteMap.size();
  }

  /// Orders the collection from an index on the sort field, so only the
  /// documents actually returned are fetched.
  ///
  /// A blocking sort has to deserialize every stored document just to read one
  /// field, which is why `orderBy(field).limit(20)` used to cost what draining
  /// the whole collection costs. An index on that field already holds the key
  /// for every document, so the ordering can be decided without touching a
  /// document.
  ///
  /// Returns `null` when the sort cannot be answered this way - the index is
  /// not a faithful stand-in for the collection (a multi-valued field is
  /// indexed once per element, a non-comparable one is not indexed at all) and
  /// the caller must fall back to the blocking sort.
  //
  // ponytail: reads the whole index (one small entry per document) rather than
  // only the skip+limit entries the page needs, because the faithfulness check
  // needs the total. Walking the index lazily in key order would make it
  // O(limit), but needs a way to know the index covers the collection without
  // reading all of it.
  Future<Stream<Document>?> _indexSortedStream(FindPlan findPlan) async {
    var descriptor = findPlan.sortIndexDescriptor;
    if (descriptor == null) return null;

    var indexer = await _nitriteConfig.findIndexer(descriptor.indexType);
    var sortKeys = await indexer.readSortKeys(
      descriptor,
      _nitriteConfig,
      await _nitriteMap.size(),
    );
    if (sortKeys == null) return null;

    // the hint is only ever set for a single-field sort, so this is that field
    var sortOrder = findPlan.blockingSortOrder.first.$2;

    // same comparator and same stability as the blocking sort, so an indexed
    // and an unindexed collection return the same rows in the same order
    sortKeys.sort((a, b) {
      var result = SortedDocumentStream.compareSortValues(
        a.$1 is DBNull ? null : a.$1.value,
        b.$1 is DBNull ? null : b.$1.value,
      );
      return sortOrder == SortOrder.descending ? -result : result;
    });

    return IndexedStream(
      Stream.fromIterable(sortKeys.map((key) => key.$2)),
      _nitriteMap,
    );
  }

  Stream<Document> _findSuitableStream(
    FutureFactory<FindPlan> findPlanFunction,
  ) async* {
    Stream<Document> rawStream;
    Stream<Document>? indexSorted;
    var findPlan = await findPlanFunction();

    if (findPlan.subPlans.isNotEmpty) {
      // or filters get all sub stream by finding suitable stream of all sub plans
      var subStreams = <Stream<Document>>[];
      for (var subPlan in findPlan.subPlans) {
        subStreams.add(_findSuitableStream(() async => subPlan));
      }

      // concat all suitable stream of all sub plans
      rawStream = ConcatStream(subStreams);

      // sub plans are the branches of an or filter, so their concatenation is a
      // set union - a document matching several branches arrives from several
      // sub streams and must still be reported once.
      rawStream = rawStream.distinctUnique(
        equals: (a, b) {
          return a.id == b.id;
        },
        hashCode: (doc) => doc.id.hashCode,
      );
    } else {
      // The offset can be taken at the source, before a document is fetched,
      // but only where nothing between the source and the page drops or
      // reorders rows: a post-filter or a blocking sort would make the source's
      // Nth row a different row from the page's. Those keep the stream skip
      // below, which is correct and merely pays for what it passes over.
      var skip = findPlan.skip ?? 0;
      // An unfiltered scan still carries the `all` filter rather than null, and
      // that one accepts every document, so it moves no row past the offset.
      // Any other filter can, and then the source's Nth row is not the page's.
      var scanFilter = findPlan.collectionScanFilter;
      var canTakeSkipAtSource = skip > 0 &&
          (scanFilter == null || scanFilter == all) &&
          findPlan.blockingSortOrder.isEmpty;
      var skipTakenAtSource = false;

      // and or single filter
      if (findPlan.byIdFilter != null) {
        var nitriteId = NitriteId.createId(findPlan.byIdFilter!.value);
        var doc = await _nitriteMap[nitriteId];
        if (doc != null) {
          rawStream = Stream.value(doc);
        } else {
          rawStream = Stream.empty();
        }
      } else {
        var indexDescriptor = findPlan.indexDescriptor;
        if (indexDescriptor != null) {
          // get optimized filter
          var indexer = await _nitriteConfig.findIndexer(
            indexDescriptor.indexType,
          );
          var nitriteIdStream = indexer.findByFilter(findPlan, _nitriteConfig);

          if (canTakeSkipAtSource) {
            // an id is not a document; dropping one costs nothing next to the
            // fetch and decode it saves
            nitriteIdStream = nitriteIdStream.skip(skip);
            skipTakenAtSource = true;
          }

          // create indexed stream from optimized filter
          rawStream = IndexedStream(nitriteIdStream, _nitriteMap);
        } else {
          indexSorted = await _indexSortedStream(findPlan);
          if (indexSorted != null) {
            rawStream = indexSorted;
          } else if (canTakeSkipAtSource) {
            rawStream = _nitriteMap.valuesSkipping(skip);
            skipTakenAtSource = true;
          } else {
            rawStream = _nitriteMap.values();
          }
        }
      }

      if (findPlan.collectionScanFilter != null) {
        rawStream = FilteredStream(rawStream, findPlan.collectionScanFilter);
      }

      // the blocking sort still runs whenever the ordered ids were not used -
      // either no index could answer the sort, or the one that could turned out
      // not to cover the collection faithfully
      if (indexSorted == null && findPlan.blockingSortOrder.isNotEmpty) {
        rawStream = SortedDocumentStream(findPlan, rawStream);
      }

      if (findPlan.limit != null || findPlan.skip != null) {
        rawStream = rawStream.skip(skipTakenAtSource ? 0 : (findPlan.skip ?? 0));
        rawStream = rawStream.take(findPlan.limit ?? _maxSafeInteger);
      }
    }

    yield* rawStream;
  }
}
