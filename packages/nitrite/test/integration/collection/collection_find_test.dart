import 'package:test/test.dart';

import 'base_collection_test.dart';

void main() {
  group("Collection Find Test Suite", () {
    setUp(() async {
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
  });
}