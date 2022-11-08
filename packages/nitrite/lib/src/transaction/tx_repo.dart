import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/repository/repository_operations.dart';

class DefaultTransactionalRepository<T> extends ObjectRepository<T> {
  final ObjectRepository<T> _primary;
  final NitriteCollection _backingCollection;
  final NitriteConfig _nitriteConfig;
  final EntityDecorator<T>? _entityDecorator;

  late RepositoryOperations<T> _operations;

  DefaultTransactionalRepository(this._primary, this._backingCollection,
      this._entityDecorator, this._nitriteConfig);

  @override
  Future<bool> get isDropped => _backingCollection.isDropped;

  @override
  Future<bool> get isOpen => _backingCollection.isOpen;

  @override
  Future<int> get size => _backingCollection.size;

  @override
  NitriteCollection? get documentCollection => _backingCollection;

  @override
  Future<void> addProcessor(Processor processor) {
    return _backingCollection.addProcessor(processor);
  }

  @override
  Future<void> createIndex(List<String> fields, [IndexOptions? indexOptions]) {
    return _backingCollection.createIndex(fields, indexOptions);
  }

  @override
  Future<void> rebuildIndex(List<String> fields) {
    return _backingCollection.rebuildIndex(fields);
  }

  @override
  Future<Iterable<IndexDescriptor>> listIndexes() {
    return _backingCollection.listIndexes();
  }

  @override
  Future<bool> hasIndex(List<String> fields) {
    return _backingCollection.hasIndex(fields);
  }

  @override
  Future<bool> isIndexing(List<String> fields) {
    return _backingCollection.isIndexing(fields);
  }

  @override
  Future<void> dropIndex(List<String> fields) {
    return _backingCollection.dropIndex(fields);
  }

  @override
  Future<void> dropAllIndices() {
    return _backingCollection.dropAllIndices();
  }

  @override
  Future<WriteResult> insert(List<T> elements) {
    elements.notNullOrEmpty("Elements cannot be empty");
    return _backingCollection.insert(_operations.toDocuments(elements));
  }

  @override
  Future<WriteResult> updateOne(T element, [bool insertIfAbsent = false]) {
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

    return _backingCollection.update(
        _operations.asObjectFilter(filter), updateDocument, updateOptions);
  }

  @override
  Future<WriteResult> updateDocument(Filter filter, Document document,
      [bool justOnce = false]) {
    _operations.removeNitriteId(document);
    _operations.serializeFields(document);

    return _backingCollection.update(_operations.asObjectFilter(filter),
        document, updateOptions(insertIfAbsent: false, justOnce: justOnce));
  }

  @override
  Future<WriteResult> removeOne(T element) {
    return remove(_operations.createUniqueFilter(element));
  }

  @override
  Future<WriteResult> remove(Filter filter, [bool justOne = false]) {
    return _backingCollection.remove(
        _operations.asObjectFilter(filter), justOne);
  }

  @override
  Future<void> clear() {
    return _backingCollection.clear();
  }

  @override
  Future<Cursor<T>> find({Filter? filter, FindOptions? findOptions}) {
    return _operations.find(filter, findOptions);
  }

  @override
  Future<T?> getById<I>(I id) async {
    var item = await _primary.getById(id);
    if (item == null) {
      var idFilter = _operations.createIdFilter(id);
      var cursor = await find(filter: idFilter);
      return cursor.first;
    }
    return item;
  }

  @override
  Future<void> drop() {
    return _backingCollection.drop();
  }

  @override
  Future<void> close() {
    return _backingCollection.close();
  }

  @override
  NitriteStore<Config> getStore<Config extends StoreConfig>() {
    return _backingCollection.getStore<Config>();
  }

  @override
  Future<void> subscribe<L>(CollectionEventListener<L> listener) {
    return _backingCollection.subscribe(listener);
  }

  @override
  Future<void> unsubscribe<L>(CollectionEventListener<L> listener) {
    return _backingCollection.unsubscribe(listener);
  }

  @override
  Future<Attributes> getAttributes() {
    return _backingCollection.getAttributes();
  }

  @override
  Future<void> setAttributes(Attributes attributes) {
    return _backingCollection.setAttributes(attributes);
  }

  @override
  Type getType() {
    return T;
  }

  @override
  Future<void> initialize() async {
    var nitriteMapper = _nitriteConfig.nitriteMapper;
    var operations = RepositoryOperations<T>(
        _entityDecorator, nitriteMapper, _backingCollection);
    await operations.createIndices();
  }
}
