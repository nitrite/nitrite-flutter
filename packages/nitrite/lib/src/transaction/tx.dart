import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/transaction/tx_store.dart';

/// Represents a transaction in Nitrite database. 
/// It provides methods to perform ACID operations on Nitrite database 
/// collections and repositories. 
/// 
/// A transaction can be committed or rolled back. Once a transaction is 
/// committed, all changes made during the transaction are persisted to 
/// the underlying store. If a transaction is rolled back, all changes 
/// made during the transaction are discarded.
/// 
/// NOTE: Certain operations are auto-committed in Nitrite database. Those
/// operations are not part of transaction and cannot be rolled back. 
/// The following operations are auto-committed:
/// 
/// * [NitriteCollection.createIndex]
/// * [NitriteCollection.rebuildIndex]
/// * [NitriteCollection.dropIndex]
/// * [NitriteCollection.dropAllIndices]
/// * [NitriteCollection.clear]
/// * [NitriteCollection.drop]
/// * [NitriteCollection.close]
/// * [ObjectRepository.createIndex]
/// * [ObjectRepository.rebuildIndex]
/// * [ObjectRepository.dropIndex]
/// * [ObjectRepository.dropAllIndices]
/// * [ObjectRepository.clear]
/// * [ObjectRepository.drop]
/// * [ObjectRepository.close]
abstract class Transaction {
  /// Gets the unique identifier of the transaction.
  String get id;

  /// Returns the current state of the transaction.
  TransactionState get state;

  /// Gets a [NitriteCollection] to perform ACID operations on it.
  Future<NitriteCollection> getCollection(String name);

  /// Gets an [ObjectRepository] to perform ACID operations on it.
  Future<ObjectRepository<T>> getRepository<T>(
      {EntityDecorator<T>? entityDecorator, String? key});

  /// Completes the transaction and commits the data to the underlying store.
  Future<void> commit();

  /// Rolls back the transaction, discarding any changes made during 
  /// the transaction.
  Future<void> rollback();

  /// Closes this transaction.
  Future<void> close();
}

/// An enumeration representing the possible states of a transaction.
enum TransactionState {
  /// The transaction is active.
  active,

  /// The transaction is partially committed.
  partiallyCommitted,

  /// The transaction is committed.
  committed,

  /// The transaction is closed.
  closed,

  /// The transaction is failed and rolled back.
  failed,

  /// The transaction is aborted.
  aborted
}

/// @nodoc
enum ChangeType { insert, update, remove, setAttributes }

/// @nodoc
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

/// @nodoc
typedef TxAction = Future<void> Function();

/// @nodoc
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

/// @nodoc
class UndoEntry {
  final String _collectionName;
  final TxAction _rollback;

  UndoEntry(this._collectionName, this._rollback);

  String get collectionName => _collectionName;
  TxAction get rollback => _rollback;
}
