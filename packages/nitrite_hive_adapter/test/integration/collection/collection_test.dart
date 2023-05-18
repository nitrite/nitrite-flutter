import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../../test_utils.dart';
import 'base_collection_test_loader.dart';

void main() {
  group('Collection Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Get Name', () {
      expect(collection.name, 'test');
    });

    test('Test Drop Collection', () async {
      // check if collection exists
      // the collection is not opened yet
      expect(await db.hasCollection('test'), true);

      await collection.drop();

      expect(await db.hasCollection('test'), false);
      expect(collection.isOpen, false);
    });

    test('Test Close Collection', () async {
      expect(collection.isOpen, true);
      await collection.close();
      expect(collection.isOpen, false);
    });

    test('Test Drop After Close', () async {
      await collection.close();
      expect(collection.isOpen, false);
      expect(() async => await collection.drop(), throwsNitriteIOException);
    });

    test('Test Operation After Drop', () async {
      await collection.drop();
      expect(
          () async => await collection.insert(createDocument('test', 'test')),
          throwsNitriteIOException);
    });
  });
}
