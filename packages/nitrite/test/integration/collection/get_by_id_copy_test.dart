import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../../test_utils.dart';
import 'base_collection_test_loader.dart';

void main() {
  group(retry: 3, 'GetById Copy Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    // The in-memory store hands back the instance it holds, so a getById that
    // did not copy let a caller edit the store directly, bypassing the indexes.
    test('Test GetById Does Not Hand Out The Stored Instance', () async {
      var doc = createDocument('name', 'original');
      var result = await collection.insert(doc);
      var id = await result.first;

      var first = await collection.getById(id);
      first!.put('name', 'mutated');

      var second = await collection.getById(id);
      expect(second!.get('name'), 'original');
    });

    test('Test GetById Returns Null For An Unknown Id', () async {
      expect(await collection.getById(NitriteId.newId()), isNull);
    });
  });
}
