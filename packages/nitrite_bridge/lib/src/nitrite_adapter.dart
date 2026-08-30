import 'dart:typed_data';

import 'package:dbinspect_bridge/dbinspect_bridge.dart';
// `WriteResult` is a name both packages use: Nitrite's is the ids a write
// touched, the core's is what the wire carries. Only the core's is named here.
import 'package:nitrite/nitrite.dart' hide WriteResult;

import 'filter_dsl.dart';

/// Inspects a running Nitrite database.
///
/// The bridge core — protocol, pairing, transport, release guard — is in
/// `dbinspect_bridge` and knows about no database at all. This adapter is the
/// only part that knows about Nitrite, so inspecting a SQLite or Drift database
/// pulls in none of it.
///
/// ```dart
/// final bridge = await startBridge(
///   appName: 'my_app',
///   adapters: [NitriteAdapter(db, id: 'main', displayName: 'app data')],
/// );
/// ```
///
/// **Collections are discovered; repositories are handed in.** Nitrite opens an
/// [ObjectRepository] by Dart type, and a name off the wire is not a type —
/// there is no `getRepository('org.example.Order')` to call, and the
/// entity-name-to-type mapping lives in the embedding application's generated
/// code rather than in the store. So the developer passes the repositories they
/// want inspected, the same way a Hive adapter is passed its boxes. A
/// repository that was not passed in is not listed, rather than listed and
/// unopenable.
class NitriteAdapter extends BridgeAdapter {
  NitriteAdapter(
    this._db, {
    required this.id,
    required this.displayName,
    List<ObjectRepository<dynamic>> repositories = const [],
    this.sampleSize = 50,
    bool allowRegex = false,
    bool allowWrite = false,
    bool allowSnapshot = false,
  })  : _repositories = repositories,
        _allowRegex = allowRegex,
        _transaction = null,
        _capabilities = AdapterCapabilities(
          query: QueryConsole.filter,
          // Nitrite's own collection-level subscription, so a write from
          // anywhere in this process is seen — not only this bridge's own.
          watch: true,
          watchScope: WatchScope.engine,
          // Off unless the embedding developer turned it on for this adapter
          // (threat model rule 5).
          edit: allowWrite,
          // Not an opt-in (`docs/PROTOCOL.md` §3.1): Nitrite's transaction is
          // implemented above the store, so it is available on every engine
          // this adapter can be pointed at — Hive and in-memory alike.
          // `allowWrite` is the permission; this reports what the engine can
          // undo.
          transactions: allowWrite,
          snapshot: allowSnapshot,
          // Not an opt-in: `queryPage` already showed the first 64 KB of this
          // very cell, and `docs/PROTOCOL.md` §2 has always promised the rest
          // on request. A document is addressed by `_id`, which every row has.
          blob: true,
          filterOps: [
            ...nitriteFilterOps,
            if (allowRegex) nitriteRegexOp,
          ],
        );

  /// The transactional twin of [parent], resolving stores through
  /// [transaction].
  ///
  /// Every capability but `transactions` is carried over: a gate that changed
  /// inside a transaction would be a second, invisible permission model. That
  /// one drops, because Nitrite does not nest one.
  NitriteAdapter._inTransaction(NitriteAdapter parent, Transaction transaction)
      : _db = parent._db,
        _repositories = parent._repositories,
        _allowRegex = parent._allowRegex,
        _transaction = transaction,
        sampleSize = parent.sampleSize,
        id = parent.id,
        displayName = parent.displayName,
        _capabilities = AdapterCapabilities(
          query: parent._capabilities.query,
          watch: parent._capabilities.watch,
          watchScope: parent._capabilities.watchScope,
          edit: parent._capabilities.edit,
          transactions: false,
          snapshot: parent._capabilities.snapshot,
          blob: parent._capabilities.blob,
          filterOps: parent._capabilities.filterOps,
        );

  final Nitrite _db;
  final List<ObjectRepository<dynamic>> _repositories;
  final AdapterCapabilities _capabilities;
  final bool _allowRegex;

  /// The open transaction this adapter is scoped to, or null on the one that is
  /// not. See [beginTransaction].
  final Transaction? _transaction;

