import 'dart:math';

import 'package:logging/logging.dart';
import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'base_collection_test_loader.dart';

void main() {
  group('Collection Single Field Index Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Create Index', () async {
      await collection.createIndex(['firstName']);
      expect(await collection.hasIndex(['firstName']), true);

      await collection
          .createIndex(['lastName'], indexOptions(IndexType.nonUnique));
      expect(await collection.hasIndex(['lastName']), true);

      await collection.createIndex(['body'], indexOptions(IndexType.fullText));
      expect(await collection.hasIndex(['body']), true);

      await collection.createIndex(['birthDay']);
      expect(await collection.hasIndex(['birthDay']), true);

      await insert();
    });

    test('Test List Indexes', () async {
      await collection.createIndex(['firstName']);
      expect(await collection.hasIndex(['firstName']), true);

      await collection
          .createIndex(['lastName'], indexOptions(IndexType.nonUnique));
      expect(await collection.hasIndex(['lastName']), true);

      await collection.createIndex(['body'], indexOptions(IndexType.fullText));
      expect(await collection.hasIndex(['body']), true);

      await collection.createIndex(['birthDay']);
      expect(await collection.hasIndex(['birthDay']), true);

      await insert();
    });

    test('Test Drop Index', () async {
      await collection.createIndex(['firstName']);
      expect(await collection.hasIndex(['firstName']), true);

      await collection.dropIndex(['firstName']);
      expect(await collection.hasIndex(['firstName']), false);
    });

    test('Test Drop All Indexes', () async {
      await collection.dropAllIndices();
      await collection.createIndex(['firstName']);
      await collection
          .createIndex(['lastName'], indexOptions(IndexType.nonUnique));
      await collection.createIndex(['body'], indexOptions(IndexType.fullText));
      await collection.createIndex(['birthDay']);

      expect(await collection.listIndexes(), hasLength(4));

      await collection.dropAllIndices();
      expect(await collection.listIndexes(), isEmpty);
    });

    test('Test Has Index', () async {
      expect(await collection.hasIndex(['lastName']), false);
      await collection
          .createIndex(['lastName'], indexOptions(IndexType.nonUnique));
      expect(await collection.hasIndex(['lastName']), true);

      expect(await collection.hasIndex(['body']), false);
      await collection.createIndex(['body'], indexOptions(IndexType.fullText));
      expect(await collection.hasIndex(['body']), true);
    });

    test('Test Delete with Index', () async {
      await collection.createIndex(['firstName']);
      await collection.createIndex(['body'], indexOptions(IndexType.fullText));

      await insert();
      var result = await collection.remove(where('firstName').eq('fn1'));
      expect(result.getAffectedCount(), 1);

      var cursor = await collection.find();
      expect(await cursor.length, 2);

      result = await collection.remove(where('body').text('Lorem'));
      expect(result.getAffectedCount(), 1);

      cursor = await collection.find();
      expect(await cursor.length, 1);
    });

    test('Test Rebuild Index', () async {
      await collection.createIndex(['body'], indexOptions(IndexType.fullText));
      await insert();
      var indices = await collection.listIndexes();
      for (var idx in indices) {
        await collection.rebuildIndex(idx.fields.fieldNames);
      }
    });

    test('Test Null Value in Indexed Field', () async {
      await collection.createIndex(['firstName']);
      await collection
          .createIndex(['birthDay'], indexOptions(IndexType.nonUnique));
      await insert();

      var document = createDocument('firstName', null)
        ..put('lastName', 'ln1')
        ..put('birthDay', null)
        ..put('data', [1, 2, 3])
        ..put('list', [
          'one',
          'two',
          'three',
        ])
        ..put('body', 'a quick brown fox jump over the lazy dog');

      await collection.insert(document);
    });

    test('Test Drop All and Create Index', () async {
      await collection.createIndex(['firstName']);
      expect(await collection.hasIndex(['firstName']), true);
      await collection.dropAllIndices();
      expect(await collection.hasIndex(['firstName']), false);

      await collection.createIndex(['firstName']);
      expect(await collection.hasIndex(['firstName']), true);

      collection = await db.getCollection('test');
      expect(await collection.hasIndex(['firstName']), true);
    });

    test('Test Index on Multiple Datatype', () async {
      await collection.dropAllIndices();
      await collection.remove(all);

      var doc1 = createDocument('field', 5);
      var doc2 = createDocument('field', 4.3);
      var doc3 = createDocument('field', 0.03);
      var doc4 = createDocument('field', 4);
      var doc5 = createDocument('field', 5.0);

      await collection.insertMany([doc1, doc2, doc3, doc4, doc5]);
      var cursor = await collection.find(filter: where('field').eq(5));
      expect(await cursor.length, 1);

      await collection
          .createIndex(['field'], indexOptions(IndexType.nonUnique));

      cursor = await collection.find(filter: where('field').eq(5));
      expect(await cursor.length, 1);
    });

    test('Test Index Event', () async {
      Logger.root.level = Level.OFF;
      var collection = await db.getCollection('index-test');
      var random = Random();

      for (var i = 0; i < 10000; i++) {
        var document = createDocument("first", random.nextInt(100))
            .put("second", random.nextDouble());
        await collection.insert(document);
      }

      var failed = false;
      var completed = false;
      collection.subscribe((event) {
        switch (event.eventType) {
          case EventType.insert:
          case EventType.update:
          case EventType.remove:
            failed = true;
            break;
          case EventType.indexStart:
          case EventType.indexEnd:
            completed = true;
            break;
        }
      });

      await collection
          .createIndex(['first'], indexOptions(IndexType.nonUnique));
      var cursor = await collection.find();
      expect(await cursor.length, 10000);

      await collection
          .createIndex(['second'], indexOptions(IndexType.nonUnique));
      cursor = await collection.find();
      expect(await cursor.length, 10000);

      expect(failed, false);
      expect(completed, true);
    });

    test('Test Index and Search on Null Values', () async {
      var collection = await db.getCollection('index-on-null');
      await collection.insert(
        createDocument('first', null)
          ..put('second', 123)
          ..put('third', [1, 2, null])
      );
      await collection.insert(
        createDocument('first', 'abcd')
          ..put('second', 456)
          ..put('third', [3, 1])
      );
      await collection.insert(
        createDocument('first', 'xyz')
          ..put('second', 789)
          ..put('third', null)
      );

      await collection.createIndex(['first']);
      var cursor = await collection.find(filter: where('first').eq(null));
      expect(await cursor.length, 1);

      await collection
          .createIndex(['third'], indexOptions(IndexType.nonUnique));
      cursor = await collection.find(filter: where('third').eq(null));
      expect(await cursor.length, 2);
    });

    test('Test Create Compound and Single Field Index on Same Field', () async {
      await collection
          .createIndex(['lastName'], indexOptions(IndexType.nonUnique));

      await collection
          .createIndex(['firstName'], indexOptions(IndexType.unique));

      await collection.createIndex(
          ['lastName', 'firstName'], indexOptions(IndexType.nonUnique));
    });
  });
}
