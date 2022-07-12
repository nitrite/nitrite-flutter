import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/transaction/tx_store.dart';

/// Represents an ACID transaction on nitrite database.
abstract class Transaction {
  /// Returns the id of the transaction.
  String get id;

  /// Returns the state of the transaction.
  TransactionState get state;

  /// Gets a [NitriteCollection] to perform ACID operations on it.
  Future<NitriteCollection> getCollection(String name);

  /// Gets an [ObjectRepository] to perform ACID operations on it.
  Future<ObjectRepository<T>> getRepository<T>([String? key]);

  /// Completes the transaction and commits the data to the underlying store.
  Future<void> commit();

  /// Rolls back the changes.
  Future<void> rollback();

  /// Closes this transaction.
  Future<void> close();
}

/// The transaction state.
enum TransactionState {
  active,
  partiallyCommitted,
  committed,
  closed,
  failed,
  aborted
}

enum ChangeType {
  insert,
  update,
  remove,
  clear,
  createIndex,
  rebuildIndex,
  dropIndex,
  dropAllIndexes,
  dropCollection,
  setAttributes
}

class TransactionContext {
  final String _collectionName;
  final Queue<JournalEntry> _journal = Queue();
  final NitriteMap<NitriteId, Document> _nitriteMap;
  final TransactionConfig _config;
  bool active = true;

  TransactionContext(this._collectionName, this._nitriteMap, this._config);

  String get collectionName => _collectionName;
  Queue<JournalEntry> get journal => _journal;
  NitriteMap<NitriteId, Document> get nitriteMap => _nitriteMap;
  TransactionConfig get config => _config;

  Future<void> close() async {
    _journal.clear();
    await _nitriteMap.clear();
    await _nitriteMap.close();
    active = false;
  }
}

typedef TxAction = Future<void> Function();

class JournalEntry {
  final ChangeType _changeType;
  final TxAction _commit;
  final TxAction _rollback;

  JournalEntry(
      {required ChangeType changeType,
      required TxAction commit,
      required TxAction rollback})
      : _changeType = changeType,
        _commit = commit,
        _rollback = rollback;

  ChangeType get changeType => _changeType;
  TxAction get commit => _commit;
  TxAction get rollback => _rollback;
}

class UndoEntry {
  final String _collectionName;
  final TxAction _rollback;

  UndoEntry(this._collectionName, this._rollback);

  String get collectionName => _collectionName;
  TxAction get rollback => _rollback;
}