  /// How many documents `getSchema` reads before answering. The schema is a
  /// sample, never a guarantee, and says so on the wire.
  final int sampleSize;

  @override
  final String id;

  @override
  final String displayName;

  @override
  String get kind => 'nitrite';

  /// `hive`, `memory`, or whatever the store calls itself — taken from
  /// [NitriteStore.storeVersion], which reads `Hive/2.2.3` or `InMemory/2.0.4`.
  @override
  String? get engine {
    final name = _db.getStore<StoreConfig>().storeVersion.split('/').first;
    return name.toLowerCase() == 'inmemory' ? 'memory' : name.toLowerCase();
  }

  @override
  AdapterCapabilities get capabilities => _capabilities;

  /// Opens one Nitrite transaction (`docs/PROTOCOL.md` §3.1).
  ///
  /// Nitrite's transaction lives above the storage engine — a transactional
  /// store buffers the writes and a journal replays them on commit — so this
  /// works identically on Hive and in memory. Nothing here re-implements either
  /// half; the session and the transaction are the engine's own.
  ///
  /// The session is held alongside the transaction and closed by whichever of
  /// commit or rollback runs, because closing a session rolls back anything
  /// still open in it — which is what makes the ending safe on both paths.
  @override
  Future<AdapterTransaction> beginTransaction() async {
    final session = _db.createSession();
    final Transaction started;
    try {
      started = await session.beginTransaction();
    } on Object catch (failure) {
      await session.close();
      throw BridgeException(
        BridgeErrorKind.adapter,
        'the database would not begin a transaction',
        detail: failure.toString(),
      );
    }

    return AdapterTransaction(
      adapter: NitriteAdapter._inTransaction(this, started),
      onCommit: () async {
        try {
          await started.commit();
        } on Object catch (failure) {
          throw BridgeException(
            BridgeErrorKind.adapter,
            'the database refused the commit',
            detail: failure.toString(),
          );
        } finally {
          // Closed on both paths: a session that is not closed holds the
          // transactional maps, and a failed commit is exactly when letting go
          // matters most.
          await session.close();
        }
      },
      onRollback: () async {
        try {
          await started.rollback();
        } finally {
          await session.close();
        }
      },
    );
  }

  /// The stores, counted through [_resolve] rather than off `_db` directly.
  ///
  /// Which matters inside a transaction: a count taken from the primary
  /// collection would show the person a total that does not include the rows
  /// they just staged, and §3.1's read-your-own-writes covers `listStores` as
  /// much as it covers a page.
  @override
  Future<List<StoreInfo>> listStores() async {
    final stores = <StoreInfo>[];
    for (final name in await _db.listCollectionNames) {
      stores.add(StoreInfo(
        name: name,
        kind: 'collection',
        approxCount: await (await _resolve(name)).size,
      ));
    }
    for (final repository in _repositories) {
      final name = repository.documentCollection.name;
      stores.add(StoreInfo(
        name: name,
        kind: 'repository',
        key: _keyOf(name),
        approxCount: await (await _resolve(name)).size,
      ));
    }
    return stores;
  }

  @override
  Future<StoreSchema> getSchema(String store) async {
    final collection = await _resolve(store);
    final sample =
        await collection.find(findOptions: limitBy(sampleSize)).toList();

    // Insertion-ordered: the first document's fields come first, and a field
    // only some documents carry lands after them rather than sorted into the
    // middle, which is closer to how the developer thinks about the store.
    final types = <String, String>{};
    final seen = <String, int>{};
    for (final document in sample) {
      for (final (field, value) in document) {
        seen[field] = (seen[field] ?? 0) + 1;
        final type = _typeOf(value);
        if (type != null) types[field] ??= type;
        types.putIfAbsent(field, () => 'unknown');
      }
    }

    return StoreSchema(
      columns: [
        for (final field in types.keys)
          ColumnInfo(
            name: field,
            type: field == docId ? 'id' : types[field]!,
            // A document store has no declared nullability, so this is what the
            // sample showed: a field missing from any sampled document.
            nullable: field != docId && seen[field] != sample.length,
            pk: field == docId,
          ),
      ],
      // Never false here. A developer must never mistake a sample for a
      // guarantee (`docs/PROTOCOL.md` §2).
      inferred: true,
      sampledDocs: sample.length,
    );
  }

