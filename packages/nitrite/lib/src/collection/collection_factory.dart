import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:mutex/mutex.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/operations/collection_operations.dart';
import 'package:nitrite/src/common/concurrent/lock_service.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:quiver/core.dart';

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
  final Map<int, StreamSubscription> _subscriptions = {};

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
      _checkOpened();
      _collectionOperations.addProcessor(processor);
    });
  }

  @override
  Future<void> clear() async {
    return _lock.protectWrite(() async {
      _checkOpened();
      await _nitriteMap.clear();
    });
  }

  @override
  Future<void> close() async {
    return _lock.protectWrite(() async {
      _checkOpened();
      await _collectionOperations.close();
      _eventBus.destroy();
    });
  }

  @override
  Future<void> createIndex(List<String> fields,
      [IndexOptions? indexOptions]) async {
    fields.notNullOrEmpty('Fields cannot be null');

    var indexFields = Fields.withNames(fields);
    return _lock.protectWrite(() async {
      _checkOpened();

      if (indexOptions == null) {
        await _collectionOperations.createIndex(indexFields, IndexType.unique);
      } else {
        await _collectionOperations.createIndex(
            indexFields, indexOptions.indexType);
      }
    });
  }

  @override
  Future<void> drop() async {
    return _lock.protectWrite(() async {
      _checkOpened();
      await _collectionOperations.close();
      await _collectionOperations.dropCollection();

      _eventBus.destroy();
      _isDropped = true;
    });
  }

  @override
  Future<void> dropAllIndices() async {
    return _lock.protectWrite(() async {
      _checkOpened();
      await _collectionOperations.dropAllIndices();
    });
  }

  @override
  Future<void> dropIndex(List<String> fields) {
    fields.notNullOrEmpty('Fields cannot be null');

    var indexFields = Fields.withNames(fields);
    return _lock.protectWrite(() async {
      _checkOpened();
      await _collectionOperations.dropIndex(indexFields);
    });
  }

  @override
  Future<DocumentCursor> find(
      [Filter? filter, FindOptions? findOptions]) async {
    return _lock.protectRead(() async {
      _checkOpened();
      return _collectionOperations.find(filter, findOptions);
    });
  }

  @override
  Future<Attributes> getAttributes() async {
    return _lock.protectRead(() async {
      _checkOpened();
      return _collectionOperations.getAttributes();
    });
  }

  @override
  Future<Document?> getById(NitriteId id) async {
    id.notNullOrEmpty('Id cannot be null');

    return _lock.protectRead(() async {
      _checkOpened();
      return _collectionOperations.getById(id);
    });
  }

  @override
  NitriteStore<Config> getStore<Config extends StoreConfig>() {
    return _nitriteStore as NitriteStore<Config>;
  }

  @override
  Future<bool> hasIndex(List<String> fields) async {
    fields.notNullOrEmpty('Fields cannot be null');

    var indexFields = Fields.withNames(fields);
    return _lock.protectRead(() async {
      _checkOpened();
      return _collectionOperations.hasIndex(indexFields);
    });
  }

  @override
  Future<WriteResult> insert(List<Document> documents) async {
    documents.notNullOrEmpty('Documents cannot be null or empty');

    return _lock.protectWrite(() async {
      _checkOpened();
      return _collectionOperations.insert(documents);
    });
  }

  @override
  Future<bool> get isDropped => _lock.protectRead(() async {
        return _isDropped;
      });

  @override
  Future<bool> isIndexing(List<String> fields) {
    fields.notNullOrEmpty('Fields cannot be null');

    var indexFields = Fields.withNames(fields);
    return _lock.protectRead(() async {
      _checkOpened();
      return _collectionOperations.isIndexing(indexFields);
    });
  }

  @override
  Future<bool> get isOpen => _lock.protectRead(() async {
        return !_nitriteStore.isClosed && !_isDropped;
      });

  @override
  Future<Iterable<IndexDescriptor>> listIndexes() {
    return _lock.protectRead(() async {
      _checkOpened();
      return _collectionOperations.listIndexes();
    });
  }

  @override
  String get name => _collectionName;

  @override
  Future<void> rebuildIndex(List<String> fields) async {
    fields.notNullOrEmpty('Fields cannot be null');

    IndexDescriptor? indexDescriptor;
    var indexFields = Fields.withNames(fields);
    await _lock.protectRead(() async {
      _checkOpened();
      indexDescriptor = await _collectionOperations.findIndex(indexFields);
    });

    if (indexDescriptor != null) {
      await _validateRebuildIndex(indexDescriptor);

      await _lock.protectWrite(() async {
        _checkOpened();
        await _collectionOperations.rebuildIndex(indexDescriptor!);
      });
    }
  }

  @override
  Future<WriteResult> remove(Filter filter,
      [Document? document, bool? justOne]) {
    if (document != null) {
      if (document.hasId) {
        return _lock.protectWrite(() async {
          _checkOpened();
          return _collectionOperations.removeDocument(document);
        });
      } else {
        throw NotIdentifiableException(
            'Document has no id, cannot remove by document');
      }
    } else {
      var once = justOne ?? false;
      if (filter == all && once) {
        throw InvalidOperationException(
            'Cannot remove all documents with justOne set to true');
      }

      return _lock.protectWrite(() async {
        _checkOpened();
        return _collectionOperations.removeByFilter(filter, once);
      });
    }
  }

  @override
  Future<void> setAttributes(Attributes attributes) {
    attributes.notNullOrEmpty('Attributes cannot be null or empty');

    return _lock.protectWrite(() async {
      _checkOpened();
      await _collectionOperations.setAttributes(attributes);
    });
  }

  @override
  Future<int> get size => _lock.protectRead(() async {
        _checkOpened();
        return _collectionOperations.getSize();
      });

  @override
  Future<void> subscribe<T>(CollectionEventListener<T> listener) async {
    listener.notNullOrEmpty('Listener cannot be null');

    return _lock.protectWrite(() async {
      _checkOpened();
      var subscription = _eventBus
          .on<CollectionEventInfo<T>>()
          .listen((event) => listener(event));

      var hashCode = hash2(listener, T);
      _subscriptions[hashCode] = subscription;
    });
  }

  @override
  Future<void> unsubscribe<T>(CollectionEventListener<T> listener) {
    listener.notNullOrEmpty('Listener cannot be null');

    return _lock.protectWrite(() async {
      _checkOpened();
      var hashCode = hash2(listener, T);
      var subscription = _subscriptions[hashCode];
      if (subscription != null) {
        subscription.cancel();

        _subscriptions.remove(hashCode);
      }
    });
  }

  @override
  Future<WriteResult> updateAll(List<Document> documents,
      [bool insertIfAbsent = false]) {
    documents.notNullOrEmpty('Documents cannot be null or empty');

    return _lock.protectWrite(() async {
      _checkOpened();
      return _collectionOperations.updateAll(documents, insertIfAbsent);
    });
  }

  @override
  Future<WriteResult> updateOne(Document documents,
      [bool insertIfAbsent = false]) {
    return _lock.protectWrite(() async {
      _checkOpened();
      return _collectionOperations.updateOne(documents, insertIfAbsent);
    });
  }

  @override
  Future<WriteResult> update(Filter filter, Document update,
      [UpdateOptions? updateOptions]) async {
    update.notNullOrEmpty('Documents cannot be null or empty');
    updateOptions ??= UpdateOptions();
    updateOptions.insertIfAbsent = false;
    updateOptions.justOnce = false;

    return _lock.protectWrite(() async {
      _checkOpened();
      return _collectionOperations.update(filter, update, updateOptions!);
    });
  }

  Future<void> _initialize() async {
    _isDropped = false;
    _nitriteStore = _nitriteConfig.getNitriteStore();
    _lock = await _lockService.getLock(_collectionName);
    _eventBus = EventBus();
    _collectionOperations = CollectionOperations(
        _collectionName, _nitriteMap, _nitriteConfig, _eventBus);
    await _collectionOperations.initialize();
  }

  void _checkOpened() {
    var opened = !_nitriteStore.isClosed && !_isDropped;
    if (opened) return;
    throw NitriteIOException("Collection is closed");
  }

  Future<void> _validateRebuildIndex(IndexDescriptor? indexDescriptor) async {
    indexDescriptor.notNullOrEmpty('Index descriptor cannot be null');

    var indexFields = indexDescriptor!.indexFields.fieldNames;
    var isIndexing = await this.isIndexing(indexFields);
    if (isIndexing) {
      throw InvalidOperationException(
          'Cannot rebuild index, index is currently being built');
    }
  }
}
