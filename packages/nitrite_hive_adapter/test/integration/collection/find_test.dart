import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';
import 'base_collection_test_loader.dart';

void main() {
  group(retry: 3, "Collection Find Test Suite", () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test("Test Find All", () async {
      await insert();

      var cursor = collection.find();
      expect(await cursor.length, 3);
    });

    test("Test Find with Filter", () async {
      await insert();

      var cursor = collection.find(
          filter:
              where('birthDay').gt(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 1);

      var doc = await cursor.first;
      expect(doc.get('firstName'), 'fn3');
      expect(doc.get('lastName'), 'ln2');

      cursor = collection.find(
          filter: where('birthDay')
              .gte(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 2);

      cursor = collection.find(
          filter:
              where('birthDay').lt(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: where('birthDay')
              .lte(DateTime.parse('2012-07-01T16:02:48.440Z')));
      expect(await cursor.length, 2);

      cursor = collection.find(filter: where('birthDay').lte(DateTime.now()));
      expect(await cursor.length, 3);

      cursor = collection.find(filter: where('birthDay').lt(DateTime.now()));
      expect(await cursor.length, 3);

      cursor = collection.find(filter: where('birthDay').gt(DateTime.now()));
      expect(await cursor.length, 0);

      cursor = collection.find(filter: where('birthDay').gte(DateTime.now()));
      expect(await cursor.length, 0);

      cursor = collection.find(
          filter: where('birthDay')
              .lte(DateTime.now())
              .and(where('firstName').eq('fn1')));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: where('birthDay')
              .lte(DateTime.now())
              .or(where('firstName').eq('fn12')));
      expect(await cursor.length, 3);

      cursor = collection.find(
          filter: and([
        or([
          where('birthDay').lte(DateTime.now()),
          where('firstName').eq('fn12'),
        ]),
        where('lastName').eq('ln1')
      ]));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: and([
        or([
          where('birthDay').lte(DateTime.now()),
          where('firstName').eq('fn12'),
        ]),
        where('lastName').eq('ln1')
      ]).not());
      expect(await cursor.length, 2);

      cursor = collection.find(
          filter: ~and([
        or([
          where('birthDay').lte(DateTime.now()),
          where('firstName').eq('fn12'),
        ]),
        where('lastName').eq('ln1')
      ]));
      expect(await cursor.length, 2);

      cursor = collection.find(filter: where('data.1').eq(4));
      expect(await cursor.length, 2);

      cursor = collection.find(filter: where('data.1').lt(4));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: where('lastName').within(["ln1", "ln2", "ln10"]));
      expect(await cursor.length, 3);

      cursor =
          collection.find(filter: where('firstName').notIn(["fn1", "fn2"]));
      expect(await cursor.length, 1);

      cursor = collection.find(filter: ~all);
      expect(await cursor.length, 0);

      cursor = collection.find(filter: all.not());
      expect(await cursor.length, 0);
    });

    test("Test Find with Skip Limit", () async {
      await insert();

      var cursor = collection.find(findOptions: skipBy(0).setLimit(1));
      expect(await cursor.length, 1);

      cursor = collection.find(findOptions: skipBy(1).setLimit(3));
      expect(await cursor.length, 2);

      cursor = collection.find(findOptions: skipBy(0).setLimit(30));
      expect(await cursor.length, 3);

      cursor = collection.find(findOptions: skipBy(2).setLimit(3));
      expect(await cursor.length, 1);
    });

    test("Test Find with Skip", () async {
      await insert();

      var cursor = collection.find(findOptions: skipBy(0));
      expect(await cursor.length, 3);

      cursor = collection.find(findOptions: skipBy(1));
      expect(await cursor.length, 2);

      cursor = collection.find(findOptions: skipBy(30));
      expect(await cursor.length, 0);

      cursor = collection.find(findOptions: skipBy(2));
      expect(await cursor.length, 1);

      expect(() async => await collection.find(findOptions: skipBy(-2)).first,
          throwsValidationException);
    });

    test("Test Find with Limit", () async {
      await insert();

      var cursor = collection.find(findOptions: limitBy(0));
      expect(await cursor.length, 0);

      cursor = collection.find(findOptions: limitBy(1));
      expect(await cursor.length, 1);

      cursor = collection.find(findOptions: limitBy(30));
      expect(await cursor.length, 3);

      expect(() async => await collection.find(findOptions: limitBy(-1)).first,
          throwsValidationException);
    });

    test("Test Find with Sort Ascending", () async {
      await insert();

      var cursor = collection.find(
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

      var cursor = collection.find(
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

      var cursor = collection.find(
          findOptions:
              orderBy('birthDay', SortOrder.descending).setSkip(1).setLimit(2));
      expect(await cursor.length, 2);
      var dateList = <DateTime>[];
      await for (var document in cursor) {
        dateList.add(document.get('birthDay') as DateTime);
      }
      expect(isSorted<DateTime>(dateList, false), isTrue);

      cursor = collection.find(
          findOptions: orderBy('birthDay').setSkip(1).setLimit(2));
      expect(await cursor.length, 2);
      dateList = <DateTime>[];
      await for (var document in cursor) {
        dateList.add(document.get('birthDay') as DateTime);
      }
      expect(isSorted<DateTime>(dateList, true), isTrue);

      cursor = collection.find(
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

      var cursor = collection.find(
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

      var cursor = collection.find(filter: where('myField').eq('myData'));
      expect(await cursor.length, 0);

      cursor = collection.find(filter: where('myField').notEq(null));
      expect(await cursor.length, 0);

      cursor = collection.find(filter: where('myField').eq(null));
      expect(await cursor.length, 3);
    });

    test("Test Find with Invalid Field with Invalid Accessor", () async {
      await insert();

      var cursor = collection.find(filter: where('myField.0').eq('myData'));
      expect(await cursor.length, 0);

      cursor = collection.find(filter: where('myField.0').notEq(null));
      expect(await cursor.length, 0);

      cursor = collection.find(filter: where('myField.0').eq(null));
      expect(await cursor.length, 3);
    });

    test("Test Find with Invalid Field with Invalid Accessor", () async {
      await insert();

      var cursor = collection.find(filter: where('myField.0').eq('myData'));
      expect(await cursor.length, 0);

      cursor = collection.find(filter: where('myField.0').notEq(null));
      expect(await cursor.length, 0);

      cursor = collection.find(filter: where('myField.0').eq(null));
      expect(await cursor.length, 3);
    });

    test("Test Find with Limit And Sort on Invalid Field", () async {
      await insert();

      var cursor = collection.find(
          findOptions: orderBy('birthDay2', SortOrder.descending)
              .setSkip(1)
              .setLimit(2));
      expect(await cursor.length, 2);
    });

    test("Test Get by Id", () async {
      await collection.insert(doc1);
      var id = NitriteId.createId('1');
      var doc = await collection.getById(id);
      expect(doc, isNull);

      doc = await (collection.find()).first;
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

      var cursor = collection.find(
          filter: where('birthDay').lte(DateTime.now()),
          findOptions: orderBy('firstName').setSkip(1).setLimit(2));
      expect(await cursor.length, 2);

      expect(cursor.map((d) => d['firstName']), emitsInOrder(['fn2', 'fn3']));
    });

    test("Test Find Text with Regex", () async {
      await insert();

      var cursor = collection.find(filter: where('body').regex(r'hello'));
      expect(await cursor.length, 1);

      cursor = collection.find(filter: where('body').regex(r'[0-9]+'));
      expect(await cursor.length, 0);

      cursor = collection.find(filter: where('body').regex('test'));
      expect(await cursor.length, 0);

      cursor = collection.find(filter: where('body').regex(r'^hello$'));
      expect(await cursor.length, 0);

      cursor = collection.find(filter: where('body').regex(r'.*'));
      expect(await cursor.length, 3);
    });

    test("Test Find Result", () async {
      await insert();

      var cursor = collection.find(
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
      await collection.insertMany([doc1, doc2]);

      var projection = emptyDocument()
        ..put('name', null)
        ..put('address.city', null)
        ..put('address.state', null);

      var cursor =
          collection.find(findOptions: orderBy("name", SortOrder.descending));
      var stream = cursor.project(projection);

      expect(await stream.length, 2);
      var list = await stream.toList();
      expect(list[0].get('name'), 'John');
      expect(list[0].get('address.city'), 'New York');
      expect(list[0].get('address.state'), 'NY');

      expect(list[1].get('name'), 'Jane');
      expect(list[1].get('address.city'), 'New Jersey');
      expect(list[1].get('address.state'), 'NJ');
    });

    test('Test Find with List Equal', () async {
      await insert();

      var data = collection.find(filter: where('data').eq([3, 4, 3]));
      expect(data, isNotNull);
      expect(await data.length, 1);
    });

    test('Test Find with List with Wrong Order', () async {
      await insert();

      var data = collection.find(filter: where('data').eq([4, 3, 3]));
      expect(data, isNotNull);
      expect(await data.length, 0);
    });

    test("Test Find in List", () async {
      await insert();

      var cursor = collection.find(
          filter: where('data').elemMatch($.gte(2).and($.lt(5))));
      expect(await cursor.length, 3);

      cursor = collection.find(
          filter: where('data').elemMatch($.gt(2).or($.lte(5))));
      expect(await cursor.length, 3);

      cursor = collection.find(
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
      await prodCollection.insertMany([doc1, doc2, doc3]);

      var cursor = prodCollection.find(
          filter: where('productScores').elemMatch(
              where('product').eq('xyz').and(where('score').gte(8))));
      expect(await cursor.length, 1);

      cursor = prodCollection.find(
          filter:
              where("productScores").elemMatch(where("score").lte(8).not()));
      expect(await cursor.length, 1);

      cursor = prodCollection.find(
          filter: where("productScores")
              .elemMatch(where("product").eq("xyz").or(where("score").gte(8))));
      expect(await cursor.length, 3);

      cursor = prodCollection.find(
          filter: where("productScores").elemMatch(where("product").eq("xyz")));
      expect(await cursor.length, 3);

      cursor = prodCollection.find(
          filter: where("productScores").elemMatch(where("score").gte(10)));
      expect(await cursor.length, 1);

      cursor = prodCollection.find(
          filter: where("productScores").elemMatch(where("score").gt(8)));
      expect(await cursor.length, 1);

      cursor = prodCollection.find(
          filter: where("productScores").elemMatch(where("score").lt(7)));
      expect(await cursor.length, 1);

      cursor = prodCollection.find(
          filter: where("productScores").elemMatch(where("score").lte(7)));
      expect(await cursor.length, 3);

      cursor = prodCollection.find(
          filter:
              where("productScores").elemMatch(where("score").within([7, 8])));
      expect(await cursor.length, 2);

      cursor = prodCollection.find(
          filter:
              where("productScores").elemMatch(where("score").notIn([7, 8])));
      expect(await cursor.length, 1);

      cursor = prodCollection.find(
          filter:
              where("productScores").elemMatch(where("product").regex("xyz")));
      expect(await cursor.length, 3);

      cursor =
          prodCollection.find(filter: where("strArray").elemMatch($.eq("a")));
      expect(await cursor.length, 2);

      cursor = prodCollection.find(
          filter: where("strArray")
              .elemMatch($.eq("a").or($.eq("f").or($.eq("b"))).not()));
      expect(await cursor.length, 1);

      cursor =
          prodCollection.find(filter: where("strArray").elemMatch($.gt("e")));
      expect(await cursor.length, 1);

      cursor =
          prodCollection.find(filter: where("strArray").elemMatch($.gte("e")));
      expect(await cursor.length, 2);

      cursor =
          prodCollection.find(filter: where("strArray").elemMatch($.lte("b")));
      expect(await cursor.length, 2);

      cursor =
          prodCollection.find(filter: where("strArray").elemMatch($.lt("a")));
      expect(await cursor.length, 0);

      cursor = prodCollection.find(
          filter: where("strArray").elemMatch($.within(["a", "f"])));
      expect(await cursor.length, 2);

      cursor = prodCollection.find(
          filter: where("strArray").elemMatch($.regex("a")));
      expect(await cursor.length, 2);
    });

    test("Test NotEqual Filter", () async {
      var doc = emptyDocument()
        ..put('abc', '123')
        ..put('xyz', null);

      await collection.insert(doc);
      var cursor = collection.find(filter: where("abc").eq("123"));
      expect(await cursor.length, 1);

      cursor = collection.find(filter: where("xyz").eq(null));
      expect(await cursor.length, 1);

      cursor = collection.find(filter: where("abc").notEq(null));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: where("abc").notEq(null).and(where("xyz").eq(null)));
      expect(await cursor.length, 1);

      cursor = collection.find(
          filter: where("abc").eq(null).and(where("xyz").notEq(null)));
      expect(await cursor.length, 0);

      await collection.remove(all);

      doc = emptyDocument()
        ..put('field', 'two')
        ..put('revision', 1482225343161);

      await collection.insert(doc);
      cursor = collection.find(
          filter: where('revision').gte(1482225343160).and(where('revision')
              .lte(1482225343162)
              .and(where('revision').notEq(null))));
      var projected = await cursor.first;
      expect(projected, isNotNull);
    });

    test("Test Filter All", () async {
      var cursor = collection.find(filter: all);
      expect(cursor, isNotNull);
      expect(await cursor.length, 0);

      await insert();

      cursor = collection.find(filter: all);
      expect(cursor, isNotNull);
      expect(await cursor.length, 3);

      cursor = collection.find();
      expect(cursor, isNotNull);
      expect(await cursor.length, 3);
    });

    test("Test Order by Nullable", () async {
      var col = await db.getCollection('test');
      await col.createIndex(['startTime'], indexOptions(IndexType.nonUnique));
      await col.createIndex(['group'], indexOptions(IndexType.nonUnique));

      await col.remove(all);

      var doc = emptyDocument()
        ..put('id', 'test-1')
        ..put('group', 'groupA');
      var result = await col.insert(doc);
      expect(result.length, 1);

      doc = emptyDocument()
        ..put('id', 'test-2')
        ..put('group', 'groupA')
        ..put('startTime', DateTime.now());
      result = await col.insert(doc);
      expect(result.length, 1);

      var cursor = col.find(
          filter: where('group').eq('groupA'),
          findOptions: orderBy('startTime', SortOrder.descending));
      expect(await cursor.length, 2);

      expect(
          cursor,
          emitsInOrder([
            emits(containsPair('startTime', isNotNull)),
            emits(isNot(containsPair('startTime', isNotNull))),
            emitsDone
          ]));

      // sort with invalid field
      cursor = col.find(
          filter: where('group').eq('groupA'),
          findOptions: orderBy('startTime2', SortOrder.descending));
      expect(await cursor.length, 2);
    });

    test("Test Default Null Order", () async {
      var col = await db.getCollection('test');
      await col.createIndex(['startTime'], indexOptions(IndexType.nonUnique));
      await col.remove(all);

      var doc1 = emptyDocument()
        ..put('id', 'test-1')
        ..put('group', 'groupA');

      var doc2 = emptyDocument()
        ..put('id', 'test-2')
        ..put('startTime', DateTime.parse('2019-10-19T02:45:15'))
        ..put('group', 'groupA');

      var doc3 = emptyDocument()
        ..put('id', 'test-3')
        ..put('startTime', DateTime.parse('2018-10-19T02:45:15'))
        ..put('group', 'groupA');

      var result = await col.insertMany([doc1, doc2, doc3]);
      expect(result.length, 3);

      var cursor = col.find(
          filter: where('group').eq('groupA'),
          findOptions: orderBy('startTime', SortOrder.descending));
      expect(await cursor.length, 3);

      expect(
          cursor,
          emitsInOrder([
            emits(containsPair('id', equals('test-2'))),
            emits(containsPair('id', equals('test-3'))),
            emits(containsPair('id', equals('test-1'))),
            emitsDone
          ]));

      cursor = col.find(
          filter: where('group').eq('groupA'),
          findOptions: orderBy('startTime', SortOrder.ascending));
      expect(await cursor.length, 3);

      expect(
          cursor,
          emitsInOrder([
            emits(containsPair('id', equals('test-1'))),
            emits(containsPair('id', equals('test-3'))),
            emits(containsPair('id', equals('test-2'))),
            emitsDone
          ]));
    });

    test("Test Find Filter Invalid Accessor", () async {
      await insert();

      var cursor = collection.find(filter: where("lastName.name").eq("ln2"));
      expect(await cursor.length, 0);
    });

    test("Test Find and Sort for Accented String", () async {
      var doc1 = emptyDocument()
        ..put('id', 'test-1')
        ..put('fruit', 'Apple');

      var doc2 = emptyDocument()
        ..put('id', 'test-2')
        ..put('fruit', 'Ôrange');

      var doc3 = emptyDocument()
        ..put('id', 'test-3')
        ..put('fruit', 'Pineapple');

      var doc4 = emptyDocument()
        ..put('id', 'test-4')
        ..put('fruit', 'Orange');

      var col = await db.getCollection('test');
      await col.insertMany([doc1, doc2, doc3, doc4]);

      var cursor = col.find(findOptions: orderBy('fruit'));
      expect(await cursor.length, 4);

      // there is no locale supported string sort in dart/flutter
      // so Ôrange will come last.
      expect(
          cursor,
          emitsInOrder([
            emits(containsPair('id', equals('test-1'))),
            emits(containsPair('id', equals('test-4'))),
            emits(containsPair('id', equals('test-3'))),
            emits(containsPair('id', equals('test-2'))),
            emitsDone
          ]));

      cursor = col.find(findOptions: orderBy('fruit', SortOrder.descending));
      expect(await cursor.length, 4);

      expect(
          cursor,
          emitsInOrder([
            emits(containsPair('id', equals('test-2'))),
            emits(containsPair('id', equals('test-3'))),
            emits(containsPair('id', equals('test-4'))),
            emits(containsPair('id', equals('test-1'))),
            emitsDone
          ]));
    });

    test("Test Find by Nested Field in List", () async {
      var doc1 = emptyDocument()
        ..put('name', 'John')
        ..put('tags', [
          emptyDocument()
            ..put('type', 'example')
            ..put('other', 'value'),
          emptyDocument()
            ..put('type', 'another-example')
            ..put('other', 'another-value')
        ]);

      var doc2 = emptyDocument()
        ..put('name', 'Jane')
        ..put('tags', [
          emptyDocument()
            ..put('type', 'example2')
            ..put('other', 'value2'),
          emptyDocument()
            ..put('type', 'another-example2')
            ..put('other', 'another-value2')
        ]);

      var col = await db.getCollection('test');
      await col.insertMany([doc1, doc2]);

      var cursor = col.find(
          filter: where('tags').elemMatch(where('type').eq('example')));

      expect(
          cursor,
          emitsInOrder(
              [emits(containsPair('name', equals('John'))), emitsDone]));
    });

    test("Test Find by Between Filter", () async {
      var doc1 = emptyDocument()
        ..put('age', 31)
        ..put('tag', 'one');

      var doc2 = emptyDocument()
        ..put('age', 32)
        ..put('tag', 'two');

      var doc3 = emptyDocument()
        ..put('age', 33)
        ..put('tag', 'two');

      var doc4 = emptyDocument()
        ..put('age', 34)
        ..put('tag', 'four');

      var doc5 = emptyDocument()
        ..put('age', 35)
        ..put('tag', 'five');

      var col = await db.getCollection('test');
      await col.insertMany([doc1, doc2, doc3, doc4, doc5]);

      var cursor = col.find(filter: where('age').between(31, 35));
      expect(await cursor.length, 5);

      cursor = col.find(
          filter: where('age')
              .between(31, 35, lowerInclusive: false, upperInclusive: false));
      expect(await cursor.length, 3);

      cursor = col.find(
          filter: where('age')
              .between(31, 35, lowerInclusive: false, upperInclusive: true));
      expect(await cursor.length, 4);

      cursor = col.find(
          filter: where('age')
              .between(31, 35, lowerInclusive: false, upperInclusive: false)
              .not());
      expect(await cursor.length, 2);

      // create index and same search with same result
      await col.createIndex(['age']);
      cursor = col.find(filter: where('age').between(31, 35));
      expect(await cursor.length, 5);

      cursor = col.find(
          filter: where('age')
              .between(31, 35, lowerInclusive: false, upperInclusive: false));
      expect(await cursor.length, 3);

      cursor = col.find(
          filter: where('age')
              .between(31, 35, lowerInclusive: false, upperInclusive: true));
      expect(await cursor.length, 4);

      cursor = col.find(
          filter: where('age')
              .between(31, 35, lowerInclusive: false, upperInclusive: false)
              .not());
      expect(await cursor.length, 2);
    });

    test("Test Find byId", () async {
      var doc1 = emptyDocument()
        ..put('age', 31)
        ..put('tag', 'one');

      var doc2 = emptyDocument()
        ..put('age', 32)
        ..put('tag', 'two');

      var doc3 = emptyDocument()
        ..put('age', 33)
        ..put('tag', 'two');

      var doc4 = emptyDocument()
        ..put('age', 34)
        ..put('tag', 'four');

      var doc5 = emptyDocument()
        ..put('age', 35)
        ..put('tag', 'five');

      var col = await db.getCollection('test');
      await col.insertMany([doc1, doc2, doc3, doc4, doc5]);

      var documentList = await (col.find()).toList();
      var doc = documentList[0];
      var nitriteId = doc.id;

      var result = await (col.find(filter: byId(nitriteId))).first;
      expect(result, equals(doc));

      result = await (col.find(
          filter: and([byId(nitriteId), where("age").notEq(null)]))).first;
      expect(result, equals(doc));

      result = await (col.find(
          filter: and([byId(nitriteId), where("tag").eq(doc['tag'])]))).first;
      expect(result, equals(doc));
    });
  });
}
