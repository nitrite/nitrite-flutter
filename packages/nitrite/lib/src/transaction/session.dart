import 'dart:async';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/stack.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/transaction/tx.dart';
import 'package:nitrite/src/transaction/tx_collection.dart';
import 'package:nitrite/src/transaction/tx_repo.dart';
import 'package:nitrite/src/transaction/tx_store.dart';
import 'package:uuid/uuid.dart';

/// A session represents a transactional context for a Nitrite database.
/// It provides methods to create a new transaction.
///
/// A session should be closed after use to release any resources
/// associated with it.
///
/// If a session is closed and the transaction is not committed,
/// all opened transactions will get rolled back and all volatile
/// data gets discarded for the session.
class Session {
  final Nitrite _nitrite;
  final Map<String, Transaction> transactionMap = {};

  bool _active = true;

  Session(this._nitrite);

  /// Checks if the session is active.
  bool get isActive => _active;

  /// Begins a new transaction.
  Future<Transaction> beginTransaction() async {
    if (!_active) {
      throw TransactionException('Session is closed');
    }

    var tx = _NitriteTransaction(_nitrite);
    await tx.prepare();
    transactionMap[tx.id] = tx;
    return tx;
  }

  /// Executes a transaction with the given action.
  ///
  /// If the [action] completes successfully, the transaction is committed.
  /// If the [action] throws an exception, the transaction is rolled back
  /// unless the exception is of a type specified in [rollbackFor].
  /// If [rollbackFor] is empty, all exceptions will cause the transaction
  /// to be rolled back.
  ///
  /// Example usage:
  /// ```dart
  /// await db.executeTransaction((tx) async {
  ///   var txCol = await tx.getCollection('test');
  ///   var document = createDocument('firstName', 'John');
  ///   await txCol.insert(document);
  /// });
  /// ```
  Future<void> executeTransaction(Future<void> Function(Transaction tx) action,
      {List<Type> rollbackFor = const []}) async {
    if (!_active) {
      throw TransactionException('Session is closed');
    }

    var tx = await beginTransaction();
    try {
      await action(tx);
      await tx.commit();
    } catch (e) {
      if (rollbackFor.any((error) => e.runtimeType == error) ||
          rollbackFor.isEmpty) {
        await tx.rollback();
      } else {
        await tx.commit();
      }
      rethrow;
    } finally {
      await tx.close();
      transactionMap.remove(tx.id);
    }
  }

  /// Closes the session.
  ///
  /// If the session is closed and the transaction is not committed,
  /// all opened transactions will get rolled back and all volatile
  /// data gets discarded for the session.
  Future<void> close() async {
    _active = false;
    for (var tx in transactionMap.values) {
      if (tx.state != TransactionState.closed) {
        await tx.rollback();
      }
    }
  }
}

class _NitriteTransaction extends Transaction {
  final Nitrite _nitrite;
  final Map<String, TransactionContext> _contextMap = {};
  final Map<String, NitriteCollection> _collectionRegistry = {};
  final Map<String, ObjectRepository<dynamic>> _repositoryRegistry = {};
  final Map<String, Stack<UndoEntry>> _undoRegistry = {};

  late TransactionStore _transactionStore;
  late TransactionConfig _transactionConfig;
  late String _id;
  late TransactionState _state;

  _NitriteTransaction(this._nitrite);

  @override
  TransactionState get state => _state;

  @override
  String get id => _id;

  @override
  Future<NitriteCollection> getCollection(String name) async {
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
    var txCollection = DefaultTransactionalCollection(primary, txContext);
    await txCollection.initialize();

    _collectionRegistry[name] = txCollection;
    _contextMap[name] = txContext;
    return txCollection;
  }

  @override
  Future<ObjectRepository<T>> getRepository<T>(
      {EntityDecorator<T>? entityDecorator, String? key}) async {
    _checkState();

    var name = entityDecorator == null
        ? findRepositoryNameByType<T>(_transactionConfig.nitriteMapper, key)
        : findRepositoryNameByDecorator(entityDecorator, key);

    if (_repositoryRegistry.containsKey(name)) {
      return _repositoryRegistry[name]! as ObjectRepository<T>;
    }

    ObjectRepository<T> primary;
    if (await _nitrite.hasRepository<T>(
        entityDecorator: entityDecorator, key: key)) {
      primary = await _nitrite.getRepository<T>(
          entityDecorator: entityDecorator, key: key);
    } else {
      throw TransactionException(
          'Repository of type ${T.runtimeType} does not exist');
    }

    var txMap = await _transactionStore.openMap<NitriteId, Document>(name);
    var txContext = TransactionContext(name, txMap, _transactionConfig);
    var primaryCollection = primary.documentCollection;
    var backingCollection =
        DefaultTransactionalCollection(primaryCollection, txContext);
    await backingCollection.initialize();

    var txRepository = DefaultTransactionalRepository<T>(
        primary, backingCollection, entityDecorator, _transactionConfig);
    await txRepository.initialize();

    _repositoryRegistry[name] = txRepository;
    _contextMap[name] = txContext;
    return txRepository;
  }

  @override
  Future<void> commit() async {
    _checkState();
    _state = TransactionState.partiallyCommitted;

    for (var contextEntry in _contextMap.entries) {
      var collectionName = contextEntry.key;
      var txContext = contextEntry.value;

      var undoLog = _undoRegistry.containsKey(collectionName)
          ? _undoRegistry[collectionName]
          : Stack<UndoEntry>();

      try {
        var commitLog = txContext.journal;
        while (commitLog.isNotEmpty) {
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
    }

    _state = TransactionState.committed;
    await close();
  }

  @override
  Future<void> rollback() async {
    _state = TransactionState.aborted;

    for (var entry in _undoRegistry.entries) {
      var undoLog = entry.value;

      while (undoLog.isNotEmpty) {
        var undoEntry = undoLog.pop();
        await undoEntry.rollback();
      }
    }

    await close();
  }

  @override
  Future<void> close() async {
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
  }

  Future<void> prepare() async {
    _id = Uuid().v4();

    var nitriteStore = _nitrite.getStore();
    var nitriteConfig = _nitrite.config;
    _transactionConfig = TransactionConfig(nitriteConfig);
    _transactionConfig.loadModule(module([TransactionStore(nitriteStore)]));

    await _transactionConfig.autoConfigure();
    await _transactionConfig.initialize();
    _transactionStore =
        _transactionConfig.getNitriteStore() as TransactionStore;
    _state = TransactionState.active;
  }

  void _checkState() {
    if (_state != TransactionState.active) {
      throw TransactionException('Transaction is not active');
    }
  }
}
