import 'package:nitrite/nitrite.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import 'base_collection_test_loader.dart';

void main() {
  group('Find By Compound Index Test Suite', () {
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
      var cursor = await collection.find(
          filter: and([
        where('lastName').eq('ln2'),
        where("firstName").notEq("fn1"),
        where("list").eq("four")
      ]));

      var findPlan = cursor.findPlan;
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

      var cursor = await collection.find(
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

      var findPlan = cursor.findPlan;
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
      cursor = await collection.find(
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
    });
  });
}
