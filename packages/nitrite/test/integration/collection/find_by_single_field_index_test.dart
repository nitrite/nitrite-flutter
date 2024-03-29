import 'package:faker/faker.dart';
import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../../test_utils.dart';
import 'base_collection_test_loader.dart';

void main() {
  group(retry: 3, 'Collection Find by Single Field Index Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Find by Unique Index', () async {
      await insert();
      await collection.createIndex(['firstName']);

      var cursor = collection.find(filter: where("firstName").eq("fn1"));
      expect(await cursor.length, 1);

      cursor = collection.find(filter: where("firstName").eq("fn10"));
      expect(await cursor.length, 0);

      await collection.createIndex(['birthDay']);

      cursor = collection.find(
          filter:
              where("birthDay").gt(DateTime.parse("2012-07-01T16:02:48.440Z")));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: where("birthDay")
              .gte(DateTime.parse("2012-07-01T16:02:48.440Z")));
      expect(await cursor.length, 2);

      cursor = collection.find(
          filter:
              where("birthDay").lt(DateTime.parse("2012-07-01T16:02:48.440Z")));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: where("birthDay")
              .lte(DateTime.parse("2012-07-01T16:02:48.440Z")));
      expect(await cursor.length, 2);

      cursor = collection.find(filter: where("birthDay").lte(DateTime.now()));
      expect(await cursor.length, 3);

      cursor = collection.find(filter: where("birthDay").lt(DateTime.now()));
      expect(await cursor.length, 3);

      cursor = collection.find(filter: where("birthDay").gt(DateTime.now()));
      expect(await cursor.length, 0);

      cursor = collection.find(filter: where("birthDay").gte(DateTime.now()));
      expect(await cursor.length, 0);

      cursor = collection.find(
          filter: where("birthDay")
              .lte(DateTime.now())
              .and(where('firstName').eq('fn1')));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: where("birthDay")
              .lte(DateTime.now())
              .or(where('firstName').eq('fn12')));
      expect(await cursor.length, 3);

      cursor = collection.find(
          filter: and([
        or([
          where("birthDay").lte(DateTime.now()),
          where("firstName").eq("fn12")
        ]),
        where('lastName').eq('ln1'),
      ]));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: ~and([
        or([
          where("birthDay").lte(DateTime.now()),
          where("firstName").eq("fn12")
        ]),
        where('lastName').eq('ln1'),
      ]));
      expect(await cursor.length, 2);

      cursor = collection.find(filter: where('data.1').eq(4));
      expect(await cursor.length, 2);

      cursor = collection.find(filter: where('data.1').lt(4));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: where('lastName').within(['ln1', 'ln2', 'ln10']));
      expect(await cursor.length, 3);

      cursor =
          collection.find(filter: where('firstName').notIn(['fn1', 'fn2']));
      expect(await cursor.length, 1);
    });

    test('Test Find by Non Unique Index', () async {
      await insert();
      await collection
          .createIndex(['lastName'], indexOptions(IndexType.nonUnique));
      await collection
          .createIndex(['birthDay'], indexOptions(IndexType.nonUnique));

      var cursor = collection.find(filter: where("lastName").eq("ln2"));
      expect(await cursor.length, 2);

      cursor = collection.find(filter: where("lastName").eq("ln20"));
      expect(await cursor.length, 0);

      cursor = collection.find(
          filter:
              where("birthDay").gt(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: where("birthDay")
              .gte(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 2);

      cursor = collection.find(
          filter:
              where("birthDay").lt(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: where("birthDay")
              .lte(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 2);

      cursor = collection.find(filter: where("birthDay").lte(DateTime.now()));
      expect(await cursor.length, 3);

      cursor = collection.find(filter: where("birthDay").lt(DateTime.now()));
      expect(await cursor.length, 3);

      cursor = collection.find(filter: where("birthDay").gt(DateTime.now()));
      expect(await cursor.length, 0);

      cursor = collection.find(filter: where("birthDay").gte(DateTime.now()));
      expect(await cursor.length, 0);

      cursor = collection.find(
          filter: where("birthDay")
              .lte(DateTime.now())
              .and(where('firstName').eq('fn1')));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: where("birthDay")
              .lte(DateTime.now())
              .or(where('firstName').eq('fn12')));
      expect(await cursor.length, 3);

      cursor = collection.find(
          filter: and([
        or([
          where("birthDay").lte(DateTime.now()),
          where("firstName").eq("fn12")
        ]),
        where('lastName').eq('ln1'),
      ]));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: ~and([
        or([
          where("birthDay").lte(DateTime.now()),
          where("firstName").eq("fn12")
        ]),
        where('lastName').eq('ln1'),
      ]));
      expect(await cursor.length, 2);

      cursor = collection.find(filter: where('data.1').eq(4));
      expect(await cursor.length, 2);

      cursor = collection.find(filter: where('data.1').lt(4));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: where('lastName').within(['ln1', 'ln2', 'ln10']));
      expect(await cursor.length, 3);

      cursor =
          collection.find(filter: where('firstName').notIn(['fn1', 'fn2']));
      expect(await cursor.length, 1);
    });

    test('Test Find by Fulltext Index After Insert', () async {
      await insert();
      await collection.createIndex(['body'], indexOptions(IndexType.fullText));

      expect(await collection.hasIndex(['body']), isTrue);

      var cursor = collection.find(filter: where('body').text('Lorem'));
      expect(await cursor.length, 1);

      cursor = collection.find(filter: where('body').text('nosql'));
      expect(await cursor.length, 0);

      await collection.dropIndex(['body']);
      bool filterExceptions = false;
      try {
        cursor = collection.find(filter: where('body').text('Lorem'));
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

      var cursor = collection.find(filter: where('body').text('Lorem'));
      expect(await cursor.length, 1);

      cursor = collection.find(filter: where('body').text('quick brown'));
      expect(await cursor.length, 2);

      cursor = collection.find(filter: where('body').text('nosql'));
      expect(await cursor.length, 0);

      await collection.dropIndex(['body']);
      bool filterExceptions = false;
      try {
        cursor = collection.find(filter: where('body').text('Lorem'));
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

      var cursor = collection.find(findOptions: orderBy('birthDay'));
      expect(await cursor.length, 3);
      var dateList =
          await cursor.map((doc) => doc['birthDay'] as DateTime).toList();
      expect(isSorted(dateList, true), isTrue);
    });

    test('Test Find by Indexed Sort Descending', () async {
      await insert();
      await collection.createIndex(['birthDay']);

      var cursor = collection.find(
          findOptions: orderBy('birthDay', SortOrder.descending));
      expect(await cursor.length, 3);
      var dateList =
          await cursor.map((doc) => doc['birthDay'] as DateTime).toList();
      expect(isSorted(dateList, false), isTrue);
    });

    test('Test Find by Index Limit & Sort', () async {
      await insert();
      await collection.createIndex(['birthDay']);

      var cursor = collection.find(
          findOptions:
              orderBy('birthDay', SortOrder.descending).setSkip(1).setLimit(2));
      expect(await cursor.length, 2);
      var dateList =
          await cursor.map((doc) => doc['birthDay'] as DateTime).toList();
      expect(isSorted(dateList, false), isTrue);

      cursor = collection.find(
          findOptions: orderBy('birthDay').setSkip(1).setLimit(2));
      expect(await cursor.length, 2);
      dateList =
          await cursor.map((doc) => doc['birthDay'] as DateTime).toList();
      expect(isSorted(dateList, true), isTrue);

      cursor = collection.find(
          findOptions: orderBy('firstName').setSkip(0).setLimit(30));
      expect(await cursor.length, 3);
      var nameList =
          await cursor.map((doc) => doc['firstName'] as String).toList();
      expect(isSorted(nameList, true), isTrue);
    });

    test('Test Find After Dropped Index', () async {
      await insert();
      await collection.createIndex(['firstName']);

      var cursor = collection.find(filter: where('firstName').eq('fn1'));
      expect(await cursor.length, 1);

      await collection.dropIndex(['firstName']);
      cursor = collection.find(filter: where('firstName').eq('fn1'));
      expect(await cursor.length, 1);
    });

    test('Test Find Text with Wild Card', () async {
      await insert();
      await collection.createIndex(['body'], indexOptions(IndexType.fullText));

      var cursor = collection.find(filter: where('body').text('Lo'));
      expect(await cursor.length, 0);

      cursor = collection.find(filter: where('body').text('Lo*'));
      expect(await cursor.length, 1);

      cursor = collection.find(filter: where('body').text('*rem'));
      expect(await cursor.length, 1);

      cursor = collection.find(filter: where('body').text('*or*'));
      expect(await cursor.length, 2);
    });

    test('Test Find Text with Empty String', () async {
      await insert();
      await collection.createIndex(['body'], indexOptions(IndexType.fullText));

      var cursor = collection.find(filter: where('body').text(''));
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

      await collection.insertMany([doc1, doc2, doc3, doc4]);
      var cursor = collection.find(
          filter:
              where('firstName').eq('John').or(where('lastName').eq('Day')));
      expect(await cursor.length, 2);
    });

    test('Test Find with Multi-key Index', () async {
      var collection = await db.getCollection('testIssue45');
      var faker = Faker();

      var text1 = '${faker.lorem.sentence()} quick brown';
      var text2 = '${faker.lorem.sentence()} fox jump';
      var text3 = '${faker.lorem.sentence()} over lazy';
      var text4 = '${faker.lorem.sentence()} dog';

      var list1 = [text1, text2];
      var list2 = [text1, text2, text3];
      var list3 = [text2, text3];
      var list4 = [text1, text2, text3, text4];

      var doc1 = createDocument('firstName', 'John').put('notes', list1);
      var doc2 = createDocument('firstName', 'Jane').put('notes', list2);
      var doc3 = createDocument('firstName', 'Jonas').put('notes', list3);
      var doc4 = createDocument('firstName', 'Johan').put('notes', list4);

      await collection.createIndex(['notes'], indexOptions(IndexType.fullText));
      await collection.insertMany([doc1, doc2, doc3, doc4]);

      var cursor = collection.find(filter: where('notes').text('fox'));
      expect(await cursor.length, 4);

      cursor = collection.find(filter: where('notes').text('dog'));
      expect(await cursor.length, 1);

      cursor = collection.find(filter: where('notes').text('lazy'));
      expect(await cursor.length, 3);
    });

    test('Test Sort By Index Descending Less Than Equal', () async {
      var collection =
          await db.getCollection('testSortByIndexDescendingLessThanEqual');
      for (var i in [1, 2, 3, 4, 5]) {
        await collection.insert(createDocument('name', i));
      }

      var cursor = collection.find(
          filter: where("name").lte(3),
          findOptions: orderBy('name', SortOrder.descending));
      var nonIndexedResult = await cursor.map((e) => e['name'] as int).toList();

      await collection.createIndex(['name']);

      cursor = collection.find(
          filter: where("name").lte(3),
          findOptions: orderBy('name', SortOrder.descending));
      var indexedResult = await cursor.map((e) => e['name'] as int).toList();

      expect(nonIndexedResult, indexedResult);
    });

    test('Test Sort By Index Ascending Less Than Equal', () async {
      var collection =
          await db.getCollection('testSortByIndexAscendingLessThanEqual');
      for (var i in [1, 2, 3, 4, 5]) {
        await collection.insert(createDocument('name', i));
      }

      var cursor = collection.find(
          filter: where("name").lte(3),
          findOptions: orderBy('name', SortOrder.ascending));
      var nonIndexedResult = await cursor.map((e) => e['name'] as int).toList();

      await collection.createIndex(['name']);

      cursor = collection.find(
          filter: where("name").lte(3),
          findOptions: orderBy('name', SortOrder.ascending));
      var indexedResult = await cursor.map((e) => e['name'] as int).toList();

      expect(nonIndexedResult, indexedResult);
    });

    test('Test Sort By Index Descending Greater Than Equal', () async {
      var collection =
          await db.getCollection('testSortByIndexDescendingGreaterThanEqual');
      for (var i in [1, 2, 3, 4, 5]) {
        await collection.insert(createDocument('name', i));
      }

      var cursor = collection.find(
          filter: where("name").gte(3),
          findOptions: orderBy('name', SortOrder.descending));
      var nonIndexedResult = await cursor.map((e) => e['name'] as int).toList();

      await collection.createIndex(['name']);

      cursor = collection.find(
          filter: where("name").gte(3),
          findOptions: orderBy('name', SortOrder.descending));
      var indexedResult = await cursor.map((e) => e['name'] as int).toList();

      expect(nonIndexedResult, indexedResult);
    });

    test('Test Sort By Index Ascending Greater Than Equal', () async {
      var collection =
          await db.getCollection('testSortByIndexAscendingGreaterThanEqual');
      for (var i in [1, 2, 3, 4, 5]) {
        await collection.insert(createDocument('name', i));
      }

      var cursor = collection.find(
          filter: where("name").gte(3),
          findOptions: orderBy('name', SortOrder.ascending));
      var nonIndexedResult = await cursor.map((e) => e['name'] as int).toList();

      await collection.createIndex(['name']);

      cursor = collection.find(
          filter: where("name").gte(3),
          findOptions: orderBy('name', SortOrder.ascending));
      var indexedResult = await cursor.map((e) => e['name'] as int).toList();

      expect(nonIndexedResult, indexedResult);
    });

    test('Test Sort By Index Descending Greater Than', () async {
      var collection =
          await db.getCollection('testSortByIndexDescendingGreaterThan');
      for (var i in [1, 2, 3, 4, 5]) {
        await collection.insert(createDocument('name', i));
      }

      var cursor = collection.find(
          filter: where("name").gt(3),
          findOptions: orderBy('name', SortOrder.descending));
      var nonIndexedResult = await cursor.map((e) => e['name'] as int).toList();

      await collection.createIndex(['name']);

      cursor = collection.find(
          filter: where("name").gt(3),
          findOptions: orderBy('name', SortOrder.descending));
      var indexedResult = await cursor.map((e) => e['name'] as int).toList();

      expect(nonIndexedResult, indexedResult);
    });

    test('Test Sort By Index Ascending Greater Than', () async {
      var collection =
          await db.getCollection('testSortByIndexAscendingGreaterThan');
      for (var i in [1, 2, 3, 4, 5]) {
        await collection.insert(createDocument('name', i));
      }

      var cursor = collection.find(
          filter: where("name").gt(3),
          findOptions: orderBy('name', SortOrder.ascending));
      var nonIndexedResult = await cursor.map((e) => e['name'] as int).toList();

      await collection.createIndex(['name']);

      cursor = collection.find(
          filter: where("name").gt(3),
          findOptions: orderBy('name', SortOrder.ascending));
      var indexedResult = await cursor.map((e) => e['name'] as int).toList();

      expect(nonIndexedResult, indexedResult);
    });

    test('Test Sort By Index Descending Less Than', () async {
      var collection =
          await db.getCollection('testSortByIndexDescendingLessThan');
      for (var i in [1, 2, 3, 4, 5]) {
        await collection.insert(createDocument('name', i));
      }

      var cursor = collection.find(
          filter: where("name").lt(3),
          findOptions: orderBy('name', SortOrder.descending));
      var nonIndexedResult = await cursor.map((e) => e['name'] as int).toList();

      await collection.createIndex(['name']);

      cursor = collection.find(
          filter: where("name").lt(3),
          findOptions: orderBy('name', SortOrder.descending));
      var indexedResult = await cursor.map((e) => e['name'] as int).toList();

      expect(nonIndexedResult, indexedResult);
    });

    test('Test Sort By Index Ascending Less Than', () async {
      var collection =
          await db.getCollection('testSortByIndexAscendingLessThan');
      for (var i in [1, 2, 3, 4, 5]) {
        await collection.insert(createDocument('name', i));
      }

      var cursor = collection.find(
          filter: where("name").lt(3),
          findOptions: orderBy('name', SortOrder.ascending));
      var nonIndexedResult = await cursor.map((e) => e['name'] as int).toList();

      await collection.createIndex(['name']);

      cursor = collection.find(
          filter: where("name").lt(3),
          findOptions: orderBy('name', SortOrder.ascending));
      var indexedResult = await cursor.map((e) => e['name'] as int).toList();

      expect(nonIndexedResult, indexedResult);
    });
  });
}
