import 'dart:async';
import 'dart:isolate';

import 'package:nitrite/nitrite.dart';

/// Opens a [Nitrite] database. Must be a top-level or static function (it is
/// sent to the owner isolate), and is the place to build the store module,
/// register entity converters, etc.
typedef NitriteOpener = Future<Nitrite> Function();

/// Runs a [Nitrite] database inside a dedicated *owner* isolate and lets any
/// number of other isolates read and write the same database concurrently.
///
/// A file-backed store (e.g. Hive) cannot be opened by more than one isolate at
/// once — independent in-memory state would diverge and concurrent writes would
/// corrupt the file. [NitriteIsolate] solves this by keeping the database in a
/// single owner isolate and serialising every operation through it. A handle is
/// itself sendable (it wraps only a [SendPort]), so after [spawn] you can pass
/// the same handle to as many client isolates as you like and they will all
/// share one consistent database.
///
/// ```dart
/// // open once on an owner isolate
/// final db = await NitriteIsolate.spawn(openMyDb); // openMyDb is top-level
///
/// // hand the (sendable) db to worker isolates; all share the same data
/// await Future.wait([
///   Isolate.run(() async { await db.getCollection('c').insert([doc]); }),
///   Isolate.run(() async { return db.getCollection('c').size; }),
/// ]);
///
/// await db.close();
/// ```
///
/// Documents, filters, find options and ids are passed by value across the
/// isolate boundary, so results are materialised lists rather than live
/// cursors. Typed repositories are not proxied (their converters live only in
/// the owner) — use document collections.
class NitriteIsolate {
  final SendPort _commands;

  NitriteIsolate._(this._commands);

  /// Spawns the owner isolate, opens the database with [factory] there, and
  /// returns a sendable handle to it.
  static Future<NitriteIsolate> spawn(NitriteOpener factory) async {
    var init = ReceivePort();
    await Isolate.spawn(
        _ownerMain,
        (
          init.sendPort,
          factory,
        ),
        debugName: 'nitrite-owner');
    var first = await init.first;
    init.close();
    if (first is SendPort) {
      return NitriteIsolate._(first);
    }
    throw NitriteException('Failed to open nitrite in owner isolate: $first');
  }

  /// A proxy to the named document collection in the owner isolate.
  IsolateCollection getCollection(String name) =>
      IsolateCollection._(this, name);

  /// Closes the database and stops the owner isolate.
  Future<void> close() => _request('close', '', null);

  Future<dynamic> _request(String type, String collection, dynamic arg) async {
    var reply = ReceivePort();
    _commands.send((type, collection, arg, reply.sendPort));
    var res = await reply.first;
    reply.close();
    if (res is (Symbol, Object?) && res.$1 == #error) {
      throw NitriteException(res.$2 as String);
    }
    return (res as (Symbol, Object?)).$2;
  }
}

/// A proxy to a [NitriteCollection] owned by another isolate. Every method
/// round-trips a message to the owner isolate, which performs the operation and
/// sends back a by-value result.
class IsolateCollection {
  final NitriteIsolate _iso;
  final String _name;

  IsolateCollection._(this._iso, this._name);

  Future<List<NitriteId>> insert(List<Document> documents) async =>
      (await _iso._request('insert', _name, documents) as List)
          .cast<NitriteId>();

  Future<List<Document>> find({
    Filter? filter,
    FindOptions? findOptions,
  }) async =>
      (await _iso._request('find', _name, (filter, findOptions)) as List)
          .cast<Document>();

  Future<Document?> getById(NitriteId id) async =>
      await _iso._request('findById', _name, id) as Document?;

  Future<int> get size async => await _iso._request('size', _name, null) as int;

  Future<List<NitriteId>> remove(Filter filter, {bool justOne = false}) async =>
      (await _iso._request('remove', _name, (filter, justOne)) as List)
          .cast<NitriteId>();

  Future<List<NitriteId>> update(
    Filter filter,
    Document update, {
    bool justOnce = false,
  }) async =>
      (await _iso._request('update', _name, (filter, update, justOnce)) as List)
          .cast<NitriteId>();

  Future<void> createIndex(
    List<String> fields, [
    IndexOptions? indexOptions,
  ]) async =>
      await _iso._request('createIndex', _name, (fields, indexOptions));
}

/// Owner-isolate entry point: opens the database, then serves commands from a
/// single [ReceivePort] strictly one at a time (each is fully awaited before
/// the next), which serialises all access to the underlying store.
Future<void> _ownerMain((SendPort, NitriteOpener) init) async {
  var (mainPort, factory) = init;

  Nitrite db;
  try {
    db = await factory();
  } catch (e) {
    mainPort.send('factory threw: $e');
    return;
  }

  var commands = ReceivePort();
  mainPort.send(commands.sendPort);

  await for (var msg in commands) {
    var (String type, String collection, dynamic arg, SendPort reply) =
        msg as (String, String, dynamic, SendPort);

    if (type == 'close') {
      await db.close();
      reply.send((#ok, null));
      commands.close();
      return;
    }

    try {
      var result = await _dispatch(db, type, collection, arg);
      reply.send((#ok, result));
    } catch (e) {
      reply.send((#error, e.toString()));
    }
  }
}

Future<Object?> _dispatch(
  Nitrite db,
  String type,
  String name,
  dynamic arg,
) async {
  var col = await db.getCollection(name);
  switch (type) {
    case 'insert':
      var wr = await col.insertMany((arg as List).cast<Document>());
      return wr.toList();
    case 'find':
      var (Filter? f, FindOptions? o) = arg as (Filter?, FindOptions?);
      return await col.find(filter: f, findOptions: o).toList();
    case 'findById':
      return await col.getById(arg as NitriteId);
    case 'size':
      return await col.size;
    case 'remove':
      var (Filter f, bool justOne) = arg as (Filter, bool);
      var wr = await col.remove(f, justOne: justOne);
      return wr.toList();
    case 'update':
      var (Filter f, Document u, bool justOnce) =
          arg as (Filter, Document, bool);
      var wr = await col.update(f, u, updateOptions(justOnce: justOnce));
      return wr.toList();
    case 'createIndex':
      var (List<dynamic> fields, IndexOptions? opts) =
          arg as (List<dynamic>, IndexOptions?);
      await col.createIndex(fields.cast<String>(), opts);
      return null;
    default:
      throw NitriteException('Unknown isolate command: $type');
  }
}
