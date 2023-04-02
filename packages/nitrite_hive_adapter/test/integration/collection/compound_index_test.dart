import 'dart:math';

import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'base_collection_test_loader.dart';

void main() {
  group('Compound Index Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Create And Check Index', () async {
      await collection.createIndex(['firstName', 'lastName']);
      expect(await collection.hasIndex(['firstName']), isTrue);
      expect(await collection.hasIndex(['firstName', 'lastName']), isTrue);
      expect(await collection.hasIndex(['firstName', 'lastName', 'birthDay']),
          isFalse);
      expect(await collection.hasIndex(['lastName', 'firstName']), isFalse);
      expect(await collection.hasIndex(['lastName']), isFalse);

      await collection
          .createIndex(['firstName'], indexOptions(IndexType.nonUnique));
      expect(await collection.hasIndex(['firstName']), isTrue);

      await collection
          .createIndex(['lastName'], indexOptions(IndexType.nonUnique));
      expect(await collection.hasIndex(['lastName']), isTrue);

      await insert();
    });

    test('Test Create Multi Key Index on First Field', () async {
      await collection
          .createIndex(['data', 'lastName'], indexOptions(IndexType.nonUnique));
      expect(await collection.hasIndex(['data', 'lastName']), isTrue);
      expect(await collection.hasIndex(['data']), isTrue);
      expect(await collection.hasIndex(['lastName']), isFalse);

      await insert();
    });

    test('Test List Indexes', () async {
      expect((await collection.listIndexes()).length, 0);
      await collection.createIndex(['firstName', 'lastName']);
      expect((await collection.listIndexes()).length, 1);

      await collection
          .createIndex(['firstName'], indexOptions(IndexType.nonUnique));
      expect((await collection.listIndexes()).length, 2);
    });

    test('Test Drop Index', () async {
      await collection.createIndex(['firstName', 'lastName']);
      expectLater(
          collection.hasIndex(['firstName', 'lastName']), completion(isTrue));
      expectLater(collection.hasIndex(['firstName']), completion(isTrue));

      await collection.createIndex(['firstName']);
      expectLater(collection.hasIndex(['firstName']), completion(isTrue));

      await collection.dropIndex(['firstName']);
      expectLater(collection.hasIndex(['firstName']), completion(isTrue));
      expectLater(
          collection.hasIndex(['firstName', 'lastName']), completion(isTrue));

      await collection.createIndex(['firstName']);
      await collection.dropIndex(['firstName', 'lastName']);
      expectLater(collection.hasIndex(['firstName']), completion(isTrue));
      expectLater(
          collection.hasIndex(['firstName', 'lastName']), completion(isFalse));

      await collection.dropIndex(['firstName']);
      expectLater(collection.hasIndex(['firstName']), completion(isFalse));
      expect((await collection.listIndexes()).length, 0);
    });

    test('Test Has Index', () async {
      expectLater(collection.hasIndex(['lastName']), completion(isFalse));
      await collection.createIndex(['lastName', 'firstName']);
      expectLater(collection.hasIndex(['lastName']), completion(isTrue));
    });

    test('Test Drop All Indexes', () async {
      await collection.dropAllIndices();
      expect((await collection.listIndexes()).length, 0);

      await collection.createIndex(['firstName', 'lastName']);
      await collection.createIndex(['firstName']);
      expect((await collection.listIndexes()).length, 2);

      await collection.dropAllIndices();
      expect((await collection.listIndexes()).length, 0);
    });

    test('Test Rebuild Index', () async {
      await collection.createIndex(['firstName', 'lastName']);
      expectLater(collection.hasIndex(['firstName']), completion(isTrue));
      expectLater(
          collection.hasIndex(['firstName', 'lastName']), completion(isTrue));

      await insert();
      await collection.rebuildIndex(['firstName', 'lastName']);
      expectLater(collection.hasIndex(['firstName']), completion(isTrue));
      expectLater(
          collection.hasIndex(['firstName', 'lastName']), completion(isTrue));
    });

    test('Test Delete With Index', () async {
      await collection.createIndex(['firstName', 'lastName']);
      await insert();

      var cursor = await collection.find(
          filter:
              and([where('firstName').eq('fn1'), where('lastName').eq('ln1')]));
      cursor.listen(print);

      var result = await collection.remove(
          and([where('firstName').eq('fn1'), where('lastName').eq('ln1')]));
      expect(result.getAffectedCount(), 1);

      result = await collection.remove(and([
        where('firstName').eq('fn2'),
        where('birthDay').gte(DateTime.now())
      ]));
      expect(result.getAffectedCount(), 0);
    });

    test('Test Rebuild Index on Running Index', () async {
      await insert();
      db.getStore().subscribe(print);
      await collection.createIndex(['firstName', 'lastName']);
      await collection.rebuildIndex(['firstName', 'lastName']);

      expectLater(
          collection.hasIndex(['firstName', 'lastName']), completion(isTrue));
    });

    test('Test Null Values in Indexed Fields', () async {
      await collection.createIndex(['firstName', 'lastName']);
      await collection.createIndex(['birthDay', 'lastName']);
      var document = emptyDocument()
        ..put("firstName", null)
        ..put("lastName", "ln1")
        ..put("birthDay", DateTime.now())
        ..put("data", [1, 2, 3])
        ..put("list", ['one', 'two', 'three'])
        ..put("body", 'a quick brown fox jump over the lazy dog');

      await insert();
      await collection.insert([document]);

      var cursor = await collection.find(filter: where('firstName').eq(null));
      expectLater(cursor.first, completion(containsPair('lastName', 'ln1')));
      expectLater(cursor.first, completion(containsPair('firstName', isNull)));

      document = emptyDocument()
        ..put("firstName", 'fn4')
        ..put("lastName", null)
        ..put("birthDay", null)
        ..put("data", [1, 2, 3])
        ..put("list", ['one', 'two', 'three'])
        ..put("body", 'a quick brown fox jump over the lazy dog');
      await collection.insert([document]);

      cursor = await collection.find(filter: where('lastName').eq(null));
      expectLater(cursor.first, completion(containsPair('firstName', 'fn4')));
      expectLater(cursor.first, completion(containsPair('lastName', isNull)));

      cursor = await collection.find(
          filter:
              and([where('birthDay').eq(null), where("lastName").eq(null)]));
      expectLater(cursor.first, completion(containsPair('lastName', isNull)));
    });

    test('Test Drop All and Create Index', () async {
      await collection.createIndex(['firstName', 'lastName']);
      expectLater(collection.hasIndex(['firstName']), completion(isTrue));

      var cursor = await collection.find(
          filter:
              and([where('firstName').eq('fn1'), where('lastName').eq('ln1')]));
      var findPlan = cursor.findPlan;
      expect(findPlan.indexScanFilter, isNotNull);
      expect(findPlan.collectionScanFilter, isNull);

      await collection.dropAllIndices();
      cursor = await collection.find(
          filter:
              and([where('firstName').eq('fn1'), where('lastName').eq('ln1')]));
      findPlan = cursor.findPlan;
      expect(findPlan.indexScanFilter, isNull);
      expect(findPlan.collectionScanFilter, isNotNull);

      await collection.createIndex(['firstName', 'lastName']);
      cursor = await collection.find(
          filter:
              and([where('firstName').eq('fn1'), where('lastName').eq('ln1')]));
      findPlan = cursor.findPlan;
      expect(findPlan.indexScanFilter, isNotNull);
      expect(findPlan.collectionScanFilter, isNull);
    });

    test('Test Find on Column with Multiple Types by Index', () async {
      await collection.dropAllIndices();
      await collection.remove(all);

      var doc1 = emptyDocument().put('field1', 5);
      var doc2 = emptyDocument().put('field1', 4.3).put('field2', 3.5);
      var doc3 = emptyDocument().put('field1', 0.03).put('field2', 5);
      var doc4 = emptyDocument().put('field1', 4).put('field2', 4.5);
      var doc5 = emptyDocument().put('field1', 5.0).put('field2', 5.0);

      await collection.insert([doc1, doc2, doc3, doc4, doc5]);

      var cursor = await collection.find(
          filter: and([where('field1').eq(0.03), where('field2').eq(5)]));
      expectLater(cursor.length, completion(1));

      cursor = await collection.find(
          filter: and([where('field1').eq(5), where('field2').eq(null)]));
      expectLater(cursor.length, completion(1));

      cursor = await collection.find(filter: where('field1').eq(5));
      expectLater(cursor.length, completion(1));

      cursor = await collection.find(filter: where('field1').eq(5.0));
      expectLater(cursor.length, completion(1));

      await collection.createIndex(['field1', 'field2']);
      cursor = await collection.find(
          filter: and([where('field1').eq(0.03), where('field2').eq(5)]));
      expectLater(cursor.length, completion(1));

      cursor = await collection.find(
          filter: and([where('field1').eq(5), where('field2').eq(null)]));
      expectLater(cursor.length, completion(1));

      cursor = await collection.find(filter: where('field1').eq(5));
      expectLater(cursor.length, completion(1));

      cursor = await collection.find(filter: where('field1').eq(5.0));
      expectLater(cursor.length, completion(1));
    });

    test('Test Index Event', () async {
      var collection = await db.getCollection('index-test');
      var random = Random();
      for (var i = 0; i < 1000; i++) {
        var doc = emptyDocument()
          ..put("first", random.nextInt(1000))
          ..put("second", random.nextDouble());
        await collection.insert([doc]);
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
          .createIndex(['first', 'second'], indexOptions(IndexType.nonUnique));
      var cursor = await collection.find();
      expectLater(cursor.length, completion(1000));
      expect(failed, isFalse);
      expect(completed, isTrue);
    });

    test('Test Index and Search on Null Values', () async {
      var collection = await db.getCollection('index-on-null');
      await collection.insert([
        createDocument("first", null)
            .put("second", 123)
            .put("third", [1, 2, null]),
        createDocument("first", "abcd").put("second", 456).put("third", [3, 1]),
        createDocument("first", "xyz").put("second", 789).put("third", null)
      ]);

      await collection.createIndex(['third', 'first']);
      var cursor = await collection.find(filter: where('first').eq(null));
      expectLater(cursor.length, completion(1));

      cursor = await collection.find(filter: where('third').eq(null));
      expectLater(cursor.length, completion(2));
    });
  });
}