  @override
  Future<QueryPage> queryPage(PageRequest request) async {
    final collection = await _resolve(request.store);
    final filter = request.filter == null
        ? null
        : parseFilter(request.filter!, allowRegex: _allowRegex);

    final options = FindOptions(skip: request.offset, limit: request.pageSize);
    final sortBy = request.sortBy;
    if (sortBy != null) {
      // Nitrite will happily sort by a field no document has — every value is
      // null and the order is arbitrary. Showing rows in an order the client
      // did not ask for is the same failure as showing rows it filtered out,
      // so the sort column is checked against the sampled schema: exactly the
      // set of columns the client was given to offer.
      //
      // ponytail: re-samples per sorted page. Cache the schema per store if a
      // sorted page ever misses the budget.
      final schema = await getSchema(request.store);
      if (!schema.columns.any((column) => column.name == sortBy)) {
        throw BridgeException(
            BridgeErrorKind.badRequest, 'unknown sort column');
      }
      options.orderBy = SortableFields()
        ..addSortedField(
            sortBy, request.desc ? SortOrder.descending : SortOrder.ascending);
    }

    final stopwatch = Stopwatch()..start();
    final documents =
        await collection.find(filter: filter, findOptions: options).toList();
    // ponytail: a second pass to count. Nitrite answers it from the index when
    // the query is unfiltered or index-covered; cache it per store if a large
    // filtered store ever misses the budget.
    final total = await collection.find(filter: filter).count();

    return QueryPage(
      rows: [
        for (final document in documents)
          {
            for (final (field, value) in document) field: encodeValue(value),
          }
      ],
      total: total,
      hasMore: request.offset + documents.length < total,
      elapsedMs: stopwatch.elapsedMilliseconds,
      pageSizeClamped: request.pageSizeClamped,
    );
  }

  /// One row, addressed by `_id` — the identity `docs/PROTOCOL.md` §3 gives
  /// every Nitrite implementation.
  @override
  Future<WriteResult> write(WriteRequest request) async {
    final collection = await _resolve(request.store);

    switch (request.op) {
      case WriteOp.insert:
        final written = await collection.insert(_documentOf(request.values));
        return WriteResult(
          changes: written.getAffectedCount(),
          // The value the client addresses the row by afterwards, in the
          // rendering `_id` already has in a page.
          id: written.isEmpty ? null : written.first.idValue,
        );
      case WriteOp.update:
        if (request.values.containsKey(docId)) {
          // Nitrite merges the update document, so an `_id` in it would rewrite
          // the identity of the row it just matched. The identity is `rowId`,
          // and it is not editable.
          throw BridgeException(
              BridgeErrorKind.badRequest, '_id is not an editable field',
              detail: 'a row is addressed by rowId; the engine owns its '
                  'identity');
        }
        final written = await collection.update(
          byId(_idOf(request.rowId)),
          _documentOf(request.values),
          updateOptions(justOnce: true),
        );
        return WriteResult(changes: written.getAffectedCount());
      case WriteOp.delete:
        final written = await collection.remove(byId(_idOf(request.rowId)),
            justOne: true);
        // `changes: 0` is an answer, not an error: the row the client addressed
        // was not there.
        return WriteResult(changes: written.getAffectedCount());
    }
  }

  /// One binary cell, whole, rather than the 64 KB `queryPage` showed.
  ///
  /// Read by id rather than by filter: this is the O(1) lookup the engine
  /// already has, and the row the client is looking at is one it has an `_id`
  /// for by definition.
  @override
  Future<BlobChunk?> fetchBlob(BlobRequest request) async {
    final collection = await _resolve(request.store);
    final document = await collection.getById(_idOf(request.rowId));
    if (document == null) return null;

    final value = document[request.column];
    if (value == null) return null;
    if (value is! List<int>) {
      // Not binary. A client asking for the bytes of a field that is not bytes
      // has a stale schema, and a UTF-8 rendering of a number would be a
      // fabricated file rather than a helpful one.
      throw BridgeException(BridgeErrorKind.badRequest,
          '"${request.column}" is not a binary field');
    }
    return BlobChunk.slice(
        value is Uint8List ? value : Uint8List.fromList(value), request);
  }

