import 'package:flutter_test/flutter_test.dart';
import 'package:nitrite/nitrite.dart';

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
        await txCol.insert([document]);

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
          await txCol.insert([document]);

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
          await txCol.insert([document]);

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
          await txCol.insert([document]);

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
      await txCol.insert([document]);

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
      await txCol.insert([document, document2]);

      try {
        // just to create UniqueConstraintViolation for rollback
        await collection.insert([createDocument('firstName', 'Jane')]);

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
      await collection.insert([document]);

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
      await collection.insert([createDocument('firstName', 'Jane')]);

      var session = db.createSession();
      var tx = await session.beginTransaction();
      bool exceptionThrown = false;

      var txCol = await tx.getCollection('test');

      var document = createDocument('firstName', 'John');
      var document2 =
          createDocument('firstName', 'Jane').put('lastName', 'Doe');

      await txCol.update(where('firstName').eq('Jane'), document2);
      await txCol.insert([document]);

      // just to create UniqueConstraintViolation for rollback
      await collection.insert([createDocument('firstName', 'John')]);

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
      await collection.insert([document]);

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
      await collection.insert([document]);

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

      await txCol.insert([createDocument('firstName', 'Jane')]);
      await collection.insert([createDocument('firstName', 'Jane')]);

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
      await collection.insert([document]);

      var session = db.createSession();
      var tx = await session.beginTransaction();
      var txCol = await tx.getCollection('test');

      await txCol.createIndex(['firstName'], indexOptions(IndexType.fullText));

      expect(await txCol.hasIndex(['firstName']), true);
      expect(await collection.hasIndex(['firstName']), false);

      await tx.commit();

      expect(await collection.hasIndex(['firstName']), true);
    });

    test('Test Rollback Create Index', () async {
      var document = createDocument('firstName', 'John');
      var document2 = createDocument('firstName', 'Jane');
      await collection.insert([document]);

      var session = db.createSession();
      var tx = await session.beginTransaction();
      bool exceptionThrown = false;

      var txCol = await tx.getCollection('test');

      await txCol.createIndex(['firstName']);

      expect(await txCol.hasIndex(['firstName']), true);
      expect(await collection.hasIndex(['firstName']), false);

      await txCol.insert([document2]);
      await collection.insert([document2]);

      try {
        // a TransactionException should occur here due to UniqueConstraintViolation
        await tx.commit();
      } on TransactionException {
        exceptionThrown = true;
        await tx.rollback();
      }

      expect(exceptionThrown, true);

      expect(await collection.hasIndex(['firstName']), false);
    });

    test('Test Commit Clear', () async {
      var document = createDocument('firstName', 'John');
      await collection.insert([document]);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txCol = await tx.getCollection('test');

      await txCol.clear();

      expect(await txCol.size, 0);
      expect(await collection.size, 1);

      await tx.commit();

      expect(await collection.size, 0);
    });

    test('Test Rollback Clear', () async {
      await collection.createIndex(['firstName']);
      var document = createDocument('firstName', 'John');
      var document2 = createDocument('firstName', 'Jane');
      await collection.insert([document]);

      var session = db.createSession();
      bool exceptionThrown = false;

      var tx = await session.beginTransaction();
      try {
        var txCol = await tx.getCollection('test');
        await txCol.clear();

        expect(await txCol.size, 0);
        expect(await collection.size, 1);

        await txCol.insert([document2]);
        await collection.insert([document2]);

        await tx.commit();
      } catch (e) {
        await tx.rollback();
        exceptionThrown = true;
      }

      expect(exceptionThrown, false);
      expect(await collection.size, 1);
    });

    test('Test Commit Drop Index', () async {
      var document = createDocument('firstName', 'John');
      await collection.insert([document]);
      await collection.createIndex(['firstName']);

      var session = db.createSession();
      var tx = await session.beginTransaction();

      var txCol = await tx.getCollection('test');
      expect(await txCol.hasIndex(['firstName']), true);

      await txCol.dropIndex(['firstName']);

      expect(await txCol.hasIndex(['firstName']), false);
      expect(await collection.hasIndex(['firstName']), true);

      await tx.commit();

      expect(await collection.hasIndex(['firstName']), false);
    });
    
  });
}
