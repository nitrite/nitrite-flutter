import 'package:event_bus/event_bus.dart';
import 'package:nitrite/src/collection/document.dart';
import 'package:nitrite/src/collection/document_cursor.dart';
import 'package:nitrite/src/collection/nitrite_id.dart';
import 'package:nitrite/src/collection/operations/document_index_writer.dart';
import 'package:nitrite/src/collection/operations/index_operations.dart';
import 'package:nitrite/src/collection/operations/read_operations.dart';
import 'package:nitrite/src/collection/operations/write_operations.dart';
import 'package:nitrite/src/collection/options.dart';
import 'package:nitrite/src/common/fields.dart';
import 'package:nitrite/src/common/meta/attributes.dart';
import 'package:nitrite/src/common/processors/processor.dart';
import 'package:nitrite/src/common/write_result.dart';
import 'package:nitrite/src/filters/filter.dart';
import 'package:nitrite/src/index/index_descriptor.dart';
import 'package:nitrite/src/nitrite_config.dart';
import 'package:nitrite/src/store/nitrite_map.dart';

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
      this._nitriteConfig, this._eventBus) {
    _init();
  }

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

  Future<void> dropAllIndices() async {}

  Future<void> dropIndex(Fields indexFields) async {}

  DocumentCursor find([Filter? filter, FindOptions? findOptions]) {
    throw UnimplementedError();
  }

  Future<Attributes> getAttributes() async {
    throw UnimplementedError();
  }

  Future<Document> getById(NitriteId nitriteId) async {
    throw UnimplementedError();
  }

  Future<bool> hasIndex(Fields indexFields) {
    throw UnimplementedError();
  }

  WriteResult insert(List<Document> documents) {
    throw UnimplementedError();
  }

  Future<bool> isIndexing(Fields indexFields) async {
    throw UnimplementedError();
  }

  Future<Iterable<IndexDescriptor>> listIndexes() async {
    throw UnimplementedError();
  }

  Future<IndexDescriptor?> findIndex(Fields indexFields) async {
    throw UnimplementedError();
  }

  Future<void> rebuildIndex(IndexDescriptor indexDescriptor) async {}

  Future<WriteResult> removeDocument(Document document) async {
    throw UnimplementedError();
  }

  Future<WriteResult> removeByFilter(Filter filter, bool once) async {
    throw UnimplementedError();
  }

  Future<void> setAttributes(Attributes attributes) async {}

  Future<bool> getSize() async {
    throw UnimplementedError();
  }

  Future<WriteResult> update(
      Filter filter, Document update, UpdateOptions updateOptions) {
    throw UnimplementedError();
  }

  Future<WriteResult> updateAll(List<Document> documents, bool insertIfAbsent) {
    throw UnimplementedError();
  }

  Future<WriteResult> updateOne(Document documents, bool insertIfAbsent) {
    throw UnimplementedError();
  }

  void _init() {
    _processorChain = ProcessorChain();
    _indexOperations = IndexOperations(
        _collectionName, _nitriteConfig, _nitriteMap, _eventBus);
    _readOperations =
        ReadOperations(_collectionName, _nitriteMap, _nitriteConfig, _eventBus);

    var indexWriter = DocumentIndexWriter(_nitriteConfig, _indexOperations);
    _writeOperations = WriteOperations(
        indexWriter, _readOperations, _nitriteMap, _eventBus, _processorChain);
  }
}
