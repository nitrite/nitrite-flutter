import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:mutex/mutex.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/operations/collection_operations.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/transaction/tx.dart';
import 'package:quiver/core.dart';

class DefaultTransactionalCollection extends NitriteCollection {
  final NitriteCollection _primary;
  final TransactionContext _context;
  final Nitrite _nitrite;
  final ReadWriteMutex _mutex = ReadWriteMutex();
  final Map<int, StreamSubscription> _subscriptions = {};

  late String _collectionName;
  late NitriteMap<NitriteId, Document> _nitriteMap;
  late NitriteStore _nitriteStore;
  late CollectionOperations _collectionOperations;
  late bool _isDropped;
  late bool _isClosed;
  late EventBus _eventBus;

  DefaultTransactionalCollection(this._primary, this._context, this._nitrite);

  @override
  String get name => _collectionName;

  @override
  Future<bool> get isDropped async => _isDropped;

  @override
  Future<bool> get isOpen async {
    if (_nitriteStore.isClosed || _isDropped) {
      try {
        await close();
      } catch (e, stackTrace) {
        throw NitriteIOException('Failed to close collection',
            cause: e, stackTrace: stackTrace);
      }
      return false;
    }
    return true;
  }

  @override
  Future<int> get size async => (await (await find()).toList()).length;

  @override
  Future<WriteResult> insert(List<Document> documents) async {
    documents.notNullOrEmpty('Empty documents cannot be inserted');

    for (var document in documents) {
      // generate ids
      document.id;
    }

    var result = await _mutex.protectWrite(() async {
      await _checkOpened();
      return _collectionOperations.insert(documents);
    });

    var journalEntry = JournalEntry(
      changeType: ChangeType.insert,
      commit: () async {
        var stream = await _primary.insert(documents);
        stream.listen(blackHole);
      },
      rollback: () async {
        for (var value in documents) {
          var stream = await _primary.removeOne(value);
          stream.listen(blackHole);
        }
      },
    );

    _context.journal.add(journalEntry);
    return result;
  }

  @override
  Future<WriteResult> update(Filter filter, Document update,
      [UpdateOptions? updateOptions]) async {
    updateOptions ??= UpdateOptions();
    updateOptions.insertIfAbsent = false;
    updateOptions.justOnce = false;

    var result = await _mutex.protectWrite(() async {
      await _checkOpened();
      return _collectionOperations.update(filter, update, updateOptions!);
    });

    var documentList = <Document>[];

    var journalEntry = JournalEntry(
      changeType: ChangeType.update,
      commit: () async {
        // get the documents which are going to be updated in case of rollback
        var cursor = await _primary.find(filter);
        await for (var document in cursor) {
          if (updateOptions!.justOnce) {
            documentList.add(document);
            break;
          } else {
            documentList.add(document);
          }
        }

        // update the documents
        var stream = await _primary.update(filter, update, updateOptions!);
        stream.listen(blackHole);
      },
      rollback: () async {
        for (var value in documentList) {
          var stream = await _primary.removeOne(value);
          stream.listen(blackHole);

          stream = await _primary.insert([value]);
          stream.listen(blackHole);
        }
      },
    );

    _context.journal.add(journalEntry);
    return result;
  }

  @override
  Future<WriteResult> updateOne(Document document,
      [bool insertIfAbsent = false]) {
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

    var result = await _mutex.protectWrite(() async {
      await _checkOpened();
      return _collectionOperations.removeDocument(document);
    });

    Document? toRemove;
    var journalEntry = JournalEntry(
      changeType: ChangeType.remove,
      commit: () async {
        toRemove = await _primary.getById(document.id);
        var stream = await _primary.removeOne(document);
        stream.listen(blackHole);
      },
      rollback: () async {
        if (toRemove != null) {
          var stream = await _primary.insert([toRemove!]);
          stream.listen(blackHole);
        }
      },
    );
    _context.journal.add(journalEntry);
    return result;
  }

  @override
  Future<WriteResult> remove(Filter filter, [bool justOne = false]) async {
    if (filter == all && justOne) {
      throw InvalidOperationException(
          'Remove all cannot be combined with just once');
    }

    var result = await _mutex.protectWrite(() async {
      await _checkOpened();
      return _collectionOperations.removeByFilter(filter, justOne);
    });

    var documentList = <Document>[];
    var journalEntry = JournalEntry(
      changeType: ChangeType.remove,
      commit: () async {
        // get the documents which are going to be removed in case of rollback
        var cursor = await _primary.find(filter);
        await for (var document in cursor) {
          if (justOne) {
            documentList.add(document);
            break;
          } else {
            documentList.add(document);
          }
        }

        // remove the documents
        var stream = await _primary.remove(filter, justOne);
        stream.listen(blackHole);
      },
      rollback: () async {
        for (var value in documentList) {
          var stream = await _primary.insert([value]);
          stream.listen(blackHole);
        }
      },
    );
    _context.journal.add(journalEntry);
    return result;
  }

  @override
  Future<DocumentCursor> find([Filter? filter, FindOptions? findOptions]) {
    return _mutex.protectRead(() async {
      await _checkOpened();
      return _collectionOperations.find(filter, findOptions);
    });
  }

  @override
  Future<Document?> getById(NitriteId id) {
    return _mutex.protectRead(() async {
      await _checkOpened();
      return _collectionOperations.getById(id);
    });
  }

