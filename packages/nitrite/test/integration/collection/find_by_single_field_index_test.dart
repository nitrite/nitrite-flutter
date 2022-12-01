import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../../test_utils.dart';
import 'base_collection_test_loader.dart';

void main() {
  group('Collection Find by Single Field Index Test Suite', () {
    setUp(() async {
      // setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Find by Unique Index', () async {
      await insert();
      await collection.createIndex(['firstName']);

      var cursor = await collection.find(filter: where("firstName").eq("fn1"));
      expect(await cursor.length, 1);

      cursor = await collection.find(filter: where("firstName").eq("fn10"));
      expect(await cursor.length, 0);

      await collection.createIndex(['birthDay']);

      cursor = await collection.find(
          filter:
              where("birthDay").gt(DateTime.parse("2012-07-01T16:02:48.440Z")));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: where("birthDay")
              .gte(DateTime.parse("2012-07-01T16:02:48.440Z")));
      expect(await cursor.length, 2);

      cursor = await collection.find(
          filter:
              where("birthDay").lt(DateTime.parse("2012-07-01T16:02:48.440Z")));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: where("birthDay")
              .lte(DateTime.parse("2012-07-01T16:02:48.440Z")));
      expect(await cursor.length, 2);

      cursor =
          await collection.find(filter: where("birthDay").lte(DateTime.now()));
      expect(await cursor.length, 3);

      cursor =
          await collection.find(filter: where("birthDay").lt(DateTime.now()));
      expect(await cursor.length, 3);

      cursor =
          await collection.find(filter: where("birthDay").gt(DateTime.now()));
      expect(await cursor.length, 0);

      cursor =
          await collection.find(filter: where("birthDay").gte(DateTime.now()));
      expect(await cursor.length, 0);

      cursor = await collection.find(
          filter: where("birthDay")
              .lte(DateTime.now())
              .and(where('firstName').eq('fn1')));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: where("birthDay")
              .lte(DateTime.now())
              .or(where('firstName').eq('fn12')));
      expect(await cursor.length, 3);

      cursor = await collection.find(
          filter: and([
        or([
          where("birthDay").lte(DateTime.now()),
          where("firstName").eq("fn12")
        ]),
        where('lastName').eq('ln1'),
      ]));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: ~and([
        or([
          where("birthDay").lte(DateTime.now()),
          where("firstName").eq("fn12")
        ]),
        where('lastName').eq('ln1'),
      ]));
      expect(await cursor.length, 2);

      cursor = await collection.find(filter: where('data.1').eq(4));
      expect(await cursor.length, 2);

      cursor = await collection.find(filter: where('data.1').lt(4));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: where('lastName').within(['ln1', 'ln2', 'ln10']));
      expect(await cursor.length, 3);

      cursor = await collection.find(
          filter: where('firstName').notIn(['fn1', 'fn2']));
      expect(await cursor.length, 1);
    });

    test('Test Find by Non Unique Index', () async {
      await insert();
      await collection
          .createIndex(['lastName'], indexOptions(IndexType.nonUnique));
      await collection
          .createIndex(['birthDay'], indexOptions(IndexType.nonUnique));

      var cursor = await collection.find(filter: where("lastName").eq("ln2"));
      expect(await cursor.length, 2);

      cursor = await collection.find(filter: where("lastName").eq("ln20"));
      expect(await cursor.length, 0);

      cursor = await collection.find(
          filter:
              where("birthDay").gt(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: where("birthDay")
              .gte(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 2);

      cursor = await collection.find(
          filter:
              where("birthDay").lt(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: where("birthDay")
              .lte(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 2);

      cursor =
          await collection.find(filter: where("birthDay").lte(DateTime.now()));
      expect(await cursor.length, 3);

      cursor =
          await collection.find(filter: where("birthDay").lt(DateTime.now()));
      expect(await cursor.length, 3);

      cursor =
          await collection.find(filter: where("birthDay").gt(DateTime.now()));
      expect(await cursor.length, 0);

      cursor =
          await collection.find(filter: where("birthDay").gte(DateTime.now()));
      expect(await cursor.length, 0);

      cursor = await collection.find(
          filter: where("birthDay")
              .lte(DateTime.now())
              .and(where('firstName').eq('fn1')));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: where("birthDay")
              .lte(DateTime.now())
              .or(where('firstName').eq('fn12')));
      expect(await cursor.length, 3);

      cursor = await collection.find(
          filter: and([
        or([
          where("birthDay").lte(DateTime.now()),
          where("firstName").eq("fn12")
        ]),
        where('lastName').eq('ln1'),
      ]));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: ~and([
        or([
          where("birthDay").lte(DateTime.now()),
          where("firstName").eq("fn12")
        ]),
        where('lastName').eq('ln1'),
      ]));
      expect(await cursor.length, 2);

      cursor = await collection.find(filter: where('data.1').eq(4));
      expect(await cursor.length, 2);

      cursor = await collection.find(filter: where('data.1').lt(4));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: where('lastName').within(['ln1', 'ln2', 'ln10']));
      expect(await cursor.length, 3);

      cursor = await collection.find(
          filter: where('firstName').notIn(['fn1', 'fn2']));
      expect(await cursor.length, 1);
    });

    test('Test Find by Fulltext Index After Insert', () async {
      await insert();
      await collection.createIndex(['body'], indexOptions(IndexType.fullText));

      expect(await collection.hasIndex(['body']), isTrue);

      var cursor = await collection.find(filter: where('body').text('Lorem'));
      expect(await cursor.length, 1);

      cursor = await collection.find(filter: where('body').text('nosql'));
      expect(await cursor.length, 0);

      await collection.dropIndex(['body']);
      bool filterExceptions = false;
      try {
        cursor = await collection.find(filter: where('body').text('Lorem'));
        expect(await cursor.length, 1);
      } on FilterException {
        filterExceptions = true;
      } finally {
        expect(filterExceptions, isTrue);
      }
    });

    test('Test Find by Fulltext Index Before Insert', () async {
      await collection.createIndex(['body'], indexOptions(IndexType.fullText));
      expect(await collection.hasIndex(['body']), isTrue);
      await insert();

      var cursor = await collection.find(filter: where('body').text('Lorem'));
      expect(await cursor.length, 1);

      cursor = await collection.find(filter: where('body').text('quick brown'));
      expect(await cursor.length, 2);

      cursor = await collection.find(filter: where('body').text('nosql'));
      expect(await cursor.length, 0);

      await collection.dropIndex(['body']);
      bool filterExceptions = false;
      try {
        cursor = await collection.find(filter: where('body').text('Lorem'));
        expect(await cursor.toList(), []);
      } on FilterException {
        filterExceptions = true;
      } finally {
        expect(filterExceptions, isTrue);
      }
    });

    test('Test Find by Indexed Sort Ascending', () async {
      await insert();
      await collection.createIndex(['birthDay']);

      var cursor = await collection.find(findOptions: orderBy('birthDay'));
      expect(await cursor.length, 3);
      var dateList =
          await cursor.map((doc) => doc['birthDay'] as DateTime).toList();
      expect(isSorted(dateList, true), isTrue);
    });

    test('Test Find by Indexed Sort Descending', () async {
      await insert();
      await collection.createIndex(['birthDay']);

      var cursor = await collection.find(
          findOptions: orderBy('birthDay', SortOrder.descending));
      expect(await cursor.length, 3);
      var dateList =
          await cursor.map((doc) => doc['birthDay'] as DateTime).toList();
      expect(isSorted(dateList, false), isTrue);
    });

    test('Test Find by Index Limit & Sort', () async {
      await insert();
      await collection.createIndex(['birthDay']);

      var cursor = await collection.find(
          findOptions:
              orderBy('birthDay', SortOrder.descending).setSkip(1).setLimit(2));
      expect(await cursor.length, 2);
      var dateList =
          await cursor.map((doc) => doc['birthDay'] as DateTime).toList();
      expect(isSorted(dateList, false), isTrue);

      cursor = await collection.find(
          findOptions: orderBy('birthDay').setSkip(1).setLimit(2));
      expect(await cursor.length, 2);
      dateList =
          await cursor.map((doc) => doc['birthDay'] as DateTime).toList();
      expect(isSorted(dateList, true), isTrue);

      cursor = await collection.find(
          findOptions: orderBy('firstName').setSkip(0).setLimit(30));
      expect(await cursor.length, 3);
      var nameList =
          await cursor.map((doc) => doc['firstName'] as String).toList();
      expect(isSorted(nameList, true), isTrue);
    });

    test('Test Find After Dropped Index', () async {
      await insert();
      await collection.createIndex(['firstName']);

      var cursor = await collection.find(filter: where('firstName').eq('fn1'));
      expect(await cursor.length, 1);

      await collection.dropIndex(['firstName']);
      cursor = await collection.find(filter: where('firstName').eq('fn1'));
      expect(await cursor.length, 1);
    });

    test('Test Find Text with Wild Card', () async {
      await insert();
      await collection.createIndex(['body'], indexOptions(IndexType.fullText));

      var cursor = await collection.find(filter: where('body').text('Lo'));
      expect(await cursor.length, 0);

      cursor = await collection.find(filter: where('body').text('Lo*'));
      expect(await cursor.length, 1);

      cursor = await collection.find(filter: where('body').text('*rem'));
      expect(await cursor.length, 1);

      cursor = await collection.find(filter: where('body').text('*or*'));
      expect(await cursor.length, 2);
    });

    test('Test Find Text with Empty String', () async {
      await insert();
      await collection.createIndex(['body'], indexOptions(IndexType.fullText));

      var cursor = await collection.find(filter: where('body').text(''));
      expect(await cursor.length, 0);
    });

    test('Test Find with OR Indexed', () async {
      var collection = await db.getCollection('testFindWithOrIndexed');
      var doc1 = createDocument('firstName', 'John').put('lastName', 'Doe');
      var doc2 = createDocument('firstName', 'Jane').put('lastName', 'Doe');
      var doc3 = createDocument('firstName', 'Jonas').put('lastName', 'Doe');
      var doc4 = createDocument('firstName', 'Johan').put('lastName', 'Day');

      await collection
          .createIndex(['firstName'], indexOptions(IndexType.unique));

      await collection
          .createIndex(['lastName'], indexOptions(IndexType.nonUnique));

      await collection.insert([doc1, doc2, doc3, doc4]);
      var cursor = await collection.find(
          filter:
              where('firstName').eq('John').or(where('lastName').eq('Day')));
      expect(await cursor.length, 2);
    });
  });
}
