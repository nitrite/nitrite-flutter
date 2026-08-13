import 'dart:typed_data';

// `WriteResult` is a name both packages use; the wire one is the one under test.
import 'package:nitrite/nitrite.dart' hide WriteResult;
import 'package:nitrite_bridge/nitrite_bridge.dart';
import 'package:test/test.dart';

class Order {
  Order(this.sku, this.qty);
  final String? sku;
  final int? qty;
}

/// Hand-written rather than generated: this package must be testable without
/// `build_runner`, and the converter is four lines.
class OrderConverter extends EntityConverter<Order> {
  @override
  Document toDocument(Order entity, NitriteMapper mapper) =>
      createDocument('sku', entity.sku)..put('qty', entity.qty);

  // Nullable throughout: Nitrite validates a repository's type by round-tripping
  // an *empty* document through the converter before it opens one.
  @override
  Order fromDocument(Document document, NitriteMapper mapper) =>
      Order(document.get<String>('sku'), document.get<int>('qty'));
}

class OrderDecorator extends EntityDecorator<Order> {
  @override
  EntityId? get idField => null;
  @override
  List<EntityIndex> get indexFields => [];
}

Document doc(Map<String, Object?> fields) {
  final document = emptyDocument();
  fields.forEach(document.put);
  return document;
}

PageRequest page({
  required String store,
  int page = 0,
  int pageSize = 200,
  Map<String, Object?>? filter,
  String? sortBy,
  bool desc = false,
}) =>
    PageRequest(
      store: store,
      page: page,
      pageSize: pageSize,
      pageSizeClamped: false,
      filter: filter,
      sortBy: sortBy,
      desc: desc,
    );

