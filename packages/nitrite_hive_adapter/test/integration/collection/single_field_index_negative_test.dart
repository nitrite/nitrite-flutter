import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../../test_utils.dart';
import 'base_collection_test_loader.dart';

void main() {
  group('Collection Single Field Index Negative Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Create Invalid Unique Index', () async {
      await collection
          .createIndex(['lastName'], indexOptions(IndexType.unique));
      expect(await collection.hasIndex(['lastName']), true);
      expect(() async => await insert(), throwsUniqueConstraintException);
    });

    test('Test Create Index on Array', () async {
      await collection.createIndex(['data'], indexOptions(IndexType.unique));
      expect(await collection.hasIndex(['data']), true);
      expect(() async => await insert(), throwsUniqueConstraintException);
    });

    test('Test Create Index on Invalid Field', () async {
      await collection
          .createIndex(['my-value'], indexOptions(IndexType.unique));
      expect(await collection.hasIndex(['my-value']), true);
      expect(() async => await insert(), throwsUniqueConstraintException);
    });

    test('Test Create Fulltext Index on Non Text Field', () async {
      await collection
          .createIndex(['birthDay'], indexOptions(IndexType.fullText));
      expect(await collection.hasIndex(['birthDay']), true);
      expect(() async => await insert(), throwsIndexingException);
    });

    test('Test Drop Index on Non Indexed Field', () async {
      expect(() async => await collection.dropIndex(['data']),
          throwsIndexingException);
    });

    test('Test Rebuild Index on Non Indexed Field', () async {
      expect(() async => await collection.dropIndex(['unknown']),
          throwsIndexingException);
    });

    test('Test Multiple IndexType on Same Field', () async {
      await collection
          .createIndex(['lastName'], indexOptions(IndexType.nonUnique));

      expect(() async => await collection.createIndex(['lastName']),
          throwsIndexingException);
    });
  });
}
