import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';
import 'base_collection_test_loader.dart';

void main() {
  group(retry: 3, 'Collection Delete Negative Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Drop', () async {
      await collection.drop();
      expect(() async => await insert(), throwsNitriteIOException);
    });

    test('Test Delete with Invalid Filter', () async {
      await insert();
      var cursor = collection.find();
      await expectLater(cursor.length, completion(3));

      expect(() async => await collection.remove(where('lastName').gt(null)),
          throwsFilterException);
    });
  });
}
