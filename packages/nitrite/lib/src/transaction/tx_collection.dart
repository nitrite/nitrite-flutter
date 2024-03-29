import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/operations/collection_operations.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/transaction/tx.dart';
import 'package:quiver/core.dart';

/// @nodoc
class DefaultTransactionalCollection extends NitriteCollection {
  final NitriteCollection _primary;
  final TransactionContext _context;
  final Map<int, StreamSubscription> _subscriptions = {};

  late String _collectionName;
  late NitriteMap<NitriteId, Document> _nitriteMap;
  late NitriteStore _nitriteStore;
  late CollectionOperations _collectionOperations;
  late bool _isDropped;
  late bool _isClosed;
  late EventBus _eventBus;

  DefaultTransactionalCollection(this._primary, this._context);

  @override
  String get name => _collectionName;

  @override
  bool get isDropped => _isDropped;

  @override
  bool get isOpen => !_nitriteStore.isClosed && !_isDropped;

  @override
  Future<int> get size async => (await (find()).toList()).length;

  @override
  Future<WriteResult> insertMany(List<Document> documents) async {
    documents.notNullOrEmpty('Empty documents cannot be inserted');

    for (var document in documents) {
      // generate ids
      document.id;
    }

    _checkOpened();
    var result = await _collectionOperations.insert(documents);

    var journalEntry = JournalEntry(
      changeType: ChangeType.insert,
      commit: () async {
        await _primary.insertMany(documents);
      },
      rollback: () async {
        for (var value in documents) {
          await _primary.removeOne(value);
        }
      },
    );

    _context.journal.add(journalEntry);
    return result;
  }

  @override
  Future<WriteResult> update(Filter filter, Document update,
      [UpdateOptions? updateOptions]) async {
    if (updateOptions == null) {
      updateOptions = UpdateOptions();
      updateOptions.insertIfAbsent = false;
      updateOptions.justOnce = false;
    }

    _checkOpened();
    var result =
        await _collectionOperations.update(filter, update, updateOptions);

    var documentList = <Document>[];

    var journalEntry = JournalEntry(
      changeType: ChangeType.update,
      commit: () async {
        // get the documents which are going to be updated in case of rollback
        var cursor = _primary.find(filter: filter);
        await for (var document in cursor) {
          if (updateOptions!.justOnce) {
            documentList.add(document);
            break;
          } else {
            documentList.add(document);
          }
        }

        // update the documents
        await _primary.update(filter, update, updateOptions!);
      },
      rollback: () async {
        for (var value in documentList) {
          await _primary.removeOne(value);
          await _primary.insert(value);
        }
      },
    );

    _context.journal.add(journalEntry);
    return result;
  }

  @override
  Future<WriteResult> updateOne(Document document,
      {bool insertIfAbsent = false}) {
    if (insertIfAbsent) {
      return update(createUniqueFilter(document), document,
          UpdateOptions(insertIfAbsent: true));
    } else {
      if (document.hasId) {
        return update(createUniqueFilter(document), document,
            UpdateOptions(insertIfAbsent: false));
      } else {
        throw NotIdentifiableException('Update operation failed as no id value'
            ' found for the document');
      }
    }
  }

  @override
  Future<WriteResult> removeOne(Document document) async {
    if (!document.hasId) {
      throw NotIdentifiableException('Remove operation failed as no id value'
          ' found for the document');
    }

    _checkOpened();
    var result = await _collectionOperations.removeDocument(document);

    Document? toRemove;
    var journalEntry = JournalEntry(
      changeType: ChangeType.remove,
      commit: () async {
        toRemove = await _primary.getById(document.id);
        await _primary.removeOne(document);
      },
      rollback: () async {
        if (toRemove != null) {
          await _primary.insert(toRemove!);
        }
      },
    );
    _context.journal.add(journalEntry);
    return result;
  }

  @override
  Future<WriteResult> remove(Filter filter, {bool justOne = false}) async {
    if (filter == all && justOne) {
      throw InvalidOperationException(
          'Remove all cannot be combined with just once');
    }

    _checkOpened();
    var result = await _collectionOperations.removeByFilter(filter, justOne);

    var documentList = <Document>[];
    var journalEntry = JournalEntry(
      changeType: ChangeType.remove,
      commit: () async {
        // get the documents which are going to be removed in case of rollback
        var cursor = _primary.find(filter: filter);
        await for (var document in cursor) {
          if (justOne) {
            documentList.add(document);
            break;
          } else {
            documentList.add(document);
          }
        }

        // remove the documents
        await _primary.remove(filter, justOne: justOne);
      },
      rollback: () async {
        await _primary.insertMany(documentList);
      },
    );
    _context.journal.add(journalEntry);
    return result;
  }

