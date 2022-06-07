import 'package:event_bus/event_bus.dart';
import 'package:mutex/mutex.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/collection_operations.dart';
import 'package:nitrite/src/collection/options.dart';
import 'package:nitrite/src/common/concurrent/lock_service.dart';
import 'package:nitrite/src/common/meta/attributes.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/common/write_result.dart';

class CollectionFactory {
  final Map<String, NitriteCollection> _collectionMap = {};
  final LockService _lockService;

  CollectionFactory(this._lockService);

  Future<NitriteCollection> getCollection(
      String name, NitriteConfig nitriteConfig, bool writeCatalogue) async {
    nitriteConfig.notNullOrEmpty('Configuration is null while '
        'creating collection');
    name.notNullOrEmpty('Collection name is null or empty');

    var lock = await _lockService.getLock(name);
    return await lock.protectWrite(() async {
      if (_collectionMap.containsKey(name)) {
        var collection = _collectionMap[name]!;
        var isDropped = await collection.isDropped;
        var isOpen = await collection.isOpen;
        if (isDropped || !isOpen) {
          _collectionMap.remove(name);
          return await _createCollection(name, nitriteConfig, writeCatalogue);
        }
        return _collectionMap[name]!;
      } else {
        return await _createCollection(name, nitriteConfig, writeCatalogue);
      }
    });
  }

  Future<void> clear() async {
    var lock = await _lockService.getLock('CollectionFactory');
    return await lock.protectWrite(() async {
      try {
        _collectionMap.forEach((key, value) async {
          await value.close();
        });
        _collectionMap.clear();
      } catch (e) {
        throw NitriteIOException("Failed to close a collection");
      }
    });
  }

  Future<NitriteCollection> _createCollection(
      String name, NitriteConfig nitriteConfig, bool writeCatalogue) async {
    var store = nitriteConfig.getNitriteStore();
    var nitriteMap = await store.openMap<NitriteId, Document>(name);
    var collection = _DefaultNitriteCollection(
        name, nitriteMap, nitriteConfig, _lockService);
    await collection._initialize();

    if (writeCatalogue) {
      var repoRegistry = await store.repositoryRegistry;
      if (repoRegistry.contains(name)) {
        await nitriteMap.close();
        await collection.close();
        throw ValidationException("A repository with same name already exists");
      }

      var keyedRepoRegistry = await store.keyedRepositoryRegistry;
      for (var set in keyedRepoRegistry.values) {
        if (set.contains(name)) {
          await nitriteMap.close();
          await collection.close();
          throw ValidationException("A keyed repository with same name "
              "already exists");
        }
      }

      _collectionMap[name] = collection;
      var storeCatalog = store.catalog;
      await storeCatalog.writeCollectionEntry(name);
    }

    return collection;
  }
}

class _DefaultNitriteCollection extends NitriteCollection {
  final String _collectionName;
  final LockService _lockService;
  final NitriteMap<NitriteId, Document> _nitriteMap;
  final NitriteConfig _nitriteConfig;

  late NitriteStore _nitriteStore;
  late CollectionOperations _collectionOperations;
  late EventBus _eventBus;
  late ReadWriteMutex _lock;

  bool _isDropped = false;

  _DefaultNitriteCollection(this._collectionName, this._nitriteMap,
      this._nitriteConfig, this._lockService);

  @override
  Future<void> addProcessor(Processor processor) async {
    processor.notNullOrEmpty('Processor is null');

    return _lock.protectWrite(() async {
      await _checkOpened();
      _collectionOperations.addProcessor(processor);
    });
  }

  @override
  Future<void> clear() {
    return _lock.protectWrite(() async {
      await _checkOpened();
      await _nitriteMap.clear();
    });
  }

  @override
  Future<void> close() {
    return _lock.protectWrite(() async {
      await _checkOpened();
      await _collectionOperations.close();
      _eventBus.destroy();
    });
  }

  @override
  Future<void> createIndex(List<String> fields, [IndexOptions? indexOptions]) {
    fields.notNullOrEmpty('Fields cannot be null');

    var indexFields = Fields.withNames(fields);
    return _lock.protectWrite(() async {
      await _checkOpened();
      
      if (indexOptions == null) {
        await _collectionOperations.createIndex(indexFields, IndexType.unique);
      } else {
        await _collectionOperations.createIndex(indexFields, indexOptions.indexType);
      }
    });
  }

  @override
  Future<void> drop() {
    return _lock.protectWrite(() async {
      await _checkOpened();
      await _collectionOperations.close();
      await _collectionOperations.dropCollection();
      
      _eventBus.destroy();
      _isDropped = true;
    });
  }

  @override
  Future<void> dropAllIndices() {
    // TODO: implement dropAllIndices
    throw UnimplementedError();
  }

  @override
  Future<void> dropIndex(List<String> fields) {
    // TODO: implement dropIndex
    throw UnimplementedError();
  }

  @override
  DocumentCursor find([Filter? filter, FindOptions? findOptions]) {
    // TODO: implement find
    throw UnimplementedError();
  }

  @override
  Future<Attributes> getAttributes() {
    // TODO: implement getAttributes
    throw UnimplementedError();
  }

  @override
  Future<Document> getById(NitriteId id) {
    // TODO: implement getById
    throw UnimplementedError();
  }

  @override
  NitriteStore<Config> getStore<Config extends StoreConfig>() {
    // TODO: implement getStore
    throw UnimplementedError();
  }

  @override
  Future<bool> hasIndex(List<String> fields) {
    // TODO: implement hasIndex
    throw UnimplementedError();
  }

  @override
  WriteResult insert(List<Document> documents) {
    // TODO: implement insert
    throw UnimplementedError();
  }

  @override
  // TODO: implement isDropped
  Future<bool> get isDropped => throw UnimplementedError();

  @override
  Future<bool> isIndexing(List<String> fields) {
    // TODO: implement isIndexing
    throw UnimplementedError();
  }

  @override
  // TODO: implement isOpen
  Future<bool> get isOpen => throw UnimplementedError();

  @override
  Future<Iterable<IndexDescriptor>> listIndexes() {
    // TODO: implement listIndexes
    throw UnimplementedError();
  }

  @override
  // TODO: implement name
  String get name => throw UnimplementedError();

  @override
  Future<void> rebuildIndex(List<String> fields) {
    // TODO: implement rebuildIndex
    throw UnimplementedError();
  }

  @override
  WriteResult remove(Filter filter, [Document? document, bool? justOne]) {
    // TODO: implement remove
    throw UnimplementedError();
  }

  @override
  Future<void> setAttributes(Attributes attributes) {
    // TODO: implement setAttributes
    throw UnimplementedError();
  }

  @override
  // TODO: implement size
  Future<bool> get size => throw UnimplementedError();

  @override
  void subscribe(CollectionEventListener listener) {
    // TODO: implement subscribe
  }

  @override
  void unsubscribe(CollectionEventListener listener) {
    // TODO: implement unsubscribe
  }

  @override
  WriteResult update(List<Document> documents,
      [Filter? filter, Document? update, UpdateOptions? updateOptions]) {
    // TODO: implement update
    throw UnimplementedError();
  }

  Future<void> _initialize() async {
    _isDropped = false;
    _nitriteStore = _nitriteConfig.getNitriteStore();
    _lock = await _lockService.getLock(_collectionName);
    _eventBus = EventBus();
    _collectionOperations = CollectionOperations(_collectionName, _nitriteMap, _nitriteConfig, _eventBus);
  }

  Future<void> _checkOpened() async {
    var opened = await isOpen;
    if (opened) return;
    throw NitriteIOException("Collection is closed");
  }
}
