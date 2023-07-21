import 'package:test/test.dart';

import '../../test_utils.dart';
import 'base_collection_test_loader.dart';

void main() {
  group('Collection Insert Negative Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Multiple Insert', () async {
      var result = await collection.insertMany([doc1, doc2, doc3]);
      expect(result.getAffectedCount(), 3);

      var cursor = collection.find();
      var document = await cursor.first;

      expect(() async => await collection.insert(document),
          throwsUniqueConstraintException);
    });
  });
}