  /// The document a write carries. The core already refused everything that is
  /// not a JSON scalar, and `_id` is validated on the way in by Nitrite itself.
  static Document _documentOf(Map<String, Object?> values) {
    final document = emptyDocument();
    for (final entry in values.entries) {
      document.put(
          entry.key, entry.key == docId ? _idOf(entry.value).idValue : entry.value);
    }
    return document;
  }

  /// Accepts an id in the rendering a page carried — a decimal string, which is
  /// how `nitrite-flutter` keeps it in the document — and the number underneath
  /// it, which is what a person types. The bracketed `[1755…]` form the Java and
  /// Rust adapters render is accepted too, so a pasted id works anywhere.
  static NitriteId _idOf(Object? rowId) {
    final text = rowId.toString();
    final open = text.indexOf('[');
    final close = text.indexOf(']');
    final digits =
        open == 0 && close > open ? text.substring(1, close) : text;
    if (int.tryParse(digits) == null) {
      throw BridgeException(
          BridgeErrorKind.badRequest, 'rowId is not a Nitrite _id',
          detail: 'an _id is the value the store reported in that column');
    }
    return NitriteId.createId(digits);
  }

  @override
  Future<void Function()> watch(
      String store, void Function(String) onChange) async {
    final collection = await _resolve(store);
    // Nitrite's five event names are the protocol's five: `insert`, `update`,
    // `remove`, `indexStart`, `indexEnd`. No mapping table needed, and none
    // invented — the coarser wire events exist for the engines that need them.
    void listener(CollectionEventInfo<dynamic> event) =>
        onChange(event.eventType.name);

    collection.subscribe(listener);
    // The handle here is the listener itself; holding it is what makes
    // `unwatch` and a dropped socket both leave the developer's application
    // with no listener of ours in it.
    return () => collection.unsubscribe(listener);
  }

  /// Turns a client-supplied store name into one this adapter reported.
  ///
  /// This is an allow-list, and it is load-bearing for a reason particular to
  /// Nitrite: [Nitrite.getCollection] **creates** a collection that does not
  /// exist. Passing an unchecked name through would let a paired client litter
  /// the developer's database with empty collections.
  Future<NitriteCollection> _resolve(String store) async {
    NitriteCollection? repository;
    for (final candidate in _repositories) {
      if (candidate.documentCollection.name == store) {
        repository = candidate.documentCollection;
        break;
      }
    }
    if (repository == null &&
        !(await _db.listCollectionNames).contains(store)) {
      throw BridgeException(BridgeErrorKind.badRequest, 'unknown store');
    }

    // Inside a transaction, always the transaction's view — a repository's
    // handle included. A read through the primary would miss the documents
    // staged beside it, and a write through it would land outside the
    // transaction entirely.
    final transaction = _transaction;
    if (transaction != null) {
      // `Transaction.getCollection` opens the primary by name and a
      // repository's document collection is not one; this adapter holds
      // document collections rather than typed repositories, so it has no `T`
      // for the other door. `viewOf` is that door.
      return repository != null
          ? transaction.viewOf(repository)
          : transaction.getCollection(store);
    }

    return repository ?? await _db.getCollection(store);
  }

  /// A keyed repository is stored under `entityName+key`; the key is reported
  /// beside the name so the client can label it, while the name stays the one
  /// addressable identity the protocol's `store` parameter carries.
  static String? _keyOf(String collectionName) {
    final separator = collectionName.indexOf(keyObjSeparator);
    return separator < 0 ? null : collectionName.substring(separator + 1);
  }

  /// A closed set, so the client has a known set of renderings rather than
  /// whatever Dart's `runtimeType` prints. `null` means this document said
  /// nothing about the field's type.
  static String? _typeOf(Object? value) => switch (value) {
        null => null,
        bool() => 'bool',
        int() => 'int',
        double() => 'real',
        String() => 'text',
        DateTime() => 'date',
        Uint8List() => 'blob',
        List() => 'list',
        Map() => 'document',
        Document() => 'document',
        _ => 'text',
      };
}
