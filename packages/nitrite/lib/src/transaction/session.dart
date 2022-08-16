import 'dart:async';

import 'package:mutex/mutex.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/concurrent/lock_service.dart';
import 'package:nitrite/src/common/stack.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/transaction/tx.dart';
import 'package:nitrite/src/transaction/tx_collection.dart';
import 'package:nitrite/src/transaction/tx_repo.dart';
import 'package:nitrite/src/transaction/tx_store.dart';
import 'package:uuid/uuid.dart';

class Session {
  final Nitrite _nitrite;
  final LockService _lockService;
  final Map<String, Transaction> transactionMap = {};

  bool _active = true;

  Session(this._nitrite, this._lockService);

  Future<void> transaction(Future<void> Function(Transaction tx) action) {
    if (!_active) {
      throw TransactionException('Session is closed');
    }

    return runZoned(() async {
      var tx = _NitriteTransaction(_nitrite, _lockService);
      await tx.prepare();
      transactionMap[tx.id] = tx;
      try {
        await action(tx);
      } catch (e, stackTrace) {
        await tx.rollback();
        throw TransactionException('Transaction rolled back',
            cause: e, stackTrace: stackTrace);
      } finally {
        await tx.close();
        transactionMap.remove(tx.id);
      }
    });
  }

  Future<void> close() async {
    _active = false;
    var futures = <Future<void>>[];
    for (var tx in transactionMap.values) {
      if (tx.state != TransactionState.closed) {
        futures.add(tx.rollback());
      }
    }
    await Future.wait(futures);
  }
}

class _NitriteTransaction extends Transaction {
  final Nitrite _nitrite;
  final LockService _lockService;
  final Map<String, TransactionContext> _contextMap = {};
  final Map<String, NitriteCollection> _collectionRegistry = {};
  final Map<String, ObjectRepository<dynamic>> _repositoryRegistry = {};
  final Map<String, Stack<UndoEntry>> _undoRegistry = {};
  final Mutex _mutex = Mutex();

  late TransactionStore _transactionStore;
  late TransactionConfig _transactionConfig;
  late String _id;
  late TransactionState _state;

  _NitriteTransaction(this._nitrite, this._lockService);

  @override
  TransactionState get state => _state;

  @override
  String get id => _id;

  @override
  Future<NitriteCollection> getCollection(String name) async {
    return _mutex.protect(() async {
      _checkState();

      if (_collectionRegistry.containsKey(name)) {
        return _collectionRegistry[name]!;
      }

      NitriteCollection primary;
      if (await _nitrite.hasCollection(name)) {
        primary = await _nitrite.getCollection(name);
      } else {
        throw TransactionException('Collection $name does not exist');
      }

      var txMap = await _transactionStore.openMap<NitriteId, Document>(name);
      var txContext = TransactionContext(name, txMap, _transactionConfig);
      var txCollection =
          DefaultTransactionalCollection(primary, txContext);
      await txCollection.initialize();

      _collectionRegistry[name] = txCollection;
      _contextMap[name] = txContext;
      return txCollection;
    });
  }

  @override
  Future<ObjectRepository<T>> getRepository<T>([String? key]) async {
    return _mutex.protect(() async {
      _checkState();

      var name =
          findRepositoryNameByType<T>(_transactionConfig.nitriteMapper, key);
      if (_repositoryRegistry.containsKey(name)) {
        return _repositoryRegistry[name]! as ObjectRepository<T>;
      }

      ObjectRepository<T> primary;
      if (await _nitrite.hasRepository(name)) {
        primary = await _nitrite.getRepository<T>(key);
      } else {
        throw TransactionException(
            'Repository of type ${T.runtimeType} does not exist');
      }

      var txMap = await _transactionStore.openMap<NitriteId, Document>(name);
      var txContext = TransactionContext(name, txMap, _transactionConfig);
      var primaryCollection = primary.documentCollection;
      var backingCollection = DefaultTransactionalCollection(
          primaryCollection!, txContext);
      await backingCollection.initialize();

      var txRepository = DefaultTransactionalRepository<T>(
          primary, backingCollection, _transactionConfig);
      await txRepository.initialize();

      _repositoryRegistry[name] = txRepository;
      _contextMap[name] = txContext;
      return txRepository;
    });
  }

  @override
  Future<void> commit() {
    return _mutex.protect(() async {
      _checkState();
      _state = TransactionState.partiallyCommitted;

      for (var contextEntry in _contextMap.entries) {
        var collectionName = contextEntry.key;
        var txContext = contextEntry.value;

        var undoLog = _undoRegistry.containsKey(collectionName)
            ? _undoRegistry[collectionName]
            : Stack<UndoEntry>();

        var lock = await _lockService.getLock(collectionName);
        return lock.protectWrite(() async {
          try {
            var commitLog = txContext.journal;
            for (var i = 0; i < commitLog.length; i++) {
              var entry = commitLog.removeFirst();
              var commitCommand = entry.commit;
              try {
                await commitCommand();
              } finally {
                var undoEntry = UndoEntry(collectionName, entry.rollback);
                undoLog!.push(undoEntry);
              }
            }
          } on TransactionException {
            _state = TransactionState.failed;
            rethrow;
          } catch (e, stackTrace) {
            _state = TransactionState.failed;
            throw TransactionException('Error committing transaction',
                cause: e, stackTrace: stackTrace);
          } finally {
            _undoRegistry[collectionName] = undoLog!;
            txContext.active = false;
          }
        });
      }

      _state = TransactionState.committed;
      await close();
    });
  }

  @override
  Future<void> rollback() {
    return _mutex.protect(() async {
      _state = TransactionState.aborted;

      for (var entry in _undoRegistry.entries) {
        var collectionName = entry.key;
        var undoLog = entry.value;

        var lock = await _lockService.getLock(collectionName);
        return lock.protectWrite(() async {
          for (var i = 0; i < undoLog.length; i++) {
            var undoEntry = undoLog.pop();
            await undoEntry.rollback();
          }
        });
      }

      await close();
    });
  }

  @override
  Future<void> close() async {
    return _mutex.protect(() async {
      try {
        _state = TransactionState.closed;
        for (var contextEntry in _contextMap.entries) {
          var txContext = contextEntry.value;
          txContext.active = false;
        }

        _contextMap.clear();
        _collectionRegistry.clear();
        _repositoryRegistry.clear();
        _undoRegistry.clear();
        await _transactionStore.close();
        await _transactionConfig.close();
      } catch (e, stackTrace) {
        throw TransactionException('Error closing transaction',
            cause: e, stackTrace: stackTrace);
      }
    });
  }

  Future<void> prepare() async {
    _id = Uuid().v4();

    var nitriteStore = _nitrite.getStore();
    var nitriteConfig = _nitrite.config;
    var txConfig = TransactionConfig(nitriteConfig);
    await txConfig
        .loadModule(NitriteModule.module([TransactionStore(nitriteStore)]));

    await txConfig.autoConfigure();
    await txConfig.initialize();
    _transactionStore = txConfig.getNitriteStore() as TransactionStore;
    _state = TransactionState.active;
  }

  void _checkState() {
    if (_state != TransactionState.active) {
      throw TransactionException('Transaction is not active');
    }
  }
}
