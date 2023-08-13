import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/filters/filter.dart';
import 'package:test/test.dart';

import 'base_collection_test_loader.dart';

void main() {
  group(retry: 3, 'Find By Compound Index Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Find By AND Filter', () async {
      await insert();

      await collection.createIndex(['list', 'lastName', 'firstName']);
      var cursor = collection.find(
          filter: and([
        where('lastName').eq('ln2'),
        where("firstName").notEq("fn1"),
        where("list").eq("four")
      ]));

      var findPlan = await cursor.findPlan;
      expect(findPlan.collectionScanFilter, isNull);
      expect(findPlan.indexDescriptor, isNotNull);
      expect(findPlan.indexDescriptor, (await collection.listIndexes()).first);

      var indexScanFilter = findPlan.indexScanFilter;
      expect(indexScanFilter?.filters.first, where('list').eq('four'));
      expect(
          indexScanFilter?.filters.skip(1).first, where('lastName').eq('ln2'));
      expect(indexScanFilter?.filters.skip(2).first,
          where('firstName').notEq('fn1'));

      expectLater(cursor.length, completion(1));
      expectLater(cursor.first,
          completion(containsPair('body', 'quick hello world from nitrite')));
    });

    test('Test Find by OR Filter & AND Filter', () async {
      await insert();
      await collection.createIndex(['lastName', 'firstName']);

      var cursor = collection.find(
          filter: or([
        and([
          where("lastName").eq("ln2"),
          where("firstName").notEq("fn1"),
        ]),
        and([
          where("firstName").eq("fn3"),
          where("lastName").eq("ln2"),
        ])
      ]));

      var findPlan = await cursor.findPlan;
      expect(findPlan.collectionScanFilter, isNull);
      expect(findPlan.indexScanFilter, isNull);
      expect(findPlan.subPlans, isNotNull);

      expect(findPlan.subPlans.length, 2);
      expect(findPlan.subPlans[0].indexScanFilter, isNotNull);
      expect(findPlan.subPlans[1].indexScanFilter, isNotNull);
      expect(findPlan.distinct, isFalse);

      expect(
          await cursor
              .where((d) => d['firstName'] == 'fn2' && d['lastName'] == 'ln2')
              .length,
          1);
      expect(
          await cursor
              .where((d) => d['firstName'] == 'fn3' && d['lastName'] == 'ln2')
              .length,
          2);

      // distinct test
      cursor = collection.find(
          filter: or([
            and([
              where("lastName").eq("ln2"),
              where("firstName").notEq("fn1"),
            ]),
            and([
              where("firstName").eq("fn3"),
              where("lastName").eq("ln2"),
            ])
          ]),
          findOptions: distinct());

      expect(await cursor.length, 2);

      findPlan = await cursor.findPlan;
      expect(findPlan.collectionScanFilter, isNull);
      expect(findPlan.indexScanFilter, isNull);
      expect(findPlan.subPlans, isNotNull);

      expect(findPlan.subPlans.length, 2);
      expect(findPlan.subPlans[0].indexScanFilter, isNotNull);
      expect(findPlan.subPlans[1].indexScanFilter, isNotNull);
      expect(findPlan.distinct, isTrue);

      expect(
          await cursor
              .where((d) => d['firstName'] == 'fn2' && d['lastName'] == 'ln2')
              .length,
          1);
      expect(
          await cursor
              .where((d) => d['firstName'] == 'fn3' && d['lastName'] == 'ln2')
              .length,
          1);
    });

    test('Test Find AND Filter & OR Filter', () async {
      await insert();
      await collection.createIndex(['lastName', 'firstName']);

      var cursor = collection.find(
          filter: and([
        or([
          where("lastName").eq("ln2"),
          where("firstName").notEq("fn1"),
        ]),
        or([
          where("firstName").eq("fn3"),
          where("lastName").eq("ln2"),
        ]),
      ]));

      expect(await cursor.length, 2);

      var findPlan = await cursor.findPlan;
      expect(findPlan.indexScanFilter, isNull);
      expect(findPlan.collectionScanFilter, isNotNull);
      expect(findPlan.subPlans, isEmpty);

      expect(
          await cursor
              .where((d) => d['firstName'] == 'fn2' && d['lastName'] == 'ln2')
              .length,
          1);
      expect(
          await cursor
              .where((d) => d['firstName'] == 'fn3' && d['lastName'] == 'ln2')
              .length,
          1);
    });

    test('Test Find by AND Filter & AND Filter', () async {
      await insert();
      await collection.createIndex(['lastName', 'firstName']);

      var cursor = collection.find(
          filter: and([
        and([
          where("lastName").eq("ln2"),
          where("firstName").notEq("fn1"),
        ]),
        and([
          where("firstName").eq("fn3"),
          where("lastName").eq("ln2"),
        ]),
      ]));

      expect(await cursor.length, 1);
      var findPlan = await cursor.findPlan;
      expect(findPlan.indexScanFilter, isNotNull);
      expect(findPlan.collectionScanFilter, isNotNull);
      expect(findPlan.subPlans, isEmpty);

      var indexes = await collection.listIndexes();
      expect(findPlan.indexDescriptor, indexes.first);
      expect(
          findPlan.indexScanFilter?.filters,
          (and([where("lastName").eq("ln2"), where("firstName").notEq("fn1")])
                  as AndFilter)
              .filters);
      expect(findPlan.collectionScanFilter, where("firstName").eq("fn3"));

      expect(await cursor.first, containsPair('firstName', 'fn3'));
    });

    test('Test Find by OR Filter', () async {
      await insert();
      await collection.createIndex(['lastName', 'firstName']);
      await collection.createIndex(['firstName']);
      await collection.createIndex(['birthDay']);

      var cursor = collection.find(
          filter: or([
        or([
          where("lastName").eq("ln2"),
          where("firstName").notEq("fn1"),
        ]),
        where('birthDay').eq(DateTime.parse('2012-07-01T16:02:48.440Z')),
        where("firstName").notEq("fn1")
      ]));

      var findPlan = await cursor.findPlan;
      expect(findPlan.subPlans.length, 3);
      expect(await cursor.length, 5);

      // with distinct
      cursor = collection.find(
          filter: or([
            or([
              where("lastName").eq("ln2"),
              where("firstName").notEq("fn1"),
            ]),
            where('birthDay').eq(DateTime.parse('2012-07-01T16:02:48.440Z')),
            where("firstName").notEq("fn1")
          ]),
          findOptions: distinct());

      findPlan = await cursor.findPlan;
      expect(findPlan.subPlans.length, 3);
      expect(await cursor.length, 3);
    });

    test('Test Find with OR Filter No Index', () async {
      await insert();
      await collection.createIndex(['lastName', 'firstName']);
      await collection.createIndex(['firstName']);

      var cursor = collection.find(
          filter: or([
        or([
          where("lastName").eq("ln2"),
          where("firstName").notEq("fn1"),
        ]),
        where('birthDay').eq(DateTime.parse('2012-07-01T16:02:48.440Z')),
        where("firstName").notEq("fn1")
      ]));

      var findPlan = await cursor.findPlan;
      expect(findPlan.subPlans.length, 0);
      expect(await cursor.length, 3);
    });

    test('Test Find with AND Filter No Index', () async {
      await insert();
      await collection.createIndex(['lastName', 'firstName']);

      var cursor = collection.find(
          filter: and([
        where('birthDay').eq(DateTime.parse('2012-07-01T16:02:48.440Z')),
        where("firstName").notEq("fn1")
      ]));

      var findPlan = await cursor.findPlan;
      expect(findPlan.indexScanFilter, isNull);
      expect(findPlan.indexDescriptor, isNull);
      expect(findPlan.collectionScanFilter, isNotNull);

      expect(await cursor.length, 0);
    });

    test('Test Sort By Index', () async {
      await collection.createIndex(['lastName', 'birthDay']);
      var doc = createDocument("firstName", "fn4")
          .put("lastName", "ln3")
          .put("birthDay", DateTime.parse("2016-04-17T16:02:48.440Z"))
          .put("data", [9, 4, 8]).put(
              "body",
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
                  "Sed nunc mi, mattis ullamcorper dignissim vitae, condimentum "
                  "non lorem.");

      await collection.insertMany([doc, doc3, doc1, doc2]);
      var cursor = collection.find(
          filter: and([
            where("lastName").notEq("ln1"),
            where("birthDay").notEq(DateTime.parse("2012-07-01T16:02:48.440Z"))
          ]),
          findOptions: orderBy('lastName')
              .thenOrderBy('birthDay', SortOrder.descending));

      expect(await cursor.length, 3);

      var document = await cursor.first;
      expect(document['lastName'], "ln2");
      expect(document['birthDay'], DateTime.parse("2014-04-17T16:02:48.440Z"));

      document = await cursor.skip(1).first;
      expect(document['lastName'], "ln2");
      expect(document['birthDay'], DateTime.parse("2010-06-12T16:02:48.440Z"));

      document = await cursor.skip(2).first;
      expect(document['lastName'], "ln3");
      expect(document['birthDay'], DateTime.parse("2016-04-17T16:02:48.440Z"));

      var findPlan = await cursor.findPlan;
      expect(findPlan.blockingSortOrder, isEmpty);
      expect(findPlan.collectionScanFilter, isNull);
      expect(findPlan.indexDescriptor, isNotNull);
      expect(findPlan.indexScanOrder['lastName'], isFalse);

      // reverse scan
      expect(findPlan.indexScanOrder['birthDay'], isTrue);
    });

    test('Test Blocking Sort', () async {
      var doc = createDocument("firstName", "fn4")
          .put("lastName", "ln3")
          .put("birthDay", DateTime.parse("2016-04-17T16:02:48.440Z"))
          .put("data", [9, 4, 8]).put(
              "body",
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
                  "Sed nunc mi, mattis ullamcorper dignissim vitae, condimentum "
                  "non lorem.");

      await collection.insertMany([doc, doc3, doc1, doc2]);
      var cursor = collection.find(
          filter: and([
            where("lastName").notEq("ln1"),
            where("birthDay").notEq(DateTime.parse("2012-07-01T16:02:48.440Z"))
          ]),
          findOptions: orderBy('lastName')
              .thenOrderBy('birthDay', SortOrder.descending));

      expect(await cursor.length, 3);

      var document = await cursor.first;
      expect(document['lastName'], "ln2");
      expect(document['birthDay'], DateTime.parse("2014-04-17T16:02:48.440Z"));

      document = await cursor.skip(1).first;
      expect(document['lastName'], "ln2");
      expect(document['birthDay'], DateTime.parse("2010-06-12T16:02:48.440Z"));

      document = await cursor.skip(2).first;
      expect(document['lastName'], "ln3");
      expect(document['birthDay'], DateTime.parse("2016-04-17T16:02:48.440Z"));

      var findPlan = await cursor.findPlan;
      expect(findPlan.collectionScanFilter, isNotNull);
      expect(findPlan.indexDescriptor, isNull);
      expect(findPlan.indexScanOrder, isEmpty);

      var blockingSortOrder = findPlan.blockingSortOrder;
      expect(blockingSortOrder.length, 2);

      var pair = blockingSortOrder.first;
      expect(pair.$1, 'lastName');
      expect(pair.$2, SortOrder.ascending);

      pair = blockingSortOrder.last;
      expect(pair.$1, 'birthDay');
      expect(pair.$2, SortOrder.descending);
    });

    test('Test Sort Not Covered By Index', () async {
      await collection
          .createIndex(['lastName'], indexOptions(IndexType.nonUnique));

      var doc = createDocument("firstName", "fn4")
          .put("lastName", "ln3")
          .put("birthDay", DateTime.parse("2016-04-17T16:02:48.440Z"))
          .put("data", [9, 4, 8]).put(
              "body",
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
                  "Sed nunc mi, mattis ullamcorper dignissim vitae, condimentum "
                  "non lorem.");

      await collection.insertMany([doc, doc3, doc1, doc2]);
      var cursor = collection.find(
          filter: and([
            where("lastName").notEq("ln1"),
            where("birthDay").notEq(DateTime.parse("2012-07-01T16:02:48.440Z"))
          ]),
          findOptions: orderBy('lastName')
              .thenOrderBy('birthDay', SortOrder.descending));

      expect(await cursor.length, 3);

      var document = await cursor.first;
      expect(document['lastName'], "ln2");
      expect(document['birthDay'], DateTime.parse("2014-04-17T16:02:48.440Z"));

      document = await cursor.skip(1).first;
      expect(document['lastName'], "ln2");
      expect(document['birthDay'], DateTime.parse("2010-06-12T16:02:48.440Z"));

      document = await cursor.skip(2).first;
      expect(document['lastName'], "ln3");
      expect(document['birthDay'], DateTime.parse("2016-04-17T16:02:48.440Z"));

      var findPlan = await cursor.findPlan;
      expect(findPlan.collectionScanFilter, isNotNull);
      expect(findPlan.indexDescriptor, isNotNull);
      expect(findPlan.indexScanOrder, isEmpty);

      var blockingSortOrder = findPlan.blockingSortOrder;
      expect(blockingSortOrder.length, 2);

      var pair = blockingSortOrder.first;
      expect(pair.$1, 'lastName');
      expect(pair.$2, SortOrder.ascending);

      pair = blockingSortOrder.last;
      expect(pair.$1, 'birthDay');
      expect(pair.$2, SortOrder.descending);
    });

    test('Test Sort By Index Prefix', () async {
      await collection.createIndex(['lastName', 'birthDay']);

      var doc = createDocument("firstName", "fn4")
          .put("lastName", "ln3")
          .put("birthDay", DateTime.parse("2016-04-17T16:02:48.440Z"))
          .put("data", [9, 4, 8]).put(
              "body",
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
                  "Sed nunc mi, mattis ullamcorper dignissim vitae, condimentum "
                  "non lorem.");

      await collection.insertMany([doc, doc3, doc1, doc2]);
      var cursor = collection.find(
          filter: and([
            where("lastName").notEq("ln1"),
            where("birthDay").notEq(DateTime.parse("2012-07-01T16:02:48.440Z"))
          ]),
          findOptions: orderBy('lastName'));

      expect(await cursor.length, 3);

      var document = await cursor.first;
      expect(document['lastName'], "ln2");
      // duplicate birthday will have natural sort order - ascending
      expect(document['birthDay'], DateTime.parse("2010-06-12T16:02:48.440Z"));

      document = await cursor.skip(1).first;
      expect(document['lastName'], "ln2");
      expect(document['birthDay'], DateTime.parse("2014-04-17T16:02:48.440Z"));

      document = await cursor.skip(2).first;
      expect(document['lastName'], "ln3");
      expect(document['birthDay'], DateTime.parse("2016-04-17T16:02:48.440Z"));

      var findPlan = await cursor.findPlan;
      expect(findPlan.collectionScanFilter, isNull);
      expect(findPlan.indexDescriptor, isNotNull);
      expect(findPlan.indexScanOrder['lastName'], isFalse);
      expect(findPlan.blockingSortOrder, isEmpty);
    });

    test('Test Limit and Skip', () async {
      await collection.createIndex(['lastName', 'birthDay']);

      var doc = createDocument("firstName", "fn4")
          .put("lastName", "ln3")
          .put("birthDay", DateTime.parse("2016-04-17T16:02:48.440Z"))
          .put("data", [9, 4, 8]).put(
              "body",
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
                  "Sed nunc mi, mattis ullamcorper dignissim vitae, condimentum "
                  "non lorem.");

      await collection.insertMany([doc, doc3, doc1, doc2]);
      var cursor = collection.find(
          filter: and([
            where("lastName").notEq("ln1"),
            where("birthDay").notEq(DateTime.parse("2012-07-01T16:02:48.440Z"))
          ]),
          findOptions: orderBy('lastName')
              .thenOrderBy('birthDay', SortOrder.descending)
              .setSkip(2)
              .setLimit(1));

      expect(await cursor.length, 1);

      var document = await cursor.first;
      expect(document['lastName'], "ln3");
      expect(document['birthDay'], DateTime.parse("2016-04-17T16:02:48.440Z"));

      var findPlan = await cursor.findPlan;
      expect(findPlan.blockingSortOrder, isEmpty);
      expect(findPlan.collectionScanFilter, isNull);
      expect(findPlan.indexDescriptor, isNotNull);
      expect(findPlan.indexScanOrder['lastName'], isFalse);
      expect(findPlan.indexScanOrder['birthDay'], isTrue);
      expect(findPlan.skip, 2);
      expect(findPlan.limit, 1);
    });
  });
}
