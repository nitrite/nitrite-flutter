import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';
import '../string_field_encryption_processor.dart';
import 'base_collection_test.dart';

void main() {
  group("Collection Find Test Suite", () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test("Test Find All", () async {
      await insert();

      var cursor = await collection.find();
      expect(await cursor.length, 3);
    });

    test("Test Find with Filter", () async {
      await insert();

      var cursor = await collection.find(
          filter:
              where('birthDay').gt(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 1);

      var doc = await cursor.first;
      expect(doc.get('firstName'), 'fn3');
      expect(doc.get('lastName'), 'ln2');

      cursor = await collection.find(
          filter: where('birthDay')
              .gte(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 2);

      cursor = await collection.find(
          filter:
              where('birthDay').lt(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: where('birthDay')
              .lte(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 2);

      cursor =
          await collection.find(filter: where('birthDay').lte(DateTime.now()));
      expect(await cursor.length, 3);

      cursor =
          await collection.find(filter: where('birthDay').lt(DateTime.now()));
      expect(await cursor.length, 3);

      cursor =
          await collection.find(filter: where('birthDay').gt(DateTime.now()));
      expect(await cursor.length, 0);

      cursor =
          await collection.find(filter: where('birthDay').gte(DateTime.now()));
      expect(await cursor.length, 0);

      cursor = await collection.find(
          filter: where('birthDay')
              .lte(DateTime.now())
              .and(where('firstName').eq('fn1')));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: where('birthDay')
              .lte(DateTime.now())
              .or(where('firstName').eq('fn12')));
      expect(await cursor.length, 3);

      cursor = await collection.find(
          filter: and([
        or([
          where('birthDay').lte(DateTime.now()),
          where('firstName').eq('fn12'),
        ]),
        where('lastName').eq('ln1')
      ]));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: and([
        or([
          where('birthDay').lte(DateTime.now()),
          where('firstName').eq('fn12'),
        ]),
        where('lastName').eq('ln1')
      ]).not());
      expect(await cursor.length, 2);

      cursor = await collection.find(
          filter: ~and([
        or([
          where('birthDay').lte(DateTime.now()),
          where('firstName').eq('fn12'),
        ]),
        where('lastName').eq('ln1')
      ]));
      expect(await cursor.length, 2);

      cursor = await collection.find(filter: where('data.1').eq(4));
      expect(await cursor.length, 2);

      cursor = await collection.find(filter: where('data.1').lt(4));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: where('lastName').within(["ln1", "ln2", "ln10"]));
      expect(await cursor.length, 3);

      cursor = await collection.find(
          filter: where('firstName').notIn(["fn1", "fn2"]));
      expect(await cursor.length, 1);

      cursor = await collection.find(filter: ~all);
      expect(await cursor.length, 0);

      cursor = await collection.find(filter: all.not());
      expect(await cursor.length, 0);
    });

    test("Test Find with Skip Limit", () async {
      await insert();

      var cursor = await collection.find(findOptions: skipBy(0).setLimit(1));
      expect(await cursor.length, 1);

      cursor = await collection.find(findOptions: skipBy(1).setLimit(3));
      expect(await cursor.length, 2);

      cursor = await collection.find(findOptions: skipBy(0).setLimit(30));
      expect(await cursor.length, 3);

      cursor = await collection.find(findOptions: skipBy(2).setLimit(3));
      expect(await cursor.length, 1);
    });

    test("Test Find with Skip", () async {
      await insert();

      var cursor = await collection.find(findOptions: skipBy(0));
      expect(await cursor.length, 3);

      cursor = await collection.find(findOptions: skipBy(1));
      expect(await cursor.length, 2);

      cursor = await collection.find(findOptions: skipBy(30));
      expect(await cursor.length, 0);

      cursor = await collection.find(findOptions: skipBy(2));
      expect(await cursor.length, 1);

      expect(() async => await collection.find(findOptions: skipBy(-2)),
          throwsValidationException);
    });

    test("Test Find with Limit", () async {
      await insert();

      var cursor = await collection.find(findOptions: limitBy(0));
      expect(await cursor.length, 0);

      cursor = await collection.find(findOptions: limitBy(1));
      expect(await cursor.length, 1);

      cursor = await collection.find(findOptions: limitBy(30));
      expect(await cursor.length, 3);

      expect(() async => await collection.find(findOptions: limitBy(-1)),
          throwsValidationException);
    });

    test("Test Find with Sort Ascending", () async {
      await insert();

      var cursor = await collection.find(
          findOptions: orderBy('birthDay', SortOrder.ascending));
      expect(await cursor.length, 3);
      var dateList = <DateTime>[];
      await for (var document in cursor) {
        dateList.add(document.get('birthDay') as DateTime);
      }

      expect(isSorted<DateTime>(dateList, true), isTrue);
    });

    test("Test Find with Sort Descending", () async {
      await insert();

      var cursor = await collection.find(
          findOptions: orderBy('birthDay', SortOrder.descending));
      expect(await cursor.length, 3);
      var dateList = <DateTime>[];
      await for (var document in cursor) {
        dateList.add(document.get('birthDay') as DateTime);
      }

      expect(isSorted<DateTime>(dateList, false), isTrue);
    });

    test("Test Find with Limit & Sort", () async {
      await insert();

      var cursor = await collection.find(
          findOptions:
              orderBy('birthDay', SortOrder.descending).setSkip(1).setLimit(2));
      expect(await cursor.length, 2);
      var dateList = <DateTime>[];
      await for (var document in cursor) {
        dateList.add(document.get('birthDay') as DateTime);
      }
      expect(isSorted<DateTime>(dateList, false), isTrue);

      cursor = await collection.find(
          findOptions: orderBy('birthDay').setSkip(1).setLimit(2));
      expect(await cursor.length, 2);
      dateList = <DateTime>[];
      await for (var document in cursor) {
        dateList.add(document.get('birthDay') as DateTime);
      }
      expect(isSorted<DateTime>(dateList, true), isTrue);

      cursor = await collection.find(
          findOptions: orderBy('firstName').setSkip(0).setLimit(30));
      expect(await cursor.length, 3);
      var nameList = <String>[];
      await for (var document in cursor) {
        nameList.add(document.get('firstName') as String);
      }
      expect(isSorted<String>(nameList, true), isTrue);
    });

    test("Test Find with Sort on NonExisting Field", () async {
      await insert();

      var cursor = await collection.find(
          findOptions: orderBy('my-value', SortOrder.descending));
      expect(await cursor.length, 3);

      var dateList = <DateTime>[];
      await for (var document in cursor) {
        dateList.add(document.get('birthDay') as DateTime);
      }
      expect(isSorted<DateTime>(dateList, false), isFalse);
    });

    test("Test Find with Invalid Field", () async {
      await insert();

      var cursor = await collection.find(filter: where('myField').eq('myData'));
      expect(await cursor.length, 0);

      cursor = await collection.find(filter: where('myField').notEq(null));
      expect(await cursor.length, 0);

      cursor = await collection.find(filter: where('myField').eq(null));
      expect(await cursor.length, 3);
    });

    test("Test Find with Invalid Field with Invalid Accessor", () async {
      await insert();

      var cursor =
          await collection.find(filter: where('myField.0').eq('myData'));
      expect(await cursor.length, 0);

      cursor = await collection.find(filter: where('myField.0').notEq(null));
      expect(await cursor.length, 0);

      cursor = await collection.find(filter: where('myField.0').eq(null));
      expect(await cursor.length, 3);
    });

    test("Test Find with Invalid Field with Invalid Accessor", () async {
      await insert();

      var cursor =
          await collection.find(filter: where('myField.0').eq('myData'));
      expect(await cursor.length, 0);

      cursor = await collection.find(filter: where('myField.0').notEq(null));
      expect(await cursor.length, 0);

      cursor = await collection.find(filter: where('myField.0').eq(null));
      expect(await cursor.length, 3);
    });

    test("Test Find with Limit And Sort on Invalid Field", () async {
      await insert();

      var cursor = await collection.find(
          findOptions: orderBy('birthDay2', SortOrder.descending)
              .setSkip(1)
              .setLimit(2));
      expect(await cursor.length, 2);
    });

    test("Test Get by Id", () async {
      await collection.insert([doc1]);
      var id = NitriteId.createId('1');
      var doc = await collection.getById(id);
      expect(doc, isNull);

      doc = await (await collection.find()).first;
      id = doc.id;

      doc = await collection.getById(id);
      expect(doc, isNotNull);
      doc!;

      expect(doc[docId], doc.id.idValue);
      expect(doc['firstName'], 'fn1');
      expect(doc['lastName'], 'ln1');
      expect(doc['data'], [1, 2, 3]);
      expect(doc['body'], 'a quick brown fox jump over the lazy dog');
    });

    test("Test Find with Filter and FindOptions", () async {
      await insert();

      var cursor = await collection.find(
          filter: where('birthDay').lte(DateTime.now()),
          findOptions: orderBy('firstName').setSkip(1).setLimit(2));
      expect(await cursor.length, 2);

      expect(cursor.map((d) => d['firstName']), emitsInOrder(['fn2', 'fn3']));
    });

    test("Test Find Text with Regex", () async {
      await insert();

      var cursor = await collection.find(filter: where('body').regex(r'hello'));
      expect(await cursor.length, 1);

      cursor = await collection.find(filter: where('body').regex(r'[0-9]+'));
      expect(await cursor.length, 0);

      cursor = await collection.find(filter: where('body').regex('test'));
      expect(await cursor.length, 0);

      cursor = await collection.find(filter: where('body').regex(r'^hello$'));
      expect(await cursor.length, 0);

      cursor = await collection.find(filter: where('body').regex(r'.*'));
      expect(await cursor.length, 3);
    });

    test("Test Find Result", () async {
      await insert();

      var cursor = await collection.find(
          filter: where('birthDay').lte(DateTime.now()),
          findOptions: orderBy('firstName').setSkip(0).setLimit(3));

      var iter = 0;
      await for (var doc in cursor) {
        switch (iter) {
          case 0:
            expect(
                isSimilarDocument(doc, doc1, [
                  "firstName",
                  "lastName",
                  "birthDay",
                  "data",
                  "list",
                  "body"
                ]),
                isTrue);
            break;
          case 1:
            expect(
                isSimilarDocument(doc, doc2, [
                  "firstName",
                  "lastName",
                  "birthDay",
                  "data",
                  "list",
                  "body"
                ]),
                isTrue);
            break;
          case 2:
            expect(
                isSimilarDocument(doc, doc3, [
                  "firstName",
                  "lastName",
                  "birthDay",
                  "data",
                  "list",
                  "body"
                ]),
                isTrue);
            break;
        }
        iter++;
      }

      expect(iter, 3);
    });

    test("Test Projection", () async {
      var doc1 = emptyDocument()
        ..put('name', 'John')
        ..put(
            'address',
            emptyDocument()
              ..put('street', 'Main Street')
              ..put('city', 'New York')
              ..put('state', 'NY')
              ..put('zip', '10001'));

      var doc2 = emptyDocument()
        ..put('name', 'Jane')
        ..put(
            'address',
            emptyDocument()
              ..put('street', 'Other Street')
              ..put('city', 'New Jersey')
              ..put('state', 'NJ')
              ..put('zip', '70001'));

      var collection = await db.getCollection('person');
      await collection.insert([doc1, doc2]);

      var processor = StringFieldEncryptionProcessor();
      processor.addFields(['name']);
      await processor.process(collection);
      await collection.addProcessor(processor);

      var projection = emptyDocument()
        ..put('name', null)
        ..put('address.city', null)
        ..put('address.state', null);

      var cursor = await collection.find();
      var stream = cursor.project(projection);

      expect(await stream.length, 2);
      expect(
          stream,
          emitsInOrder([
            emptyDocument()
              ..put('name', 'John')
              ..put(
                  'address',
                  emptyDocument()
                    ..put('city', 'New York')
                    ..put('state', 'NY')),
            emptyDocument()
              ..put('name', 'Jane')
              ..put(
                  'address',
                  emptyDocument()
                    ..put('city', 'New Jersey')
                    ..put('state', 'NJ'))
          ]));
    });

    test('Test Find with List Equal', () async {
      await insert();

      var data = await collection.find(filter: where('data').eq([3, 4, 3]));
      expect(data, isNotNull);
      expect(await data.length, 1);
    });

    test('Test Find with List with Wrong Order', () async {
      await insert();

      var data = await collection.find(filter: where('data').eq([4, 3, 3]));
      expect(data, isNotNull);
      expect(await data.length, 0);
    });

    test("Test Find in List", () async {
      await insert();

      var cursor = await collection.find(
          filter: where('data').elemMatch($.gte(2).and($.lt(5))));
      expect(await cursor.length, 3);

      cursor = await collection.find(
          filter: where('data').elemMatch($.gt(2).or($.lte(5))));
      expect(await cursor.length, 3);

      cursor = await collection.find(
          filter: where('data').elemMatch($.gt(1).and($.lt(4))));
      expect(await cursor.length, 2);
    });

    test("Test ElemMatch Filter", () async {
      var doc1 = emptyDocument()
        ..put('productScores', [
          emptyDocument()
            ..put('product', 'abc')
            ..put('score', 10),
          emptyDocument()
            ..put('product', 'xyz')
            ..put('score', 5),
        ])
        ..put('strArray', ["a", "b"]);

      var doc2 = emptyDocument()
        ..put('productScores', [
          emptyDocument()
            ..put('product', 'abc')
            ..put('score', 8),
          emptyDocument()
            ..put('product', 'xyz')
            ..put('score', 7),
        ])
        ..put('strArray', ["d", "e"]);

      var doc3 = emptyDocument()
        ..put('productScores', [
          emptyDocument()
            ..put('product', 'abc')
            ..put('score', 7),
          emptyDocument()
            ..put('product', 'xyz')
            ..put('score', 8),
        ])
        ..put('strArray', ["a", "f"]);

      var prodCollection = await db.getCollection('prodScore');
      await prodCollection.insert([doc1, doc2, doc3]);

      var cursor = await prodCollection.find(
          filter: where('productScores').elemMatch(
              where('product').eq('xyz').and(where('score').gte(8))));
      expect(await cursor.length, 1);

      cursor = await prodCollection.find(
          filter:
              where("productScores").elemMatch(where("score").lte(8).not()));
      expect(await cursor.length, 1);

      cursor = await prodCollection.find(
          filter: where("productScores")
              .elemMatch(where("product").eq("xyz").or(where("score").gte(8))));
      expect(await cursor.length, 3);

      cursor = await prodCollection.find(
          filter: where("productScores").elemMatch(where("product").eq("xyz")));
      expect(await cursor.length, 3);

      cursor = await prodCollection.find(
          filter: where("productScores").elemMatch(where("score").gte(10)));
      expect(await cursor.length, 1);

      cursor = await prodCollection.find(
          filter: where("productScores").elemMatch(where("score").gt(8)));
      expect(await cursor.length, 1);

      cursor = await prodCollection.find(
          filter: where("productScores").elemMatch(where("score").lt(7)));
      expect(await cursor.length, 1);

      cursor = await prodCollection.find(
          filter: where("productScores").elemMatch(where("score").lte(7)));
      expect(await cursor.length, 3);

      cursor = await prodCollection.find(
          filter:
              where("productScores").elemMatch(where("score").within([7, 8])));
      expect(await cursor.length, 2);

      cursor = await prodCollection.find(
          filter:
              where("productScores").elemMatch(where("score").notIn([7, 8])));
      expect(await cursor.length, 1);

      cursor = await prodCollection.find(
          filter:
              where("productScores").elemMatch(where("product").regex("xyz")));
      expect(await cursor.length, 3);

      cursor = await prodCollection.find(
          filter: where("strArray").elemMatch($.eq("a")));
      expect(await cursor.length, 2);

      cursor = await prodCollection.find(
          filter: where("strArray")
              .elemMatch($.eq("a").or($.eq("f").or($.eq("b"))).not()));
      expect(await cursor.length, 1);

      cursor = await prodCollection.find(
          filter: where("strArray").elemMatch($.gt("e")));
      expect(await cursor.length, 1);

      cursor = await prodCollection.find(
          filter: where("strArray").elemMatch($.gte("e")));
      expect(await cursor.length, 2);

      cursor = await prodCollection.find(
          filter: where("strArray").elemMatch($.lte("b")));
      expect(await cursor.length, 2);

      cursor = await prodCollection.find(
          filter: where("strArray").elemMatch($.lt("a")));
      expect(await cursor.length, 0);

      cursor = await prodCollection.find(
          filter: where("strArray").elemMatch($.within(["a", "f"])));
      expect(await cursor.length, 2);

      cursor = await prodCollection.find(
          filter: where("strArray").elemMatch($.regex("a")));
      expect(await cursor.length, 2);
    });

    test("Test NotEqual Filter", () async {
      var doc = emptyDocument()
        ..put('abc', '123')
        ..put('xyz', null);

      await collection.insert([doc]);
      var cursor = await collection.find(filter: where("abc").eq("123"));
      expect(await cursor.length, 1);

      cursor = await collection.find(filter: where("xyz").eq(null));
      expect(await cursor.length, 1);

      cursor = await collection.find(filter: where("abc").notEq(null));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: where("abc").notEq(null).and(where("xyz").eq(null)));
      expect(await cursor.length, 1);

      cursor = await collection.find(
          filter: where("abc").eq(null).and(where("xyz").notEq(null)));
      expect(await cursor.length, 0);

      await collection.remove(all);

      doc = emptyDocument()
        ..put('field', 'two')
        ..put('revision', 1482225343161);

      await collection.insert([doc]);
      cursor = await collection.find(
          filter: where('revision').gte(1482225343160).and(where('revision')
              .lte(1482225343162)
              .and(where('revision').notEq(null))));
      var projected = await cursor.first;
      expect(projected, isNotNull);
    });

    test("Test Filter All", () async {
      var cursor = await collection.find(filter: all);
      expect(cursor, isNotNull);
      expect(await cursor.length, 0);

      await insert();

      cursor = await collection.find(filter: all);
      expect(cursor, isNotNull);
      expect(await cursor.length, 3);

      cursor = await collection.find();
      expect(cursor, isNotNull);
      expect(await cursor.length, 3);
    });

    test("Test Order by Nullable", () async {
      var col = await db.getCollection('test');
      await col.createIndex(['id'], indexOptions(IndexType.unique));
      await col.createIndex(['group'], indexOptions(IndexType.nonUnique));

      await col.remove(all);

      var doc = emptyDocument()
        ..put('id', 'test-1')
        ..put('group', 'groupA');
      var result = await col.insert([doc]);
      expect(result.length, 1);

      doc = emptyDocument()
        ..put('id', 'test-2')
        ..put('group', 'groupA')
        ..put('startTime', DateTime.now());
      result = await col.insert([doc]);
      expect(result.length, 1);

      var cursor = await col.find(
          filter: where('group').eq('groupA'),
          findOptions: orderBy('startTime', SortOrder.descending));
      expect(await cursor.length, 2);

      expect(cursor, emitsInOrder([
        emits(containsPair('startTime', isNotNull)),
        emits(isNot(containsPair('startTime', isNotNull))),
        emitsDone
      ]));
    });
  });
}