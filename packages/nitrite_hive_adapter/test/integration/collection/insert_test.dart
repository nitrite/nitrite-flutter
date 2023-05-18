import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'base_collection_test_loader.dart';

void main() {
  group('Collection Insert Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Insert', () async {
      var result = await collection.insertMany([doc1, doc2, doc3]);
      expect(result.getAffectedCount(), 3);

      var cursor = await collection.find();
      expect(await cursor.length, 3);

      await for (var doc in cursor) {
        expect(doc['firstName'], isNotNull);
        expect(doc['lastName'], isNotNull);
        expect(doc['birthDay'], isNotNull);
        expect(doc['data'], isNotNull);
        expect(doc['body'], isNotNull);
        expect(doc[docId], isNotNull);
      }
    });

    test('Test Insert Hetero Docs', () async {
      var document = createDocument('test', 'Nitrite Test');
      var result = await collection.insertMany([doc1, doc2, doc3, document]);
      expect(result.getAffectedCount(), 4);
    });
  });
}
