import 'package:event_bus/event_bus.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/operations/index_manager.dart';
import 'package:nitrite/src/common/util/document_utils.dart';

class IndexOperations {
  final String _collectionName;
  final NitriteConfig _nitriteConfig;
  final NitriteMap<NitriteId, Document> _nitriteMap;
  final EventBus _eventBus;

  late IndexManager _indexManager;

  IndexOperations(this._collectionName, this._nitriteConfig, this._nitriteMap,
      this._eventBus);

  Future<bool> isIndexing(Fields indexFields) async => false;

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
    await _buildIndexInternal(indexDescriptor, rebuild);
  }

  Future<void> dropAllIndices() async {
    var indices = await listIndexes();
    for (var index in indices) {
      await dropIndex(index.fields);
    }

    await _indexManager.dropIndexMeta();
    await _indexManager.close();

    // recreate index manager to discard old native resources
    _indexManager = IndexManager(_collectionName, _nitriteConfig);
    await _indexManager.initialize();
  }

  Future<void> dropIndex(Fields fields) async {
    var indexDescriptor = await findIndexDescriptor(fields);
    if (indexDescriptor != null) {
      var indexType = indexDescriptor.indexType;
      var nitriteIndexer = await _nitriteConfig.findIndexer(indexType);
      await nitriteIndexer.dropIndex(indexDescriptor, _nitriteConfig);
      await _indexManager.dropIndexDescriptor(fields);
    } else {
      throw IndexingException('Index does not exist on fields: $fields');
    }
  }

  Future<bool> hasIndexEntry(Fields fields) {
    return _indexManager.hasIndexDescriptor(fields);
  }

  Future<Iterable<IndexDescriptor>> listIndexes() {
    return _indexManager.getIndexDescriptors();
  }

  Future<IndexDescriptor?> findIndexDescriptor(Fields fields) {
    return _indexManager.findExactIndexDescriptor(fields);
  }

  Future<bool> shouldRebuildIndex(Fields fields) async {
    return await _indexManager.isDirtyIndex(fields);
  }

  Future<void> clear() async {
    await _indexManager.clearAll();
  }

  Future<void> _buildIndexInternal(
      IndexDescriptor indexDescriptor, bool rebuild) async {
    var fields = indexDescriptor.fields;

    _alert(EventType.indexStart, fields);
    // first put dirty marker
    await _indexManager.beginIndexing(fields);

    var indexType = indexDescriptor.indexType;
    var nitriteIndexer = await _nitriteConfig.findIndexer(indexType);

    // if rebuild drop existing index
    if (rebuild) {
      await nitriteIndexer.dropIndex(indexDescriptor, _nitriteConfig);
    }

    await for (var entry in _nitriteMap.entries()) {
      var document = entry.$2;
      var fieldValues = getDocumentValues(document, indexDescriptor.fields);

      await nitriteIndexer.writeIndexEntry(
          fieldValues, indexDescriptor, _nitriteConfig);
    }

    // remove dirty marker to denote indexing completed successfully
    // if dirty marker is found in any index, it needs to be rebuilt
    await _indexManager.endIndexing(fields);
    _alert(EventType.indexEnd, fields);
  }

  void _alert(EventType eventType, Fields field) {
    var eventInfo = CollectionEventInfo<Fields>(
        eventType: eventType,
        item: field,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        originator: 'IndexOperations');

    if (!_eventBus.streamController.isClosed) {
      _eventBus.fire(eventInfo);
    }
  }
}
