import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/operations/collection_operations.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/transaction/tx.dart';
import 'package:quiver/core.dart';

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
  Future<int> get size async => (await (await find()).toList()).length;

  @override
  Future<WriteResult> insert(List<Document> documents) async {
    documents.notNullOrEmpty('Empty documents cannot be inserted');

    for (var document in documents) {
      // generate ids
      document.id;
    }

    await _checkOpened();
    var result = await _collectionOperations.insert(documents);

    var journalEntry = JournalEntry(
      changeType: ChangeType.insert,
      commit: () async {
        await _primary.insert(documents);
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

    await _checkOpened();
    var result =
        await _collectionOperations.update(filter, update, updateOptions);

    var documentList = <Document>[];

    var journalEntry = JournalEntry(
      changeType: ChangeType.update,
      commit: () async {
        // get the documents which are going to be updated in case of rollback
        var cursor = await _primary.find(filter: filter);
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
          await _primary.insert([value]);
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

    await _checkOpened();
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
          await _primary.insert([toRemove!]);
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

    await _checkOpened();
    var result = await _collectionOperations.removeByFilter(filter, justOne);

    var documentList = <Document>[];
    var journalEntry = JournalEntry(
      changeType: ChangeType.remove,
      commit: () async {
        // get the documents which are going to be removed in case of rollback
        var cursor = await _primary.find(filter: filter);
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
        for (var value in documentList) {
          await _primary.insert([value]);
        }
      },
    );
    _context.journal.add(journalEntry);
    return result;
  }

  @override
  Future<DocumentCursor> find(
      {Filter? filter, FindOptions? findOptions}) async {
    await _checkOpened();
    return _collectionOperations.find(filter, findOptions);
  }

  @override
  Future<Document?> getById(NitriteId id) async {
    await _checkOpened();
    return _collectionOperations.getById(id);
  }

  @override
  Future<void> addProcessor(Processor processor) async {
    await _checkOpened();
    return _collectionOperations.addProcessor(processor);
  }

  @override
  Future<void> createIndex(List<String> fields,
      [IndexOptions? indexOptions]) async {
    var fieldNames = Fields.withNames(fields);
    await _checkOpened();
    if (indexOptions == null) {
      await _collectionOperations.createIndex(fieldNames, IndexType.unique);
    } else {
      await _collectionOperations.createIndex(
          fieldNames, indexOptions.indexType);
    }

    var journalEntry = JournalEntry(
      changeType: ChangeType.createIndex,
      commit: () async {
        await _primary.createIndex(fields, indexOptions);
      },
      rollback: () async {
        await _primary.dropIndex(fields);
      },
    );
    _context.journal.add(journalEntry);
  }

  @override
  Future<void> rebuildIndex(List<String> fields) async {
    fields.notNullOrEmpty('Fields cannot be empty');

    await _checkOpened();
    var indexDescriptor =
        await _collectionOperations.findIndex(Fields.withNames(fields));

    if (indexDescriptor == null) {
      throw IndexingException('$fields is not indexed');
    }

    if (await isIndexing(indexDescriptor.fields.fieldNames)) {
      throw IndexingException(
          'Indexing on fields $fields is currently running');
    }

    await _checkOpened();
    await _collectionOperations.rebuildIndex(indexDescriptor);

    var journalEntry = JournalEntry(
      changeType: ChangeType.rebuildIndex,
      commit: () async {
        await _primary.rebuildIndex(fields);
      },
      rollback: () async {
        await _primary.rebuildIndex(fields);
      },
    );
    _context.journal.add(journalEntry);
  }

  @override
  Future<Iterable<IndexDescriptor>> listIndexes() async {
    await _checkOpened();
    return _collectionOperations.listIndexes();
  }

  @override
  Future<bool> hasIndex(List<String> fields) async {
    await _checkOpened();
    return _collectionOperations.hasIndex(Fields.withNames(fields));
  }

  @override
  Future<bool> isIndexing(List<String> fields) async {
    await _checkOpened();
    return _collectionOperations.isIndexing(Fields.withNames(fields));
  }

  @override
  Future<void> dropIndex(List<String> fields) async {
    await _checkOpened();
    await _collectionOperations.dropIndex(Fields.withNames(fields));

    IndexDescriptor? indexDescriptor;
    var journalEntry = JournalEntry(
      changeType: ChangeType.dropIndex,
      commit: () async {
        var indexes = await _primary.listIndexes();

        // find the index descriptor to get the index type
        // which will be required during rollback
        for (var entry in indexes) {
          if (entry.fields == Fields.withNames(fields)) {
            indexDescriptor = entry;
            break;
          }
        }

        await _primary.dropIndex(fields);
      },
      rollback: () async {
        if (indexDescriptor != null) {
          await _primary.createIndex(
              fields, indexOptions(indexDescriptor!.indexType));
        }
      },
    );
    _context.journal.add(journalEntry);
  }

  @override
  Future<void> dropAllIndices() async {
    await _checkOpened();
    await _collectionOperations.dropAllIndices();

    var indexEntries = <IndexDescriptor>[];
    var journalEntry = JournalEntry(
      changeType: ChangeType.dropAllIndexes,
      commit: () async {
        var indexes = await _primary.listIndexes();
        indexEntries.addAll(indexes);
        await _primary.dropAllIndices();
      },
      rollback: () async {
        for (var entry in indexEntries) {
          await _primary.createIndex(
              entry.fields.fieldNames, indexOptions(entry.indexType));
        }
      },
    );
    _context.journal.add(journalEntry);
  }

  @override
  Future<void> clear() async {
    await _checkOpened();
    await _collectionOperations.clear();

    var journalEntry = JournalEntry(
      changeType: ChangeType.clear,
      commit: () async {
        await _primary.clear();
      },
      rollback: () async {}, // can't rollback clear
    );
    _context.journal.add(journalEntry);
  }

  @override
  Future<void> drop() async {
    await _checkOpened();
    await _collectionOperations.dropCollection();
    _isDropped = true;

    var journalEntry = JournalEntry(
      changeType: ChangeType.dropCollection,
      commit: () async {
        await _primary.drop();
      },
      rollback: () async {}, // can't rollback drop
    );

    _context.journal.add(journalEntry);
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
    await _checkOpened();
    return _collectionOperations.getAttributes();
  }

  @override
  Future<void> setAttributes(Attributes attributes) async {
    await _checkOpened();
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

  Future<void> _checkOpened() async {
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
