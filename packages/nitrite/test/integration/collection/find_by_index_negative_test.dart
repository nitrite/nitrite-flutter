import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../../test_utils.dart';
import 'base_collection_test_loader.dart';

void main() {
  group('Collection Find By Index Negative Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Find Text with Wildcard Multiple Word', () async {
      await insert();
      await collection.createIndex(['body'], indexOptions(IndexType.fullText));

      var cursor =
          collection.find(filter: where("body").text("*ipsum dolor*"));
      expect(() async => await cursor.length, throwsFilterException);
    });

    test('Test Find Text with Only Wildcard', () async {
      await insert();
      await collection.createIndex(['body'], indexOptions(IndexType.fullText));

      var cursor = collection.find(filter: where("body").text("*"));
      expect(() async => await cursor.length, throwsFilterException);
    });
  });
}
