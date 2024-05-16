import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/collection_factory.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/repository/repository_operations.dart';

/// @nodoc
class RepositoryFactory {
  final Map<String, ObjectRepository<dynamic>> _repositoryMap = {};
  final CollectionFactory _collectionFactory;

  RepositoryFactory(this._collectionFactory);

  Future<ObjectRepository<T>> getRepository<T>(NitriteConfig nitriteConfig,
      [EntityDecorator<T>? entityDecorator, String? key]) async {
    var collectionName = entityDecorator == null
        ? findRepositoryNameByType<T>(nitriteConfig.nitriteMapper, key)
        : findRepositoryNameByDecorator(entityDecorator, key);

    if (_repositoryMap.containsKey(collectionName)) {
      var repository = _repositoryMap[collectionName]! as ObjectRepository<T>;
      if (repository.isDropped || !repository.isOpen) {
        _repositoryMap.remove(collectionName);
        return await _createRepository<T>(
            nitriteConfig, collectionName, entityDecorator, key);
      } else {
        return repository;
      }
    } else {
      return await _createRepository<T>(
          nitriteConfig, collectionName, entityDecorator, key);
    }
  }

  Future<void> clear() async {
    try {
      for (var entry in _repositoryMap.entries) {
        await entry.value.close();
      }
      _repositoryMap.clear();
    } catch (e, stackTrace) {
      throw NitriteIOException('Failed to clear an object repository',
          cause: e, stackTrace: stackTrace);
    }
  }

  Future<ObjectRepository<T>> _createRepository<T>(
      NitriteConfig nitriteConfig, String collectionName,
      [EntityDecorator<T>? entityDecorator, String? key]) async {
    var store = nitriteConfig.getNitriteStore();

    validateRepositoryType<T>(nitriteConfig);

    var collectionNames = await store.collectionNames;
    if (collectionNames.contains(collectionName)) {
      throw ValidationException(
          'A collection with same entity name already exists');
    }

    var nitriteCollection = await _collectionFactory.getCollection(
        collectionName, nitriteConfig, false);
    var repository = _DefaultObjectRepository<T>(
        entityDecorator, nitriteCollection, nitriteConfig);

    // initialize
    await repository.initialize();

    _repositoryMap[collectionName] = repository;

    await _writeCatalog(store, collectionName, key);
    return repository;
  }

  Future<void> _writeCatalog(
      NitriteStore store, String collectionName, String? key) async {
    var storeCatalog = await store.getCatalog();
    var exists = await storeCatalog.hasEntry(collectionName);
    if (!exists) {
      if (key.isNullOrEmpty) {
        await storeCatalog.writeRepositoryEntry(collectionName);
      } else {
        await storeCatalog.writeKeyedRepositoryEntry(collectionName);
      }
    }
  }
}

class _DefaultObjectRepository<T> extends ObjectRepository<T> {
  final NitriteCollection _nitriteCollection;
  final NitriteConfig _nitriteConfig;
  final EntityDecorator<T>? _entityDecorator;
  late RepositoryOperations<T> _operations;

  _DefaultObjectRepository(
      this._entityDecorator, this._nitriteCollection, this._nitriteConfig);

  @override
  bool get isDropped => _nitriteCollection.isDropped;

  @override
  bool get isOpen => _nitriteCollection.isOpen;

  @override
  Future<int> get size => _nitriteCollection.size;

  @override
  NitriteCollection get documentCollection => _nitriteCollection;

  @override
  void addProcessor(Processor processor) {
    return _nitriteCollection.addProcessor(processor);
  }

  @override
  Future<void> createIndex(List<String> fields, [IndexOptions? indexOptions]) {
    return _nitriteCollection.createIndex(fields, indexOptions);
  }

  @override
  Future<void> rebuildIndex(List<String> fields) {
    return _nitriteCollection.rebuildIndex(fields);
  }

  @override
  Future<Iterable<IndexDescriptor>> listIndexes() {
    return _nitriteCollection.listIndexes();
  }

  @override
  Future<bool> hasIndex(List<String> fields) {
    return _nitriteCollection.hasIndex(fields);
  }

  @override
  Future<bool> isIndexing(List<String> fields) {
    return _nitriteCollection.isIndexing(fields);
  }

  @override
  Future<void> dropIndex(List<String> fields) {
    return _nitriteCollection.dropIndex(fields);
  }

  @override
  Future<void> dropAllIndices() {
    return _nitriteCollection.dropAllIndices();
  }

  @override
  Future<WriteResult> insertMany(List<T> elements) {
    elements.notNullOrEmpty('Element list is empty');
    elements.notContainsNull('A null object cannot be inserted');
    return _nitriteCollection.insertMany(_operations.toDocuments(elements));
  }

  @override
  Future<WriteResult> updateOne(T element, {bool insertIfAbsent = false}) {
    return update(_operations.createUniqueFilter(element), element,
        updateOptions(insertIfAbsent: insertIfAbsent, justOnce: true));
  }

  @override
  Future<WriteResult> update(Filter filter, T element,
      [UpdateOptions? updateOptions]) {
    var updateDocument = _operations.toDocument(element, true);
    if (updateOptions == null || !updateOptions.insertIfAbsent) {
      _operations.removeNitriteId(updateDocument);
    }

    return _nitriteCollection.update(
        _operations.asObjectFilter(filter), updateDocument, updateOptions);
  }

  @override
  Future<WriteResult> updateDocument(Filter filter, Document document,
      {bool justOnce = false}) {
    _operations.removeNitriteId(document);
    _operations.serializeFields(document);
    return _nitriteCollection.update(_operations.asObjectFilter(filter),
        document, updateOptions(justOnce: justOnce));
  }

  @override
  Future<WriteResult> removeOne(T element) {
    return remove(_operations.createUniqueFilter(element));
  }

  @override
  Future<WriteResult> remove(Filter filter, {bool justOne = false}) {
    return _nitriteCollection.remove(_operations.asObjectFilter(filter),
        justOne: justOne);
  }

  @override
  Future<void> clear() {
    return _nitriteCollection.clear();
  }

  @override
  Cursor<T> find({Filter? filter, FindOptions? findOptions}) {
    return _operations.find(filter, findOptions);
  }

  @override
  Future<T?> getById<I>(I id) async {
    try {
      var idFilter = _operations.createIdFilter<I>(id);
      var cursor = find(filter: idFilter);
      return await cursor.first;
    } catch (e) {
      throw InvalidIdException('No element found using the specified id',
          cause: e);
    }
  }

  @override
  Future<void> drop() {
    return _nitriteCollection.drop();
  }

  @override
  Future<void> close() {
    return _nitriteCollection.close();
  }

  @override
  NitriteStore<Config> getStore<Config extends StoreConfig>() {
    return _nitriteCollection.getStore();
  }

  @override
  void subscribe<L>(CollectionEventListener<L> listener) {
    return _nitriteCollection.subscribe(listener);
  }

  @override
  void unsubscribe<L>(CollectionEventListener<L> listener) {
    return _nitriteCollection.unsubscribe(listener);
  }

  @override
  Future<Attributes> getAttributes() {
    return _nitriteCollection.getAttributes();
  }

  @override
  Future<void> setAttributes(Attributes attributes) {
    return _nitriteCollection.setAttributes(attributes);
  }

  @override
  Type getType() {
    return T;
  }

  @override
  Future<void> initialize() {
    _operations = RepositoryOperations<T>(
        _entityDecorator, _nitriteCollection, _nitriteConfig);
    _operations.scanIndexes();
    return _operations.createIndices();
  }
}
