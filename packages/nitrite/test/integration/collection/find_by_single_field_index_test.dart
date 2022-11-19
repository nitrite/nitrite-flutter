import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'base_collection_test_loader.dart';

void main() {
  group('Collection Find by Single Field Index Test Suite', () {
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
  });
}
