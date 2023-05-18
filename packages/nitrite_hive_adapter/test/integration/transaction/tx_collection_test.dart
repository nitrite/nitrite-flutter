import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_hive_adapter/nitrite_hive_adapter.dart';

import '../../test_utils.dart';
import '../collection/base_collection_test_loader.dart';

void main() {
  group('Transaction Collection Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Execute Transaction Commit', () async {
      var session = db.createSession();
      await session.executeTransaction((tx) async {
        var txCol = await tx.getCollection('test');

        var document = createDocument('firstName', 'John');
        await txCol.insert(document);

        var cursor = await txCol.find(filter: where('firstName').eq('John'));
        expect(await cursor.length, 1);

        var colCursor =
            await collection.find(filter: where('firstName').eq('John'));
        expect(await colCursor.length, 0);
      });

      // auto commit
      var cursor = await collection.find(filter: where('firstName').eq('John'));
      expect(await cursor.length, 1);
    });

    test('Test Execute Transaction Rollback', () async {
      var session = db.createSession();
      var exceptionThrown = false;

      try {
        await session.executeTransaction((tx) async {
          var txCol = await tx.getCollection('test');

          var document = createDocument('firstName', 'John');
          await txCol.insert(document);

          var cursor = await txCol.find(filter: where('firstName').eq('John'));
          expect(await cursor.length, 1);

          var colCursor =
              await collection.find(filter: where('firstName').eq('John'));
          expect(await colCursor.length, 0);

          throw NitriteException('rollback');
        });
      } on NitriteException {
        exceptionThrown = true;
      }

      expect(exceptionThrown, true);

      // auto rollback
      var cursor = await collection.find(filter: where('firstName').eq('John'));
      expect(await cursor.length, 0);
    });

    test('Test Execute Transaction Rollback For', () async {
      var session = db.createSession();
      var exceptionThrown = false;

      try {
        await session.executeTransaction((tx) async {
          var txCol = await tx.getCollection('test');

          var document = createDocument('firstName', 'John');
          await txCol.insert(document);

          var cursor = await txCol.find(filter: where('firstName').eq('John'));
          expect(await cursor.length, 1);

          var colCursor =
              await collection.find(filter: where('firstName').eq('John'));
          expect(await colCursor.length, 0);

          throw NitriteException('rollback');
        }, rollbackFor: [NitriteException]);
      } on NitriteException {
        exceptionThrown = true;
      }

      expect(exceptionThrown, true);

      // auto rollback
      var cursor = await collection.find(filter: where('firstName').eq('John'));
      expect(await cursor.length, 0);
    });

    test('Test Execute Transaction No Rollback For Super Type', () async {
      var session = db.createSession();
      var exceptionThrown = false;

      try {
        await session.executeTransaction((tx) async {
          var txCol = await tx.getCollection('test');

          var document = createDocument('firstName', 'John');
          await txCol.insert(document);

          var cursor = await txCol.find(filter: where('firstName').eq('John'));
          expect(await cursor.length, 1);

          var colCursor =
              await collection.find(filter: where('firstName').eq('John'));
          expect(await colCursor.length, 0);

          throw NitriteIOException('rollback');
        }, rollbackFor: [NitriteException]);
      } on NitriteException {
        exceptionThrown = true;
      }

      expect(exceptionThrown, true);

      // no auto rollback with subtype exception
      var cursor = await collection.find(filter: where('firstName').eq('John'));
      expect(await cursor.length, 1);
    });

    test('Test Commit Insert', () async {
      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txCol = await tx.getCollection('test');

      var document = createDocument('firstName', 'John');
      await txCol.insert(document);

      var cursor = await txCol.find(filter: where('firstName').eq('John'));
      expect(await cursor.length, 1);

      var colCursor =
          await collection.find(filter: where('firstName').eq('John'));
      expect(await colCursor.length, 0);
      await tx.commit();

      cursor = await collection.find(filter: where('firstName').eq('John'));
      expect(await cursor.length, 1);
    });

    test('Test Rollback Insert', () async {
      await collection.createIndex(['firstName']);

      var session = db.createSession();
      var tx = await session.beginTransaction();
      bool exceptionThrown = false;

      var txCol = await tx.getCollection('test');

      var document = createDocument('firstName', 'John');
      var document2 =
          createDocument('firstName', 'Jane').put('lastName', 'Doe');
      await txCol.insertMany([document, document2]);

      try {
        // just to create UniqueConstraintViolation for rollback
        await collection.insertMany([createDocument('firstName', 'Jane')]);

        var cursor = await txCol.find(filter: where('firstName').eq('John'));
        expect(await cursor.length, 1);

        cursor = await txCol.find(filter: where('firstName').eq('Jane'));
        expect(await cursor.length, 1);

        var colCursor =
            await collection.find(filter: where('lastName').eq('Doe'));
        expect(await colCursor.length, 0);

        // a TransactionException should occur here due to UniqueConstraintViolation
        await tx.commit();
      } on TransactionException {
        exceptionThrown = true;
        await tx.rollback();
      }

      expect(exceptionThrown, true);

      var cursor = await collection.find(filter: where('firstName').eq('John'));
      expect(await cursor.length, 0);

      cursor = await collection.find(filter: where('lastName').eq('Doe'));
      expect(await cursor.length, 0);
    });

    test('Test Commit Update', () async {
      var document = createDocument('firstName', 'John');
      await collection.insert(document);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txCol = await tx.getCollection('test');
      document.put('lastName', 'Doe');

      await txCol.update(where('firstName').eq('John'), document,
          UpdateOptions(insertIfAbsent: true));

      var cursor = await txCol.find(filter: where('lastName').eq('Doe'));
      expect(await cursor.length, 1);

      var colCursor =
          await collection.find(filter: where('lastName').eq('Doe'));
      expect(await colCursor.length, 0);

      await tx.commit();

      cursor = await collection.find(filter: where('lastName').eq('Doe'));
      expect(await cursor.length, 1);
    });

    test('Test Rollback Update', () async {
      await collection.createIndex(['firstName']);
      await collection.insertMany([createDocument('firstName', 'Jane')]);

      var session = db.createSession();
      var tx = await session.beginTransaction();
      bool exceptionThrown = false;

      var txCol = await tx.getCollection('test');

      var document = createDocument('firstName', 'John');
      var document2 =
          createDocument('firstName', 'Jane').put('lastName', 'Doe');

      await txCol.update(where('firstName').eq('Jane'), document2);
      await txCol.insert(document);

      // just to create UniqueConstraintViolation for rollback
      await collection.insertMany([createDocument('firstName', 'John')]);

      var cursor = await txCol.find(filter: where('firstName').eq('John'));
      expect(await cursor.length, 1);

      cursor = await txCol.find(filter: where('lastName').eq('Doe'));
      expect(await cursor.length, 1);

      var colCursor =
          await collection.find(filter: where('lastName').eq('Doe'));
      expect(await colCursor.length, 0);

      try {
        // a TransactionException should occur here due to UniqueConstraintViolation
        await tx.commit();
      } on TransactionException {
        exceptionThrown = true;
        await tx.rollback();
      }

      // it is failing here without throwing unique constraint violation
      expect(exceptionThrown, true);

      cursor = await collection.find(filter: where('firstName').eq('Jane'));
      expect(await cursor.length, 1);

      cursor = await collection.find(filter: where('lastName').eq('Doe'));
      expect(await cursor.length, 0);
    });

    test('Test Commit Remove', () async {
      var document = createDocument('firstName', 'John');
      await collection.insert(document);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txCol = await tx.getCollection('test');

      await txCol.remove(where('firstName').eq('John'));

      var cursor = await txCol.find(filter: where('firstName').eq('John'));
      expect(await cursor.length, 0);

      var colCursor =
          await collection.find(filter: where('firstName').eq('John'));
      expect(await colCursor.length, 1);

      await tx.commit();

      cursor = await collection.find(filter: where('firstName').eq('John'));
      expect(await cursor.length, 0);
    });

    test('Test Rollback Remove', () async {
      await collection.createIndex(['firstName']);
      var document = createDocument('firstName', 'John');
      await collection.insert(document);

      var session = db.createSession();
      var tx = await session.beginTransaction();
      bool exceptionThrown = false;

      var txCol = await tx.getCollection('test');

      await txCol.remove(where('firstName').eq('John'));
      var cursor = await txCol.find(filter: where('firstName').eq('John'));
      expect(await cursor.length, 0);

      var colCursor =
          await collection.find(filter: where('firstName').eq('John'));
      expect(await colCursor.length, 1);

      await txCol.insert(createDocument('firstName', 'Jane'));
      await collection.insert(createDocument('firstName', 'Jane'));

      try {
        // a TransactionException should occur here due to UniqueConstraintViolation
        await tx.commit();
      } on TransactionException {
        exceptionThrown = true;
        await tx.rollback();
      }

      expect(exceptionThrown, true);

      cursor = await collection.find(filter: where('firstName').eq('Jane'));
      expect(await cursor.length, 1);

      cursor = await collection.find(filter: where('firstName').eq('John'));
      expect(await cursor.length, 1);
    });

    test('Test Create Index', () async {
      var document = createDocument('firstName', 'John');
      await collection.insert(document);

      var session = db.createSession();
      var tx = await session.beginTransaction();
      var txCol = await tx.getCollection('test');

      await txCol.createIndex(['firstName'], indexOptions(IndexType.fullText));

      expect(await txCol.hasIndex(['firstName']), true);
      expect(await collection.hasIndex(['firstName']), true);

      await tx.commit();

      expect(await collection.hasIndex(['firstName']), true);
    });

    test('Test Rollback Create Index', () async {
      var document = createDocument('firstName', 'John');
      var document2 = createDocument('firstName', 'Jane');
      await collection.insert(document);

      var session = db.createSession();
      var tx = await session.beginTransaction();
      bool exceptionThrown = false;

      var txCol = await tx.getCollection('test');

      await txCol.createIndex(['firstName']);

      expect(await txCol.hasIndex(['firstName']), true);
      expect(await collection.hasIndex(['firstName']), true);

      await txCol.insert(document2);
      await collection.insert(document2);

      try {
        // a TransactionException should occur here due to UniqueConstraintViolation
        await tx.commit();
      } on TransactionException {
        exceptionThrown = true;
        await tx.rollback();
      }

      expect(exceptionThrown, true);

      expect(await collection.hasIndex(['firstName']), true);
    });

    test('Test Commit Clear', () async {
      var document = createDocument('firstName', 'John');
      await collection.insert(document);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txCol = await tx.getCollection('test');

      await txCol.clear();

      expect(await txCol.size, 0);
      expect(await collection.size, 0);

      await tx.commit();

      expect(await collection.size, 0);
    });

    test('Test Rollback Clear', () async {
      await collection.createIndex(['firstName']);
      var document = createDocument('firstName', 'John');
      var document2 = createDocument('firstName', 'Jane');
      await collection.insert(document);

      var session = db.createSession();
      bool exceptionThrown = false;

      var tx = await session.beginTransaction();
      try {
        var txCol = await tx.getCollection('test');
        await txCol.clear();

        expect(await txCol.size, 0);
        expect(await collection.size, 0);

        await txCol.insert(document2);
        await collection.insert(document2);

        await tx.commit();
      } catch (e) {
        // auto-comitted rollback creates UniqueConstraintViolation in insert
        await tx.rollback();
        exceptionThrown = true;
      }

      expect(exceptionThrown, true);
      expect(await collection.size, 0);
    });

    test('Test Commit Drop Index', () async {
      var document = createDocument('firstName', 'John');
      await collection.insert(document);
      await collection.createIndex(['firstName']);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txCol = await tx.getCollection('test');
      expect(await txCol.hasIndex(['firstName']), true);

      await txCol.dropIndex(['firstName']);

      expect(await txCol.hasIndex(['firstName']), false);
      expect(await collection.hasIndex(['firstName']), false);

      await tx.commit();

      expect(await collection.hasIndex(['firstName']), false);
    });

    test('Test Rollback Drop Index', () async {
      var document = createDocument('firstName', 'John');
      var document2 = createDocument('firstName', 'Jane');
      await collection.insert(document);
      await collection.createIndex(['firstName']);
      await collection
          .createIndex(['lastName'], indexOptions(IndexType.nonUnique));

      var session = db.createSession();
      var tx = await session.beginTransaction();
      var exceptionThrown = false;

      try {
        var txCol = await tx.getCollection('test');
        expect(await txCol.hasIndex(['lastName']), true);

        await txCol.dropIndex(['lastName']);

        expect(await txCol.hasIndex(['lastName']), false);
        expect(await collection.hasIndex(['lastName']), false);

        await txCol.insert(document2);
        await collection.insert(document2);

        await tx.commit();
      } catch (e) {
        exceptionThrown = true;
        await tx.rollback();
      }

      expect(exceptionThrown, true);
      expect(await collection.hasIndex(['lastName']), false);
      expect(await collection.hasIndex(['firstName']), true);
    });

    test('Test Commit Drop All Indices', () async {
      var document = createDocument('firstName', 'John');
      await collection.insert(document);
      await collection.createIndex(['firstName']);
      await collection.createIndex(['lastName']);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txCol = await tx.getCollection('test');
      expect(await txCol.hasIndex(['firstName']), true);
      expect(await txCol.hasIndex(['lastName']), true);

      await txCol.dropAllIndices();

      expect(await txCol.hasIndex(['firstName']), false);
      expect(await txCol.hasIndex(['lastName']), false);
      expect(await collection.hasIndex(['firstName']), false);
      expect(await collection.hasIndex(['lastName']), false);

      await tx.commit();

      expect(await collection.hasIndex(['firstName']), false);
      expect(await collection.hasIndex(['lastName']), false);
    });

    test('Test Rollback Drop All Indices', () async {
      var document = createDocument('firstName', 'John').put('lastName', 'Doe');
      await collection.insert(document);
      await collection.createIndex(['firstName']);
      await collection
          .createIndex(['lastName'], indexOptions(IndexType.nonUnique));

      var session = db.createSession();
      var tx = await session.beginTransaction();
      var exceptionThrown = false;

      try {
        var txCol = await tx.getCollection('test');
        expect(await txCol.hasIndex(['firstName']), true);
        expect(await txCol.hasIndex(['lastName']), true);

        await txCol.dropAllIndices();

        expect(await txCol.hasIndex(['firstName']), false);
        expect(await txCol.hasIndex(['lastName']), false);
        expect(await collection.hasIndex(['firstName']), false);
        expect(await collection.hasIndex(['lastName']), false);

        await txCol.insert(
            createDocument('firstName', 'Jane').put('lastName', 'Doe'));
        await collection.insert(
            createDocument('firstName', 'Jane').put('lastName', 'Doe'));

        throw Exception('Test Rollback Drop All Indices');
      } catch (e) {
        exceptionThrown = true;
        await tx.rollback();
      }

      expect(exceptionThrown, true);
      expect(await collection.hasIndex(['firstName']), false);
      expect(await collection.hasIndex(['lastName']), false);
    });

    test('Test Commit Drop Collection', () async {
      var document = createDocument('firstName', 'John');
      await collection.insert(document);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txCol = await tx.getCollection('test');
      await txCol.drop();

      // auto commit
      expect(await db.hasCollection('test'), false);
    });

    test('Test Rollback Drop Collection', () async {
      var document = createDocument('firstName', 'John');
      await collection.insert(document);

      var session = db.createSession();
      var tx = await session.beginTransaction();
      var exceptionThrown = false;

      try {
        var txCol = await tx.getCollection('test');
        await txCol.drop();

        // auto commit
        expect(await db.hasCollection('test'), false);

        throw Exception('Test Rollback Drop Collection');
      } catch (e) {
        exceptionThrown = true;
        await tx.rollback();
      }

      expect(exceptionThrown, true);
      expect(await db.hasCollection('test'), false);
    });

    test('Test Commit Set Attributes', () async {
      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txCol = await tx.getCollection('test');
      var attributes = Attributes();
      attributes.set('key', 'value');
      await txCol.setAttributes(attributes);

      expect(await txCol.getAttributes(), attributes);

      await tx.commit();

      expect(await collection.getAttributes(), attributes);
    });

    test('Test Rollback Set Attributes', () async {
      await collection.createIndex(['firstName']);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      try {
        var txCol = await tx.getCollection('test');
        var attributes = Attributes();
        attributes.set('key', 'value');
        await txCol.setAttributes(attributes);

        await txCol.insert(createDocument('firstName', 'John'));
        await txCol.insert(createDocument('firstName', 'Jane'));

        var attr = await collection.getAttributes();
        expect(attr.hasKey('key'), false);

        // just to create UniqueConstraintViolation for rollback
        await collection.insert(createDocument('firstName', 'Jane'));

        await tx.commit();
      } catch (e) {
        await tx.rollback();
      }

      var attr = await collection.getAttributes();
      expect(attr.hasKey('key'), false);
    });

    test('Test Concurrent Insert And Remove', () async {
      var collection = await db.getCollection('test');
      await collection
          .createIndex(['firstName'], indexOptions(IndexType.nonUnique));
      await collection.createIndex(['id']);
      await db.close();

      var path = dbPath;
      var fk = faker;
      for (var i = 0; i < 10; i++) {
        await Isolate.run(() async {
          var storeModule =
              HiveModule.withConfig().crashRecovery(true).path(path).build();

          var builder = await Nitrite.builder().loadModule(storeModule);

          db = await builder
              .fieldSeparator('.')
              .openOrCreate(username: 'test', password: 'test');

          var session = db.createSession();
          var tx = await session.beginTransaction();
          try {
            var txCol = await tx.getCollection('test');

            for (var j = 0; j < 10; j++) {
              var document = createDocument('firstName', fk.person.firstName())
                  .put('lastName', fk.person.lastName())
                  .put('id', j + (i * 10));

              await txCol.insert(document);
            }

            await txCol.remove(where('id').eq(2 + (i * 10)));
            await tx.commit();
          } catch (e) {
            print('Error in concurrent insert and remove: $e');
            await tx.rollback();
          }

          await db.close();
        });
      }

      var storeModule =
          HiveModule.withConfig().crashRecovery(true).path(dbPath).build();
      var builder = await Nitrite.builder().loadModule(storeModule);

      db = await builder
          .fieldSeparator('.')
          .openOrCreate(username: 'test', password: 'test');

      collection = await db.getCollection('test');
      expect(await collection.size, 90);
    });

    test('Test Transaction on Different Collection', () async {
      var col1 = await db.getCollection('test1');
      var col2 = await db.getCollection('test2');
      var col3 = await db.getCollection('test3');

      await col3.createIndex(['id']);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txCol1 = await tx.getCollection('test1');
      var txCol2 = await tx.getCollection('test2');
      var txCol3 = await tx.getCollection('test3');

      for (var i = 0; i < 10; i++) {
        var document =
            createDocument('firstName', faker.person.firstName()).put('id', i);
        await txCol1.insert(document);

        document = createDocument('firstName', faker.person.firstName())
            .put('id', i + 10);
        await txCol2.insert(document);

        document = createDocument('firstName', faker.person.firstName())
            .put('id', i + 20);
        await txCol3.insert(document);
      }

      await tx.commit();

      expect(await col1.size, 10);
      expect(await col2.size, 10);
      expect(await col3.size, 10);

      session = db.createSession();
      tx = await session.beginTransaction();

      txCol1 = await tx.getCollection('test1');
      txCol2 = await tx.getCollection('test2');
      txCol3 = await tx.getCollection('test3');

      for (var i = 0; i < 10; i++) {
        var document = createDocument('firstName', faker.person.firstName())
            .put('id', i + 30);
        await txCol1.insert(document);

        document = createDocument('firstName', faker.person.firstName())
            .put('id', i + 40);
        await txCol2.insert(document);

        document = createDocument('firstName', faker.person.firstName())
            .put('id', i + 50);
        await txCol3.insert(document);
      }

      expect(await txCol1.size, 20);
      expect(await txCol2.size, 20);
      expect(await txCol3.size, 20);

      expect(await col1.size, 10);
      expect(await col2.size, 10);
      expect(await col3.size, 10);

      var document =
          createDocument('firstName', faker.person.firstName()).put('id', 52);
      await col3.insert(document);

      try {
        await tx.commit();
      } catch (e) {
        await tx.rollback();
      }

      expect(await col1.size, 10);
      expect(await col2.size, 10);
      expect(await col3.size, 11);
    });

    test('Test Failure on Closed Transaction', () async {
      var session = db.createSession();
      var tx = await session.beginTransaction();

      var col = await tx.getCollection('test');
      await col.insert(createDocument('firstName', 'John'));
      await tx.commit();

      expect(
          () async => await col.insert(createDocument('firstName', 'Jane')),
          throwsTransactionException);
    });
  });
}
