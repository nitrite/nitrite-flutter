import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import 'base_collection_test_loader.dart';

void main() {
  group('Collection Delete Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Delete', () async {
      await insert();

      var writeResult = await collection.remove(where('lastName').notEq(null));
      expect(writeResult.getAffectedCount(), 3);

      var cursor = await collection.find();
      expectLater(cursor.length, completion(0));
    });

    test('Test Delete with Options', () async {
      await insert();

      var writeResult =
          await collection.remove(where('lastName').notEq(null), justOne: true);
      expect(writeResult.getAffectedCount(), 1);

      var cursor = await collection.find();
      expectLater(cursor.length, completion(2));
    });

    test('Test Delete with Non Matching Filter', () async {
      await insert();

      var cursor = await collection.find();
      expectLater(cursor.length, completion(3));

      var writeResult = await collection.remove(where('lastName').eq('a'));
      expect(writeResult.getAffectedCount(), 0);

      cursor = await collection.find();
      expectLater(cursor.length, completion(3));
    });

    test('Test Delete in Empty Collection', () async {
      var cursor = await collection.find();
      expectLater(cursor.length, completion(0));

      var writeResult = await collection.remove(where('lastName').notEq(null));
      expect(writeResult.getAffectedCount(), 0);
    });

    test('Test Clear', () async {
      await collection.createIndex(['firstName']);
      await insert();

      var cursor = await collection.find();
      expect(await cursor.length, 3);
      expectLater(collection.hasIndex(['firstName']), completion(isTrue));

      bool errorThrown = false;
      try {
        await collection.insert(doc1);
      } catch (e) {
        errorThrown = true;
        expect(e is UniqueConstraintException, isTrue);
      }

      expect(errorThrown, isTrue);

      await collection.clear();

      cursor = await collection.find();
      expectLater(cursor.length, completion(0));
      expectLater(collection.hasIndex(['firstName']), completion(isTrue));

      await collection.insert(doc1);
      cursor = await collection.find();
      expectLater(cursor.length, completion(1));
      expectLater(collection.hasIndex(['firstName']), completion(isTrue));
    });

    test("Test Remove All", () async {
      await insert();
      var writeResult = await collection.remove(all);
      expect(writeResult.getAffectedCount(), 3);

      var cursor = await collection.find();
      expect(await cursor.length, 0);
    });
  });
}
