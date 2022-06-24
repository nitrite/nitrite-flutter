import 'package:event_bus/event_bus.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/operations/document_index_writer.dart';
import 'package:nitrite/src/collection/operations/index_operations.dart';
import 'package:nitrite/src/collection/operations/read_operations.dart';
import 'package:nitrite/src/collection/operations/write_operations.dart';
import 'package:nitrite/src/common/processors/processor.dart';

class CollectionOperations {
  final String _collectionName;
  final NitriteMap<NitriteId, Document> _nitriteMap;
  final NitriteConfig _nitriteConfig;
  final EventBus _eventBus;

  late ProcessorChain _processorChain;
  late IndexOperations _indexOperations;
  late WriteOperations _writeOperations;
  late ReadOperations _readOperations;

  CollectionOperations(this._collectionName, this._nitriteMap,
      this._nitriteConfig, this._eventBus);

  void addProcessor(Processor processor) {
    _processorChain.add(processor);
  }

  Future<void> close() async {
    await _indexOperations.close();
    await _nitriteMap.close();
  }

  Future<void> createIndex(Fields indexFields, String indexType) async {
    await _indexOperations.createIndex(indexFields, indexType);
  }

  Future<void> dropCollection() async {
    // drop all indices
    await _indexOperations.dropAllIndices();

    // remove the collection name from the catalog
    var catalog = _nitriteMap.getStore().catalog;
    await catalog.remove(_nitriteMap.name);

    // drop the map
    await _nitriteMap.close();
  }

  Future<void> dropAllIndices() async {
    await _indexOperations.dropAllIndices();
  }

  Future<void> dropIndex(Fields indexFields) async {
    await _indexOperations.dropIndex(indexFields);
  }

  Future<DocumentCursor> find([Filter? filter, FindOptions? findOptions]) {
    return _readOperations.find(filter, findOptions);
  }

  Future<Attributes> getAttributes() async {
    return _nitriteMap.getAttributes();
  }

  Future<Document?> getById(NitriteId nitriteId) async {
    return _readOperations.getById(nitriteId);
  }

  Future<bool> hasIndex(Fields indexFields) {
    return _indexOperations.hasIndexEntry(indexFields);
  }

  WriteResult insert(List<Document> documents) {
    var stream = _writeOperations.insert(documents);
    return WriteResult(stream);
  }

  Future<bool> isIndexing(Fields indexFields) async {
    return _indexOperations.isIndexing(indexFields);
  }

  Future<Iterable<IndexDescriptor>> listIndexes() async {
    return Future.value(_indexOperations.listIndexes());
  }

  Future<IndexDescriptor?> findIndex(Fields indexFields) async {
    return _indexOperations.findIndexDescriptor(indexFields);
  }

  Future<void> rebuildIndex(IndexDescriptor indexDescriptor) async {
    await _indexOperations.buildIndex(indexDescriptor, true);
  }

  WriteResult removeDocument(Document document) {
    var stream = _writeOperations.removeDocument(document);
    return WriteResult(stream);
  }

  WriteResult removeByFilter(Filter filter, bool once) {
    var stream = _writeOperations.removeByFilter(filter, once);
    return WriteResult(stream);
  }

  Future<void> setAttributes(Attributes attributes) async {
    await _nitriteMap.setAttributes(attributes);
  }

  Future<int> getSize() async {
    return _nitriteMap.size();
  }

  WriteResult update(
      Filter filter, Document update, UpdateOptions updateOptions) {
    var stream = _writeOperations.update(filter, update, updateOptions);
    return WriteResult(stream);
  }

  WriteResult updateAll(List<Document> documents, bool insertIfAbsent) {
    var stream = _writeOperations.updateAll(documents, insertIfAbsent);
    return WriteResult(stream);
  }

  WriteResult updateOne(Document documents, bool insertIfAbsent) {
    var stream = _writeOperations.updateOne(documents, insertIfAbsent);
    return WriteResult(stream);
  }

  Future<void> initialize() async {
    _processorChain = ProcessorChain();
    _indexOperations = IndexOperations(
        _collectionName, _nitriteConfig, _nitriteMap, _eventBus);
    await _indexOperations.initialize();
    
    _readOperations = ReadOperations(_collectionName, _indexOperations,
        _nitriteConfig, _nitriteMap, _processorChain);

    var indexWriter = DocumentIndexWriter(_nitriteConfig, _indexOperations);
    _writeOperations = WriteOperations(
        indexWriter, _readOperations, _nitriteMap, _eventBus, _processorChain);
  }
}