  @override
  Future<void> addProcessor(Processor processor) {
    return _mutex.protectWrite(() async {
      await _checkOpened();
      return _collectionOperations.addProcessor(processor);
    });
  }

  @override
  Future<void> createIndex(List<String> fields,
      [IndexOptions? indexOptions]) async {
    var fieldNames = Fields.withNames(fields);
    await _mutex.protectWrite(() async {
      await _checkOpened();
      if (indexOptions == null) {
        await _collectionOperations.createIndex(fieldNames, IndexType.unique);
      } else {
        await _collectionOperations.createIndex(
            fieldNames, indexOptions.indexType);
      }
    });

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

    var indexDescriptor = await _mutex.protectRead(() async {
      await _checkOpened();
      return _collectionOperations.findIndex(Fields.withNames(fields));
    });

    if (indexDescriptor == null) {
      throw IndexingException('$fields is not indexed');
    }

    if (await isIndexing(indexDescriptor.indexFields.fieldNames)) {
      throw IndexingException(
          'Indexing on fields $fields is currently running');
    }

    await _mutex.protectWrite(() async {
      await _checkOpened();
      await _collectionOperations.rebuildIndex(indexDescriptor);
    });

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
    return _mutex.protectRead(() async {
      await _checkOpened();
      return _collectionOperations.listIndexes();
    });
  }

  @override
  Future<bool> hasIndex(List<String> fields) async {
    return _mutex.protectRead(() async {
      await _checkOpened();
      return _collectionOperations.hasIndex(Fields.withNames(fields));
    });
  }

  @override
  Future<bool> isIndexing(List<String> fields) async {
    return _mutex.protectRead(() async {
      await _checkOpened();
      return _collectionOperations.isIndexing(Fields.withNames(fields));
    });
  }

  @override
  Future<void> dropIndex(List<String> fields) async {
    await _mutex.protectWrite(() async {
      await _checkOpened();
      await _collectionOperations.dropIndex(Fields.withNames(fields));
    });

    IndexDescriptor? indexDescriptor;
    var journalEntry = JournalEntry(
      changeType: ChangeType.dropIndex,
      commit: () async {
        var indexes = await _primary.listIndexes();

        // find the index descriptor to get the index type
        // which will be required during rollback
        for (var entry in indexes) {
          if (entry.indexFields == Fields.withNames(fields)) {
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
    await _mutex.protectWrite(() async {
      await _checkOpened();
      await _collectionOperations.dropAllIndices();
    });

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
              entry.indexFields.fieldNames, indexOptions(entry.indexType));
        }
      },
    );
    _context.journal.add(journalEntry);
  }

  @override
  Future<void> clear() async {
    await _mutex.protectWrite(() async {
      await _checkOpened();
      await _nitriteMap.clear();
    });

    var documentList = <Document>[];
    var journalEntry = JournalEntry(
      changeType: ChangeType.clear,
      commit: () async {
        var cursor = await _primary.find();
        await for (var document in cursor) {
          documentList.add(document);
        }
        await _primary.clear();
      },
      rollback: () async {
        var stream = await _primary.insert(documentList);
        stream.listen(blackHole);
      },
    );
    _context.journal.add(journalEntry);
  }

  @override
  Future<void> drop() async {
    await _mutex.protectWrite(() async {
      await _checkOpened();
      await _collectionOperations.dropCollection();
    });
    _isDropped = true;

    var documentList = <Document>[];
    var indexEntries = <IndexDescriptor>[];
    var journalEntry = JournalEntry(
      changeType: ChangeType.dropCollection,
      commit: () async {
        var cursor = await _primary.find();
        await for (var document in cursor) {
          documentList.add(document);
        }
        var indexes = await _primary.listIndexes();
        indexEntries.addAll(indexes);
        await _primary.drop();
      },
      rollback: () async {
        // re-create collection
        var collection = await _nitrite.getCollection(_collectionName);

        // re-create indexes
        for (var entry in indexEntries) {
          await collection.createIndex(
              entry.indexFields.fieldNames, indexOptions(entry.indexType));
        }

        // re-insert documents
        var stream = await collection.insert(documentList);
        stream.listen(blackHole);
      },
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
  Future<void> subscribe<T>(CollectionEventListener<T> listener) {
    return _mutex.protectWrite(() async {
      _checkOpened();
      var subscription =
          _eventBus.on<CollectionEventInfo<T>>().listen(listener);

      var hashCode = hash2(listener, T);
      _subscriptions[hashCode] = subscription;
    });
  }

  @override
  Future<void> unsubscribe<T>(CollectionEventListener<T> listener) {
    return _mutex.protectWrite(() async {
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
  Future<Attributes> getAttributes() {
    return _mutex.protectRead(() async {
      await _checkOpened();
      return _collectionOperations.getAttributes();
    });
  }

  @override
  Future<void> setAttributes(Attributes attributes) async {
    await _mutex.protectWrite(() async {
      await _checkOpened();
      await _collectionOperations.setAttributes(attributes);
    });

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

    _eventBus = EventBus();
    _collectionOperations = CollectionOperations(
        _collectionName, _nitriteMap, nitriteConfig, _eventBus);
  }

  Future<void> _checkOpened() async {
    if (_isClosed) {
      throw TransactionException('Collection is closed');
    }

    if (!await _primary.isOpen) {
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
