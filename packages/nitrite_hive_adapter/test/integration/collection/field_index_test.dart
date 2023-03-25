import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Collection Field Index Test Suite', () {
    late Nitrite db;

    setUp(() async {
      db = await Nitrite.builder().fieldSeparator(".").openOrCreate();
    });

    test('Test Collection', () async {
      var doc1 = createDocument("name", "Anindya")
        ..put("color", ["red", "green", "blue"])
        ..put("books", [
          createDocument("name", "Book ABCD")..put("tag", ["tag1", "tag2"]),
          createDocument("name", "Book EFGH")..put("tag", ["tag3", "tag1"]),
          createDocument("name", "No Tag")
        ]);

      var doc2 = createDocument("name", "Bill")
        ..put("color", ["purple", "yellow", "gray"])
        ..put("books", [
          createDocument("name", "Book abcd")..put("tag", ["tag4", "tag5"]),
          createDocument("name", "Book wxyz")..put("tag", ["tag3", "tag1"]),
          createDocument("name", "No Tag 2")
        ]);

      var doc3 = createDocument("name", "John")
        ..put("color", ["black", "sky", "violet"])
        ..put("books", [
          createDocument("name", "Book Mnop")..put("tag", ["tag6", "tag2"]),
          createDocument("name", "Book ghij")..put("tag", ["tag3", "tag7"]),
          createDocument("name", "No Tag")
        ]);

      var collection = await db.getCollection('test');
      await collection.createIndex(['color']);
      await collection
          .createIndex(['books.tag'], indexOptions(IndexType.nonUnique));
      await collection
          .createIndex(['books.name'], indexOptions(IndexType.fullText));

      var writeResult = await collection.insert([doc1, doc2, doc3]);
      expect(writeResult.getAffectedCount(), 3);

      var cursor = await collection.find(filter: where('color').eq('red'));
      expectLater(cursor.first, completion(containsPair('name', 'Anindya')));

      cursor = await collection.find(filter: where('books.name').text('abcd'));
      expectLater(cursor.length, completion(2));

      cursor = await collection.find(filter: where('books.tag').eq('tag2'));
      expectLater(cursor.length, completion(2));

      cursor = await collection.find(filter: where('books.tag').eq('tag5'));
      expectLater(cursor.length, completion(1));

      cursor = await collection.find(filter: where('books.tag').eq('tag10'));
      expectLater(cursor.length, completion(0));
    });
  });
}