  @override
  DocumentCursor find({Filter? filter, FindOptions? findOptions}) {
    _checkOpened();
    return _collectionOperations.find(filter, findOptions);
  }

  @override
  Future<Document?> getById(NitriteId id) async {
    _checkOpened();
    return _collectionOperations.getById(id);
  }

  @override
  void addProcessor(Processor processor) {
    _checkOpened();
    return _collectionOperations.addProcessor(processor);
  }

  @override
  Future<void> createIndex(List<String> fields,
      [IndexOptions? indexOptions]) async {
    _checkOpened();
    await _primary.createIndex(fields, indexOptions);
  }

  @override
  Future<void> rebuildIndex(List<String> fields) async {
    _checkOpened();
    await _primary.rebuildIndex(fields);
  }

  @override
  Future<Iterable<IndexDescriptor>> listIndexes() async {
    _checkOpened();
    return _primary.listIndexes();
  }

  @override
  Future<bool> hasIndex(List<String> fields) async {
    _checkOpened();
    return _primary.hasIndex(fields);
  }

  @override
  Future<bool> isIndexing(List<String> fields) async {
    _checkOpened();
    return _primary.isIndexing(fields);
  }

  @override
  Future<void> dropIndex(List<String> fields) async {
    _checkOpened();
    await _primary.dropIndex(fields);
  }

  @override
  Future<void> dropAllIndices() async {
    _checkOpened();
    await _primary.dropAllIndices();
    await _collectionOperations.initialize();
  }

  @override
  Future<void> clear() async {
    _checkOpened();
    await _primary.clear();
  }

  @override
  Future<void> drop() async {
    _checkOpened();
    await _primary.drop();
    await close();
    _isDropped = true;
  }

  @override
  Future<void> close() async {
    await _collectionOperations.close();
    _eventBus.destroy();
    _isClosed = true;
  }

  @override
  NitriteStore<Config> getStore<Config extends StoreConfig>() {
    return _nitriteStore as NitriteStore<Config>;
  }

  @override
  void subscribe<T>(CollectionEventListener<T> listener) {
    var subscription = _eventBus.on<CollectionEventInfo<T>>().listen(listener);

    var hashCode = hash2(listener, T);
    _subscriptions[hashCode] = subscription;
  }

  @override
  void unsubscribe<T>(CollectionEventListener<T> listener) {
    var hashCode = hash2(listener, T);
    var subscription = _subscriptions[hashCode];
    if (subscription != null) {
      subscription.cancel();
      _subscriptions.remove(hashCode);
    }
  }

  @override
  Future<Attributes> getAttributes() async {
    _checkOpened();
    return _collectionOperations.getAttributes();
  }

  @override
  Future<void> setAttributes(Attributes attributes) async {
    _checkOpened();
    await _collectionOperations.setAttributes(attributes);

    Attributes? original;
    var journalEntry = JournalEntry(
      changeType: ChangeType.setAttributes,
      commit: () async {
        original = await _primary.getAttributes();
        await _primary.setAttributes(attributes);
      },
      rollback: () async {
        if (original != null) {
          await _primary.setAttributes(original!);
        }
      },
    );
    _context.journal.add(journalEntry);
  }

  @override
  Future<void> initialize() async {
    _collectionName = _context.collectionName;
    _nitriteMap = _context.nitriteMap;
    var nitriteConfig = _context.config;
    _nitriteStore = nitriteConfig.getNitriteStore();
    _isDropped = false;
    _isClosed = false;

    _eventBus = EventBus();
    _collectionOperations = CollectionOperations(
        _collectionName, _nitriteMap, nitriteConfig, _eventBus);

    await _collectionOperations.initialize();
  }

  void _checkOpened() {
    if (_isClosed) {
      throw TransactionException('Collection is closed');
    }

    if (!_primary.isOpen) {
      throw TransactionException('Store is closed');
    }

    if (_isDropped) {
      throw TransactionException('Collection is dropped');
    }

    if (!_context.active) {
      throw TransactionException('Transaction is not active');
    }
  }
}
