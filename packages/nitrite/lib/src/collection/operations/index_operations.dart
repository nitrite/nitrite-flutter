import 'package:event_bus/event_bus.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/operations/index_manager.dart';
import 'package:nitrite/src/common/async/executor.dart';
import 'package:nitrite/src/common/util/document_utils.dart';

class IndexOperations {
  final String _collectionName;
  final NitriteConfig _nitriteConfig;
  final NitriteMap<NitriteId, Document> _nitriteMap;
  final EventBus _eventBus;
  final Map<Fields, bool> _indexBuildTracker = {};

  late IndexManager _indexManager;

  IndexOperations(this._collectionName, this._nitriteConfig, this._nitriteMap,
      this._eventBus);

  Future<void> initialize() async {
    _indexManager = IndexManager(_collectionName, _nitriteConfig);
    await _indexManager.initialize();
  }

  Future<void> close() {
    return _indexManager.close();
  }

  Future<void> createIndex(Fields fields, String indexType) async {
    var indexDescriptor = await _indexManager.findExactIndexDescriptor(fields);
    if (indexDescriptor == null) {
      // if no index create index
      indexDescriptor =
          await _indexManager.createIndexDescriptor(fields, indexType);
    } else {
      // if index already there throw
      throw IndexingException('Index already exists on fields: $fields');
    }

    await buildIndex(indexDescriptor, false);
  }

  // call to this method is already synchronized, only one thread per field
  // can access it only if rebuild is already not running for that field
  Future<void> buildIndex(IndexDescriptor indexDescriptor, bool rebuild) async {
    var fields = indexDescriptor.fields;
    if (_getBuildFlag(fields) == false) {
      _indexBuildTracker[fields] = true;
      return _buildIndexInternal(indexDescriptor, rebuild);
    }
    throw IndexingException(
        'Index build already in progress on fields: $fields');
  }

  Future<void> dropAllIndices() async {
    for (var entry in _indexBuildTracker.entries) {
      if (entry.value == true) {
        throw IndexingException(
            'Index build already in progress on fields: ${entry.key}');
      }
    }

    var indices = await listIndexes();

    var executor = Executor();
    for (var index in indices) {
      // drop all indices in parallel
      executor.submit(() async => await dropIndex(index.fields));
    }

    await executor.execute();
    await _indexManager.dropIndexMeta();
    _indexBuildTracker.clear();
    await _indexManager.close();

    // recreate index manager to discard old native resources
    _indexManager = IndexManager(_collectionName, _nitriteConfig);
    await _indexManager.initialize();
  }

  Future<void> dropIndex(Fields fields) async {
    if (_getBuildFlag(fields)) {
      throw IndexingException(
          'Index build already in progress on fields: $fields');
    }

    var indexDescriptor = await findIndexDescriptor(fields);
    if (indexDescriptor != null) {
      var indexType = indexDescriptor.indexType;
      var nitriteIndexer = await _nitriteConfig.findIndexer(indexType);
      await nitriteIndexer.dropIndex(indexDescriptor, _nitriteConfig);

      await _indexManager.dropIndexDescriptor(fields);
      _indexBuildTracker.remove(fields);
    } else {
      throw IndexingException('Index does not exist on fields: $fields');
    }
  }

  Future<bool> hasIndexEntry(Fields fields) {
    return _indexManager.hasIndexDescriptor(fields);
  }

  Future<bool> isIndexing(Fields fields) async {
    // has an index will only return true, if there is an index on
    // the value and indexing is not running on it
    return await _indexManager.hasIndexDescriptor(fields) &&
        _getBuildFlag(fields);
  }

  Future<Iterable<IndexDescriptor>> listIndexes() {
    return _indexManager.getIndexDescriptors();
  }

  Future<IndexDescriptor?> findIndexDescriptor(Fields fields) {
    return _indexManager.findExactIndexDescriptor(fields);
  }

  Future<bool> shouldRebuildIndex(Fields fields) async {
    return await _indexManager.isDirtyIndex(fields) && !_getBuildFlag(fields);
  }

  Future<void> clear() async {
    for (var entry in _indexBuildTracker.entries) {
      if (entry.value == true) {
        throw IndexingException(
            'Index build already in progress on fields: ${entry.key}');
      }
    }

    await _indexManager.clearAll();
    _indexBuildTracker.clear();
  }

  bool _getBuildFlag(Fields field) {
    var flag = _indexBuildTracker[field];
    if (flag != null) return flag;

    _indexBuildTracker[field] = false;
    return false;
  }

  Future<void> _buildIndexInternal(
      IndexDescriptor indexDescriptor, bool rebuild) async {
    var fields = indexDescriptor.fields;

    try {
      _alert(EventType.indexStart, fields);
      // first put dirty marker
      await _indexManager.beginIndexing(fields);

      var indexType = indexDescriptor.indexType;
      var nitriteIndexer = await _nitriteConfig.findIndexer(indexType);

      // if rebuild drop existing index
      if (rebuild) {
        await nitriteIndexer.dropIndex(indexDescriptor, _nitriteConfig);
      }

      var executor = Executor();
      await for (var entry in _nitriteMap.entries()) {
        var document = entry.second;
        var fieldValues = getDocumentValues(document, indexDescriptor.fields);

        // write index entries in parallel
        executor.submit(() async => await nitriteIndexer.writeIndexEntry(
            fieldValues, indexDescriptor, _nitriteConfig));
      }

      await executor.execute();
    } finally {
      // remove dirty marker to denote indexing completed successfully
      // if dirty marker is found in any index, it needs to be rebuilt
      await _indexManager.endIndexing(fields);
      _indexBuildTracker[fields] = false;
      _alert(EventType.indexEnd, fields);
    }
  }

  void _alert(EventType eventType, Fields field) {
    var eventInfo = CollectionEventInfo<Fields>(
        eventType: eventType,
        item: field,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        originator: 'IndexOperations');
    _eventBus.fire(eventInfo);
  }
}
