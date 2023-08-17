import 'dart:isolate';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite_hive_adapter/nitrite_hive_adapter.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';
import '../repository/base_object_repository_test_loader.dart';
import '../repository/data/test_objects.dart';
import '../repository/data/test_objects_decorators.dart';

void main() {
  group(retry: 3, 'Transaction Repository Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Commit Insert', () async {
      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      var session = db.createSession();
      var tx = await session.beginTransaction();

      var data = TxData()
        ..name = 'John'
        ..id = 1;

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await txRepo.insert(data);

      var txCursor = txRepo.find(filter: where('name').eq('John'));
      expect(await txCursor.length, 1);

      var cursor = repository.find(filter: where('name').eq('John'));
      expect(await cursor.length, 0);

      await tx.commit();

      cursor = repository.find(filter: where('name').eq('John'));
      expect(await cursor.length, 1);
    });

    test("Test Rollback Insert", () async {
      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await repository.createIndex(['name']);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var data1 = TxData()
        ..name = 'John'
        ..id = 1;

      var data2 = TxData()
        ..name = 'Jane'
        ..id = 2;

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await txRepo.insertMany([data1, data2]);

      data2.name = 'Molly';
      await repository.insert(data2);

      var txCursor = txRepo.find(filter: where('name').eq('John'));
      expect(await txCursor.length, 1);

      var cursor = repository.find(filter: where('name').eq('John'));
      expect(await cursor.length, 0);

      bool exceptionThrown = false;
      try {
        await tx.commit();
      } catch (e) {
        exceptionThrown = true;
        await tx.rollback();
      }

      expect(exceptionThrown, isTrue);

      cursor = repository.find(filter: where('name').eq('John'));
      expect(await cursor.length, 0);

      cursor = repository.find(filter: where('name').eq('Molly'));
      expect(await cursor.length, 1);
    });

    test('Test Commit Update', () async {
      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());

      var data = TxData()
        ..name = 'John'
        ..id = 1;

      await repository.insert(data);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      var txData1 = TxData()
        ..name = 'Jane'
        ..id = 1;

      await txRepo.updateOne(txData1, insertIfAbsent: true);

      var txCursor = txRepo.find(filter: where('name').eq('Jane'));
      expect(await txCursor.length, 1);

      var cursor = repository.find(filter: where('name').eq('Jane'));
      expect(await cursor.length, 0);

      await tx.commit();

      cursor = repository.find(filter: where('name').eq('Jane'));
      expect(await cursor.length, 1);
    });

    test('Test Rollback Update', () async {
      var repository = await db.getRepository<TxData>(
          entityDecorator: TxDataDecorator(), key: 'rollback');

      var data = TxData()
        ..name = 'Jane'
        ..id = 1;

      await repository.insert(data);
      await repository.createIndex(['name']);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo = await tx.getRepository<TxData>(
          entityDecorator: TxDataDecorator(), key: 'rollback');

      var txData1 = TxData()
        ..name = 'John'
        ..id = 2;

      var txData2 = TxData()
        ..name = 'Jane Doe'
        ..id = 1;

      await txRepo.updateOne(txData2, insertIfAbsent: false);
      await txRepo.insert(txData1);

      // just to create UniqueConstraintViolation for rollback
      await repository.insert(txData1);

      var txCursor = txRepo.find(filter: where('name').eq('John'));
      expect(await txCursor.length, 1);

      txCursor = txRepo.find(filter: where('name').eq('Jane Doe'));
      expect(await txCursor.length, 1);

      var cursor = repository.find(filter: where('name').eq('Jane Doe'));
      expect(await cursor.length, 0);

      bool exceptionThrown = false;
      try {
        await tx.commit();
      } catch (e) {
        exceptionThrown = true;
        await tx.rollback();
      }

      expect(exceptionThrown, isTrue);
      cursor = repository.find(filter: where('name').eq('Jane'));
      expect(await cursor.length, 1);

      cursor = repository.find(filter: where('name').eq('Jane Doe'));
      expect(await cursor.length, 0);
    });

    test('Test Commit Remove', () async {
      var txData1 = TxData()
        ..name = 'John'
        ..id = 1;

      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await repository.insert(txData1);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await txRepo.remove(where('name').eq('John'));

      var txCursor = txRepo.find(filter: where('name').eq('John'));
      expect(await txCursor.length, 0);

      var cursor = repository.find(filter: where('name').eq('John'));
      expect(await cursor.length, 1);

      await tx.commit();

      cursor = repository.find(filter: where('name').eq('John'));
      expect(await cursor.length, 0);
    });

    test('Test Rollback Remove', () async {
      var txData1 = TxData()
        ..name = 'John'
        ..id = 1;

      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await repository.insert(txData1);
      await repository.createIndex(['name']);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await txRepo.remove(where('name').eq('John'));

      var txCursor = txRepo.find(filter: where('name').eq('John'));
      expect(await txCursor.length, 0);

      var cursor = repository.find(filter: where('name').eq('John'));
      expect(await cursor.length, 1);

      var txData2 = TxData()
        ..name = 'Jane'
        ..id = 2;
      await txRepo.insert(txData2);
      await repository.insert(txData2);

      bool exceptionThrown = false;
      try {
        await tx.commit();
      } catch (e) {
        exceptionThrown = true;
        await tx.rollback();
      }

      expect(exceptionThrown, isTrue);

      cursor = repository.find(filter: where('name').eq('John'));
      expect(await cursor.length, 1);

      cursor = repository.find(filter: where('name').eq('Jane'));
      expect(await cursor.length, 1);
    });

    test('Test Commit Create Index', () async {
      var txData1 = TxData()
        ..name = 'John'
        ..id = 1;

      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await repository.insert(txData1);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await txRepo.createIndex(['name'], indexOptions(IndexType.fullText));

      expect(await txRepo.hasIndex(['name']), true);
      expect(await repository.hasIndex(['name']), true);

      await tx.commit();

      expect(await repository.hasIndex(['name']), true);
    });

    test('Test Rollback Create Index', () async {
      var txData1 = TxData()
        ..name = 'John'
        ..id = 1;

      var txData2 = TxData()
        ..name = 'Jane'
        ..id = 2;

      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await repository.insert(txData1);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());

      await txRepo.createIndex(['name'], indexOptions(IndexType.fullText));

      expect(await txRepo.hasIndex(['name']), true);
      expect(await repository.hasIndex(['name']), true);

      await txRepo.insert(txData2);
      await repository.insert(txData2);

      bool exceptionThrown = false;
      try {
        await tx.commit();
      } catch (e) {
        exceptionThrown = true;
        await tx.rollback();
      }

      expect(exceptionThrown, isTrue);
      expect(await repository.hasIndex(['name']), true);
    });

    test('Test Commit Clear', () async {
      var txData1 = TxData()
        ..name = 'John'
        ..id = 1;

      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await repository.insert(txData1);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await txRepo.clear();

      expect(await txRepo.size, 0);
      // auto commit
      expect(await repository.size, 0);

      await tx.commit();

      expect(await repository.size, 0);
    });

    test('Test Rollback Clear', () async {
      var txData1 = TxData()
        ..name = 'John'
        ..id = 1;

      var txData2 = TxData()
        ..name = 'Jane'
        ..id = 2;

      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await repository.insert(txData1);
      await repository.createIndex(['name']);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await txRepo.clear();

      expect(await txRepo.size, 0);
      expect(await repository.size, 0);

      await txRepo.insert(txData2);
      await repository.insert(txData2);

      bool exceptionThrown = false;
      try {
        await tx.commit();
      } catch (e) {
        exceptionThrown = true;
        await tx.rollback();
      }

      expect(exceptionThrown, isTrue);
      expect(await repository.size, 1);
    });

    test('Test Commit Drop Index', () async {
      var txData1 = TxData()
        ..name = 'John'
        ..id = 1;

      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await repository.insert(txData1);
      await repository.createIndex(['name']);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await txRepo.dropIndex(['name']);

      expect(await txRepo.hasIndex(['name']), false);
      // auto commit
      expect(await repository.hasIndex(['name']), false);

      await tx.commit();

      expect(await repository.hasIndex(['name']), false);
    });

    test('Test Rollback Drop Index', () async {
      var txData1 = TxData()
        ..name = 'John'
        ..id = 1;

      var txData2 = TxData()
        ..name = 'Jane'
        ..id = 2;

      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await repository.insert(txData1);
      await repository.createIndex(['name']);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await txRepo.dropIndex(['name']);

      expect(await txRepo.hasIndex(['name']), false);
      // auto commit
      expect(await repository.hasIndex(['name']), false);

      await txRepo.insert(txData2);
      await repository.insert(txData2);

      bool exceptionThrown = false;
      try {
        await tx.commit();
      } catch (e) {
        exceptionThrown = true;
        await tx.rollback();
      }

      expect(exceptionThrown, isTrue);
      expect(await repository.hasIndex(['name']), false);
    });

    test('Test Commit Drop All Indices', () async {
      var txData1 = TxData()
        ..name = 'John'
        ..id = 1;

      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await repository.insert(txData1);
      await repository.createIndex(['name']);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await txRepo.dropAllIndices();

      expect(await txRepo.hasIndex(['name']), false);
      // auto commit
      expect(await repository.hasIndex(['name']), false);

      await tx.commit();

      expect(await repository.hasIndex(['name']), false);
    });

    test('Test Rollback Drop All Indices', () async {
      var txData1 = TxData()
        ..name = 'John'
        ..id = 1;

      var txData2 = TxData()
        ..name = 'Jane'
        ..id = 2;

      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await repository.insert(txData1);
      await repository.createIndex(['name']);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await txRepo.dropAllIndices();

      expect(await txRepo.hasIndex(['name']), false);
      // auto commit
      expect(await repository.hasIndex(['name']), false);

      await txRepo.insert(txData2);
      await repository.insert(txData2);
      await tx.rollback();

      expect(await repository.hasIndex(['name']), false);
    });

    test('Test Commit Drop Repository', () async {
      var txData1 = TxData()
        ..name = 'John'
        ..id = 1;

      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await repository.insert(txData1);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await txRepo.drop();

      bool exceptionThrown = false;
      try {
        expect(await txRepo.size, 0);
      } catch (e) {
        exceptionThrown = true;
      }

      expect(exceptionThrown, isTrue);

      // auto commit
      exceptionThrown = false;
      try {
        expect(await repository.size, 0);
      } catch (e) {
        exceptionThrown = true;
      }

      expect(exceptionThrown, isTrue);
    });

    test('Test Rollback Drop Repository', () async {
      var txData1 = TxData()
        ..name = 'John'
        ..id = 1;

      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await repository.insert(txData1);
      await repository.createIndex(['name']);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      // auto commit
      await txRepo.drop();

      bool exceptionThrown = false;
      try {
        expect(await txRepo.size, 0);
      } catch (e) {
        exceptionThrown = true;
      }

      expect(exceptionThrown, isTrue);

      await tx.rollback();

      exceptionThrown = false;
      try {
        expect(await repository.size, 0);
      } catch (e) {
        exceptionThrown = true;
      }
    });

    test('Test Commit Set Attribute', () async {
      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());

      var attribute = Attributes();
      attribute.set('key', 'value');
      await txRepo.setAttributes(attribute);

      expect(await repository.getAttributes(), isNot(attribute));

      await tx.commit();
      expect(await repository.getAttributes(), attribute);
    });

    test('Test Rollback Set Attribute', () async {
      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());

      var attribute = Attributes();
      attribute.set('key', 'value');
      await txRepo.setAttributes(attribute);

      expect(await repository.getAttributes(), isNot(attribute));

      await tx.rollback();

      expect(await repository.getAttributes(), isNot(attribute));
    });

    test('Test Concurrent Insert and Remove', () async {
      var repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await db.close();

      var path = dbPath;
      var fk = faker;

      for (var i = 0; i < 10; i++) {
        await Isolate.run(() async {
          var storeModule =
              HiveModule.withConfig().crashRecovery(true).path(path).build();

          db = await Nitrite.builder()
              .loadModule(storeModule)
              .fieldSeparator('.')
              .openOrCreate(username: 'test', password: 'test');
          var mapper = db.config.nitriteMapper as SimpleNitriteMapper;
          mapper.registerEntityConverter(TxDataConverter());

          var session = db.createSession();
          var tx = await session.beginTransaction();

          var txRepo = await tx.getRepository<TxData>(
              entityDecorator: TxDataDecorator());

          for (var j = 0; j < 10; j++) {
            var txData = TxData()
              ..name = fk.person.name()
              ..id = j + (10 * i);

            await txRepo.insert(txData);
          }

          await txRepo.remove(where('id').eq(2 + (10 * i)));
          await tx.commit();

          await db.close();
        });
      }

      var storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

      db = await Nitrite.builder()
          .loadModule(storeModule)
          .fieldSeparator('.')
          .openOrCreate(username: 'test', password: 'test');

      var mapper = db.config.nitriteMapper as SimpleNitriteMapper;
      mapper.registerEntityConverter(TxDataConverter());

      repository =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      expect(await repository.size, 90);
    });

    test('Test Transaction on Different Repository', () async {
      var repo1 =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      var repo2 = await db.getRepository<TxData>(
          entityDecorator: TxDataDecorator(), key: 'repo2');
      var repo3 = await db.getRepository<TxData>(
          entityDecorator: TxDataDecorator(), key: 'repo3');

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo1 =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      var txRepo2 = await tx.getRepository<TxData>(
          entityDecorator: TxDataDecorator(), key: 'repo2');
      var txRepo3 = await tx.getRepository<TxData>(
          entityDecorator: TxDataDecorator(), key: 'repo3');

      for (var i = 0; i < 10; i++) {
        var txData1 = TxData()
          ..name = faker.person.name()
          ..id = i;

        var txData2 = TxData()
          ..name = faker.person.name()
          ..id = i + 10;

        var txData3 = TxData()
          ..name = faker.person.name()
          ..id = i + 20;

        await txRepo1.insert(txData1);
        await txRepo2.insert(txData2);
        await txRepo3.insert(txData3);
      }

      await tx.commit();

      expect(await repo1.size, 10);
      expect(await repo2.size, 10);
      expect(await repo3.size, 10);

      session = db.createSession();
      tx = await session.beginTransaction();

      txRepo1 =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      txRepo2 = await tx.getRepository<TxData>(
          entityDecorator: TxDataDecorator(), key: 'repo2');
      txRepo3 = await tx.getRepository<TxData>(
          entityDecorator: TxDataDecorator(), key: 'repo3');

      for (var i = 0; i < 10; i++) {
        var txData1 = TxData()
          ..name = faker.person.name()
          ..id = i + 30;

        var txData2 = TxData()
          ..name = faker.person.name()
          ..id = i + 40;

        var txData3 = TxData()
          ..name = faker.person.name()
          ..id = i + 50;

        await txRepo1.insert(txData1);
        await txRepo2.insert(txData2);
        await txRepo3.insert(txData3);
      }

      await tx.commit();

      expect(await repo1.size, 20);
      expect(await repo2.size, 20);
      expect(await repo3.size, 20);
    });

    test('Test Failure on Closed Transaction', () async {
      var repo =
          await db.getRepository<TxData>(entityDecorator: TxDataDecorator());
      await repo.close();

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txRepo =
          await tx.getRepository<TxData>(entityDecorator: TxDataDecorator());
      var txData = TxData()
        ..name = faker.person.name()
        ..id = 1;
      await txRepo.insert(txData);

      await tx.commit();

      var txData2 = TxData()
        ..name = faker.person.name()
        ..id = 2;

      expect(
          () async => await txRepo.insert(txData2), throwsTransactionException);
    });
  });
}
