import 'package:dart_numerics/dart_numerics.dart';
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

/// @nodoc
class ReadOperations {
  final String _collectionName;
  final NitriteConfig _nitriteConfig;
  final NitriteMap<NitriteId, Document> _nitriteMap;
  final IndexOperations _indexOperations;
  final ProcessorChain _processorChain;

  late FindOptimizer _findOptimizer;

  ReadOperations(this._collectionName, this._indexOperations,
      this._nitriteConfig, this._nitriteMap, this._processorChain) {
    _findOptimizer = FindOptimizer();
  }

  DocumentCursor find(Filter? filter, FindOptions? findOptions) {
    filter ??= all;
    _prepareFilter(filter);

    return _createCursor(() async {
      Iterable<IndexDescriptor> indexDescriptors =
          await _indexOperations.listIndexes();

      var findPlan =
          _findOptimizer.optimize(filter!, findOptions, indexDescriptors);
      return findPlan;
    });
  }

  Future<Document?> getById(NitriteId nitriteId) async {
    var doc = await _nitriteMap[nitriteId];
    if (doc != null) {
      doc = await _processorChain.processAfterRead(doc);
    }
    return doc;
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
    return DocumentStream(() => _findSuitableStream(findPlanFunction),
        _processorChain, findPlanFunction);
  }

  Stream<Document> _findSuitableStream(
      FutureFactory<FindPlan> findPlanFunction) async* {
    Stream<Document> rawStream;
    var findPlan = await findPlanFunction();

    if (findPlan.subPlans.isNotEmpty) {
      // or filters get all sub stream by finding suitable stream of all sub plans
      var subStreams = <Stream<Document>>[];
      for (var subPlan in findPlan.subPlans) {
        subStreams.add(_findSuitableStream(() async => subPlan));
      }

      // concat all suitable stream of all sub plans
      rawStream = ConcatStream(subStreams);

      // return only distinct items
      if (findPlan.distinct) {
        rawStream = rawStream.distinctUnique(
            equals: (a, b) {
              return a.id == b.id;
            },
            hashCode: (doc) => doc.id.hashCode);
      }
    } else {
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
          var indexer =
              await _nitriteConfig.findIndexer(indexDescriptor.indexType);
          var nitriteIdStream = indexer.findByFilter(findPlan, _nitriteConfig);

          // create indexed stream from optimized filter
          rawStream = IndexedStream(nitriteIdStream, _nitriteMap);
        } else {
          rawStream = _nitriteMap.values();
        }
      }

      if (findPlan.collectionScanFilter != null) {
        rawStream = FilteredStream(rawStream, findPlan.collectionScanFilter);
      }

      if (findPlan.blockingSortOrder.isNotEmpty) {
        rawStream = SortedDocumentStream(findPlan, rawStream);
      }

      if (findPlan.limit != null || findPlan.skip != null) {
        rawStream = rawStream.skip(findPlan.skip ?? 0);
        rawStream = rawStream.take(findPlan.limit ?? int64MaxValue);
      }
    }

    yield* rawStream;
  }
}
