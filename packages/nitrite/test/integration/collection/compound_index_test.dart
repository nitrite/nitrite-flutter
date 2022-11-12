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
      print('Found objects');
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
      var futures = <Future<void>>[];
      futures.add(collection.createIndex(['firstName', 'lastName']));
      futures.add(collection.rebuildIndex(['firstName', 'lastName']));
      await Future.wait(futures);

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
      expect(cursor, matcher)
    });
  });
}
