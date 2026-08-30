// `WriteResult` is a name both packages use; the wire one is the one under test.
import 'package:nitrite/nitrite.dart' hide WriteResult;
import 'package:nitrite_bridge/nitrite_bridge.dart';
import 'package:test/test.dart';

import 'nitrite_adapter_test.dart' show Order, OrderConverter, doc, page;

/// `docs/PROTOCOL.md` §3.1 against a real Nitrite database.
///
/// Nitrite's transaction lives above the storage engine, so what is proved here
/// — a rollback really takes the documents back, and a read inside the
/// transaction sees what is staged — holds for the Hive adapter too. This suite
/// runs in memory because that is what this package can open without one.
void main() {
  late Nitrite db;
  late NitriteCollection users;
  late ObjectRepository<Order> orders;

  setUp(() async {
    db = await Nitrite.builder()
        .registerEntityConverter(OrderConverter())
        .openOrCreate();
    users = await db.getCollection('users');
    await users.insertMany([
      doc({'name': 'ada', 'age': 36}),
      doc({'name': 'bob', 'age': 20}),
      doc({'name': 'cyd', 'age': 55}),
    ]);
    orders = await db.getRepository<Order>();
    await orders.insert(Order('sku-1', 2));
  });

  tearDown(() => db.close());

  NitriteAdapter adapterFor({bool allowWrite = true}) => NitriteAdapter(
        db,
        id: 'main',
        displayName: 'app data',
        repositories: [orders],
        allowWrite: allowWrite,
      );

  WriteRequest insert(String store, String name) => WriteRequest.fromParams(
        {
          'store': store,
          'values': {'name': name},
        },
        const AdapterCapabilities(query: QueryConsole.filter, edit: true),
        WriteOp.insert,
      );

  Future<int> countOf(String store) async =>
      (await (await db.getCollection(store)).size);

  group('capability', () {
    test('a writable adapter reports transactions', () {
      expect(adapterFor().capabilities.transactions, isTrue);
    });

    test('a read-only adapter does not', () {
      // `allowWrite` is the permission; `transactions` reports what the engine
      // can undo. Without the first there is nothing to undo.
      expect(adapterFor(allowWrite: false).capabilities.transactions, isFalse);
    });

    test('hello carries it as a present false rather than an absent key', () {
      final capabilities =
          adapterFor(allowWrite: false).toJson()['capabilities']!
              as Map<String, Object?>;
      expect(capabilities.containsKey('transactions'), isTrue);
      expect(capabilities['transactions'], isFalse);
    });

    test('the transactional twin does not offer to nest another', () async {
      final adapter = adapterFor();
      final transaction = await adapter.beginTransaction();
      expect(transaction.adapter.capabilities.transactions, isFalse);
      // Everything else carried over: a gate that changed inside a transaction
      // would be a second, invisible permission model.
      expect(transaction.adapter.capabilities.edit, isTrue);
      expect(transaction.adapter.capabilities.watch, isTrue);
      expect(
        transaction.adapter.capabilities.filterOps,
        adapter.capabilities.filterOps,
      );
      await transaction.rollback();
    });
  });

  group('rollback and commit', () {
    test('a rollback takes the documents back', () async {
      final adapter = adapterFor();
      final transaction = await adapter.beginTransaction();
      await transaction.adapter.write(insert('users', 'ada2'));
      await transaction.adapter.write(insert('users', 'grace'));
      await transaction.rollback();
      expect(await countOf('users'), 3);
    });

    test('a commit keeps them', () async {
      final adapter = adapterFor();
      final transaction = await adapter.beginTransaction();
      await transaction.adapter.write(insert('users', 'grace'));
      await transaction.commit();
      expect(await countOf('users'), 4);
    });

    test('a rolled-back delete brings the document back', () async {
      final adapter = adapterFor();
      final first = (await adapter.queryPage(page(store: 'users'))).rows.first;
      final id = first['_id'];

      final transaction = await adapter.beginTransaction();
      final result = await transaction.adapter.write(
        WriteRequest.fromParams(
          {'store': 'users', 'rowId': id},
          const AdapterCapabilities(query: QueryConsole.filter, edit: true),
          WriteOp.delete,
        ),
      );
      expect(result.changes, 1);
      await transaction.rollback();

      expect(await countOf('users'), 3);
    });

    test('a rolled-back update leaves the old value', () async {
      final adapter = adapterFor();
      final first = (await adapter.queryPage(page(store: 'users'))).rows.first;

      final transaction = await adapter.beginTransaction();
      await transaction.adapter.write(
        WriteRequest.fromParams(
          {
            'store': 'users',
            'rowId': first['_id'],
            'values': {'name': 'changed'},
          },
          const AdapterCapabilities(query: QueryConsole.filter, edit: true),
          WriteOp.update,
        ),
      );
      await transaction.rollback();

      final after = (await adapter.queryPage(page(store: 'users'))).rows.first;
      expect(after['name'], first['name']);
    });
  });

  group('read-your-own-writes', () {
    test('a read inside the transaction sees the pending insert', () async {
      final adapter = adapterFor();
      final transaction = await adapter.beginTransaction();
      await transaction.adapter.write(insert('users', 'grace'));

      // A person who has just inserted a row and cannot see it has been told
      // their edit did not work.
      final inside = await transaction.adapter.queryPage(page(store: 'users'));
      expect(inside.total, 4);
      expect(inside.rows.map((row) => row['name']), contains('grace'));

      await transaction.rollback();
    });

    test('listStores counts through the transaction', () async {
      final adapter = adapterFor();
      final transaction = await adapter.beginTransaction();
      await transaction.adapter.write(insert('users', 'grace'));

      final stores = await transaction.adapter.listStores();
      expect(
        stores.firstWhere((store) => store.name == 'users').approxCount,
        4,
      );
      await transaction.rollback();
    });

    test('a repository is resolved through the transaction too', () async {
      final adapter = adapterFor();
      final store = orders.documentCollection.name;
      final transaction = await adapter.beginTransaction();

      await transaction.adapter.write(insert(store, 'in flight'));
      // Resolved through `viewOf`, not through the repository handle the
      // adapter was constructed with — a write through that one would land
      // outside the transaction.
      expect((await transaction.adapter.queryPage(page(store: store))).total, 2);

      await transaction.rollback();
      expect(await orders.documentCollection.size, 1);
    });

    test('another reader does not see uncommitted documents', () async {
      final adapter = adapterFor();
      final transaction = await adapter.beginTransaction();
      await transaction.adapter.write(insert('users', 'grace'));

      // The base adapter is what another connection resolves to, and §3.1 says
      // it must not see this connection's uncommitted rows.
      expect((await adapter.queryPage(page(store: 'users'))).total, 3);
      await transaction.rollback();
    });
  });

  group('failures', () {
    test('a refused write leaves the transaction usable', () async {
      final adapter = adapterFor();
      final transaction = await adapter.beginTransaction();
      await transaction.adapter.write(insert('users', 'grace'));

      await expectLater(
        transaction.adapter.write(insert('no_such_store', 'x')),
        throwsA(isA<BridgeException>()
            .having((e) => e.kind, 'kind', BridgeErrorKind.badRequest)),
      );

      await transaction.adapter.write(insert('users', 'hopper'));
      await transaction.commit();
      expect(await countOf('users'), 5);
    });
  });
}
