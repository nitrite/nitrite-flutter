import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';
import 'base_collection_test_loader.dart';

void main() {
  group('Collection Index Negative Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      // await cleanUp();
    });

    test('Test Create Invalid Unique Index', () async {
      await collection.createIndex(['lastName']);
      expect(await collection.hasIndex(['lastName']), true);
      expect(() async => await insert(), throwsUniqueConstraintException);
    });

    test('Test Create Index on Array', () async {
      await collection.createIndex(['data']);
      expect(await collection.hasIndex(['data']), true);
      // data array field has repetition, so unique constraint exception
      expect(() async => await insert(), throwsUniqueConstraintException);
    });

    test('Test Create Index on Invalid Field', () async {
      await insert();
      bool uniqueConstraintError = false;
      try {
        await collection.createIndex(['my-value']);
      } catch (e) {
        uniqueConstraintError = true;
      } finally {
        expect(uniqueConstraintError, true);
      }
    });

    test('Test Create Fulltext Index on Non Text Field', () async {
      await insert();
      expect(
          () async => await collection
              .createIndex(['birthDay'], indexOptions(IndexType.fullText)),
          throwsIndexingException);
    });
  });
}