void main() {
  late Nitrite db;
  late NitriteCollection users;

  setUp(() async {
    db = await Nitrite.builder()
        .registerEntityConverter(OrderConverter())
        .openOrCreate();
    users = await db.getCollection('users');
    await users.insertMany([
      doc({'name': 'ada', 'age': 36, 'city': 'london'}),
      doc({'name': 'bob', 'age': 20, 'city': 'paris'}),
      doc({'name': 'cyd', 'age': 55, 'city': 'london'}),
    ]);
  });

  tearDown(() => db.close());

  NitriteAdapter adapterFor({
    List<ObjectRepository<dynamic>> repositories = const [],
    bool allowRegex = false,
    bool allowWrite = false,
    bool allowSnapshot = false,
    int sampleSize = 50,
  }) =>
      NitriteAdapter(
        db,
        id: 'main',
        displayName: 'app data',
        repositories: repositories,
        allowRegex: allowRegex,
        allowWrite: allowWrite,
        allowSnapshot: allowSnapshot,
        sampleSize: sampleSize,
      );

  Matcher badRequest(String because) => throwsA(isA<BridgeException>()
      .having((e) => e.kind, 'kind', BridgeErrorKind.badRequest)
      .having((_) => because, 'because', because));

  group('identity', () {
    test('reports itself as a nitrite store with a filter console', () {
      final adapter = adapterFor();
      expect(adapter.kind, 'nitrite');
      expect(adapter.engine, 'memory');
      expect(adapter.capabilities.query, QueryConsole.filter);
    });

    test('grants nothing by default (criterion 10)', () {
      final capabilities = adapterFor().capabilities.toJson();

      expect(capabilities['edit'], isFalse);
      expect(capabilities['sql'], isFalse);
      expect(capabilities['snapshot'], isFalse);
      expect(capabilities['filterOps'], isNot(contains('regex')));
    });

    test('watch is on and honestly scoped', () {
      // Nitrite's subscription is collection-level and sees every write in this
      // process, not only the ones this bridge made — unlike Drift's.
      final capabilities = adapterFor().capabilities.toJson();
      expect(capabilities['watch'], isTrue);
      expect(capabilities['watchScope'], 'engine');
    });

    test('opting in is per adapter and explicit', () {
      final capabilities =
          adapterFor(allowRegex: true, allowWrite: true, allowSnapshot: true)
              .capabilities
              .toJson();

      expect(capabilities['edit'], isTrue);
      expect(capabilities['snapshot'], isTrue);
      expect(capabilities['filterOps'], contains('regex'));
    });
  });

  group('listStores', () {
    test('lists collections with their sizes', () async {
      final stores = await adapterFor().listStores();

      expect(stores, hasLength(1));
      expect(stores.single.toJson(),
          {'name': 'users', 'kind': 'collection', 'approxCount': 3});
    });

    test('lists a repository that was handed in, keyed or not', () async {
      final orders =
          await db.getRepository<Order>(entityDecorator: OrderDecorator());
      final archive = await db.getRepository<Order>(
          entityDecorator: OrderDecorator(), key: 'archive');
      await orders.insert(Order('a-1', 2));

      final stores =
          await adapterFor(repositories: [orders, archive]).listStores();
      final repositories =
          stores.where((store) => store.kind == 'repository').toList();

      expect(
          repositories.map((store) => store.name), ['Order', 'Order+archive'],
          reason: 'the name is the one addressable identity `store` carries; a '
              'keyed and an unkeyed repository must not collide');
      expect(repositories.first.key, isNull);
      expect(repositories.last.key, 'archive');
      expect(repositories.first.approxCount, 1);
    });

    test('a repository that was not handed in is not listed', () async {
      // Nitrite opens a repository by Dart type and a wire name is not a type,
      // so listing one we cannot open would be a row the client cannot click.
      await db.getRepository<Order>(entityDecorator: OrderDecorator());

      final stores = await adapterFor().listStores();
      expect(stores.map((store) => store.kind), everyElement('collection'));
    });
  });

  group('getSchema', () {
    test('is always flagged inferred, with the sample size', () async {
      final schema = await adapterFor().getSchema('users');

      expect(schema.toJson()['inferred'], isTrue,
          reason: 'a developer must never mistake a sample for a guarantee');
      expect(schema.sampledDocs, 3);
    });

    test('names _id as the key and types the rest from the sample', () async {
      final columns = {
        for (final column in (await adapterFor().getSchema('users')).columns)
          column.name: column
      };

      expect(columns['_id']!.type, 'id');
      expect(columns['_id']!.pk, isTrue);
      expect(columns['_id']!.nullable, isFalse);
      expect(columns['name']!.type, 'text');
      expect(columns['age']!.type, 'int');
    });

    test('a field only some documents carry is nullable', () async {
      await users.insert(doc({'name': 'dee', 'nickname': 'd'}));
      final columns = {
        for (final column in (await adapterFor().getSchema('users')).columns)
          column.name: column
      };

      expect(columns['nickname']!.nullable, isTrue);
      expect(columns['name']!.nullable, isFalse);
    });

    test('reads no further than the sample size', () async {
      await users.insertMany([
        for (var i = 0; i < 100; i++) doc({'name': 'n$i', 'age': i})
      ]);

      final schema = await adapterFor(sampleSize: 10).getSchema('users');
      expect(schema.sampledDocs, 10);
    });

    test('an unknown store is a bad request, not an empty schema', () {
      expect(() => adapterFor().getSchema('nope'), badRequest('unknown store'));
    });
  });

  group('queryPage', () {
    test('pages with skip and limit and reports the total', () async {
      final adapter = adapterFor();
      final first = await adapter.queryPage(page(store: 'users', pageSize: 2));
      final second =
          await adapter.queryPage(page(store: 'users', page: 1, pageSize: 2));

      expect(first.rows, hasLength(2));
      expect(first.total, 3);
      expect(first.hasMore, isTrue);
      expect(second.rows, hasLength(1));
      expect(second.hasMore, isFalse);
    });

    test('a page past the end is empty rather than an error', () async {
      final result =
          await adapterFor().queryPage(page(store: 'users', page: 99));
      expect(result.rows, isEmpty);
      expect(result.hasMore, isFalse);
    });

    test('sorts by a named field in both directions', () async {
      final adapter = adapterFor();
      final ascending =
          await adapter.queryPage(page(store: 'users', sortBy: 'age'));
      final descending = await adapter
          .queryPage(page(store: 'users', sortBy: 'age', desc: true));

      expect([for (final row in ascending.rows) row['name']],
          ['bob', 'ada', 'cyd']);
      expect([for (final row in descending.rows) row['name']],
          ['cyd', 'ada', 'bob']);
    });

    test('an unknown sort column is refused, not sorted by nothing', () {
      // Nitrite sorts by a field no document has without complaint: every
      // value is null and the order is arbitrary. A grid that silently ignores
      // the sort the user clicked is the same class of lie as an unfiltered
      // page — and the conformance suite checks it for every adapter.
      expect(() => adapterFor().queryPage(page(store: 'users', sortBy: 'rank')),
          badRequest('no sampled document has a rank'));
    });

    test('applies a filter and counts the filtered set, not the store',
        () async {
      final result = await adapterFor().queryPage(page(store: 'users', filter: {
        'and': [
          {'field': 'city', 'op': 'eq', 'value': 'london'}
        ]
      }));

      expect([for (final row in result.rows) row['name']], ['ada', 'cyd']);
      expect(result.total, 2,
          reason: 'a total that counts the whole store turns the pager into a '
              'lie about the filtered result');
    });

    test('an unadvertised regex filter is refused (criterion 9)', () {
      expect(
        () => adapterFor().queryPage(page(
            store: 'users',
            filter: {'field': 'name', 'op': 'regex', 'value': 'a'})),
        badRequest('regex is not in filterOps'),
      );
    });

    test('a regex filter runs when the developer allowed it', () async {
      final result = await adapterFor(allowRegex: true).queryPage(page(
          store: 'users',
          filter: {'field': 'name', 'op': 'regex', 'value': '^a'}));

      expect([for (final row in result.rows) row['name']], ['ada']);
    });

    test('values reach the wire JSON-safe', () async {
      await users.insert(doc({
        'name': 'zed',
        'avatar': Uint8List.fromList([1, 2, 3]),
        'joined': DateTime.utc(2026, 8, 6),
      }));

      final result = await adapterFor().queryPage(page(
          store: 'users',
          filter: {'field': 'name', 'op': 'eq', 'value': 'zed'}));
      final row = result.rows.single;

      expect((row['avatar']! as Map<String, Object?>)['len'], 3);
      expect(row['joined'], '2026-08-06T00:00:00.000Z');
    });

    test('the client is untrusted input: an unknown store creates nothing',
        () async {
      // Nitrite's getCollection *creates* a collection that does not exist, so
      // an unchecked name would let a paired client litter the developer's
      // database.
      expect(() => adapterFor().queryPage(page(store: 'invented')),
          badRequest('unknown store'));
      await pumpEventQueue();
      expect(await db.listCollectionNames, ['users']);
    });

    test('a repository pages through its own documents', () async {
      final orders =
          await db.getRepository<Order>(entityDecorator: OrderDecorator());
      await orders.insertMany([Order('a-1', 2), Order('b-2', 5)]);

      final result = await adapterFor(repositories: [orders])
          .queryPage(page(store: 'Order', sortBy: 'sku'));

      expect([for (final row in result.rows) row['sku']], ['a-1', 'b-2']);
    });
  });

  group('write', () {
    /// Through the core's validator, because that is where an adapter is
    /// reached from: a test that built a [WriteRequest] by hand would be
    /// testing a path no client can take.
    Future<WriteResult> write(
            NitriteAdapter adapter, WriteOp op, Map<String, Object?> params) =>
        adapter
            .write(WriteRequest.fromParams(params, adapter.capabilities, op));

    test('the three writes round-trip by document id', () async {
      final adapter = adapterFor(allowWrite: true);

      final inserted = await write(adapter, WriteOp.insert, {
        'store': 'users',
        'values': {'name': 'eve', 'age': 41},
      });
      expect(inserted.changes, 1);
      final id = inserted.id;
      expect(id, isNotNull,
          reason: 'an insert reports the identity the client addresses it by');

      final updated = await write(adapter, WriteOp.update, {
        'store': 'users',
        'rowId': id,
        'values': {'age': 42},
      });
      expect(updated.changes, 1);

      // A partial update leaves the fields it did not name alone.
      final row = await adapter.queryPage(page(
          store: 'users',
          filter: {'field': 'name', 'op': 'eq', 'value': 'eve'}));
      expect(row.rows.single['age'], 42);
      expect(row.rows.single['_id'], id);

      final deleted = await write(
          adapter, WriteOp.delete, {'store': 'users', 'rowId': id});
      expect(deleted.changes, 1);

      // `changes: 0` is an answer, not an error: the row is gone, and a client
      // must be able to tell that from a write that failed.
      final again = await write(
          adapter, WriteOp.delete, {'store': 'users', 'rowId': id});
      expect(again.changes, 0);
    });

    test('an id is addressable as rendered, as a number and as bracketed',
        () async {
      final adapter = adapterFor(allowWrite: true);
      final rendered =
          (await adapter.queryPage(page(store: 'users', pageSize: 1)))
              .rows
              .single['_id'] as String;

      for (final rowId in [rendered, int.parse(rendered), '[$rendered]']) {
        final updated = await write(adapter, WriteOp.update, {
          'store': 'users',
          'rowId': rowId,
          'values': {'seen': true},
        });
        expect(updated.changes, 1, reason: '$rowId');
      }
    });

    test('the writes an adapter must refuse', () async {
      final adapter = adapterFor(allowWrite: true);

      // The identity is `rowId` and the engine owns it: Nitrite merges the
      // update document, so an `_id` in it would rewrite the row's identity.
      await expectLater(
          write(adapter, WriteOp.update, {
            'store': 'users',
            'rowId': 1,
            'values': {'_id': '2'},
          }),
          badRequest('_id is not editable'));

      // Not an `_id` at all. A store that took this for one would address
      // whatever it happened to match.
      await expectLater(
          write(adapter, WriteOp.delete,
              {'store': 'users', 'rowId': 'not-an-id'}),
          badRequest('rowId is not an _id'));

      // The store allow-list is the same one every read goes through: an
      // unchecked name would let a paired client create a collection by
      // writing to it.
      await expectLater(
          write(adapter, WriteOp.insert, {
            'store': 'nope',
            'values': {'name': 'eve'},
          }),
          badRequest('unknown store'));
    });

    test('writing is refused until the developer opts in', () {
      // Criterion 10, at the adapter: the gate is the core's, and this is the
      // proof that a default-constructed adapter never opens it.
      final adapter = adapterFor();
      expect(adapter.capabilities.edit, isFalse);
      expect(
          () => write(adapter, WriteOp.insert, {
                'store': 'users',
                'values': {'name': 'eve'},
              }),
          throwsA(isA<BridgeException>()
              .having((e) => e.kind, 'kind', BridgeErrorKind.forbidden)));
    });

    test('a snapshot pages the whole store once the developer opts in',
        () async {
      expect(adapterFor().capabilities.snapshot, isFalse);

      final adapter = adapterFor(allowSnapshot: true);
      final request = SnapshotRequest.fromParams(
          {'store': 'users'}, adapter.capabilities);

      var rows = 0;
      await for (final chunk in adapter.snapshot(request)) {
        rows += chunk.length;
      }
      expect(rows, 3);
    });
  });

  group('watch', () {
    test('an insert reaches the listener as the protocol event name', () async {
      final adapter = adapterFor();
      final events = <String>[];
      final cancel = await adapter.watch('users', events.add);

      await users.insert(doc({'name': 'eve'}));
      await pumpEventQueue();

      expect(events, ['insert']);
      cancel();
    });

    test('remove and update arrive under their own names', () async {
      final adapter = adapterFor();
      final events = <String>[];
      final cancel = await adapter.watch('users', events.add);

      await users.update(
          where('name').eq('ada'), doc({'city': 'york'}), updateOptions());
      await users.remove(where('name').eq('bob'));
      await pumpEventQueue();

      expect(events, ['update', 'remove']);
      cancel();
    });

    test('cancelling leaves no listener in the application', () async {
      final adapter = adapterFor();
      final events = <String>[];
      final cancel = await adapter.watch('users', events.add);
      cancel();

      await users.insert(doc({'name': 'eve'}));
      await pumpEventQueue();

      expect(events, isEmpty);
    });

    test('watching an unknown store is a bad request', () {
      expect(() => adapterFor().watch('nope', (_) {}),
          badRequest('unknown store'));
    });
  });
}
