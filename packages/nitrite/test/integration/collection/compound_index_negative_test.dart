import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../../test_utils.dart';
import 'base_collection_test_loader.dart';

void main() {
  group('Compound Index Negative Test', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Create Invalid Unique Index', () async {
      doc1 = emptyDocument()
        ..put("firstName", "fn3")
        ..put("lastName", "ln2")
        ..put("birthDay", DateTime.now())
        ..put("data", [1, 2, 3])
        ..put("list", ["one", "two", "three"])
        ..put("body", 'a quick brown fox jump over the lazy dog');

      await collection.createIndex(["lastName", "firstName"]);
      expect(() async => await insert(), throwsUniqueConstraintException);
    });

    test('Test Create Unique Multikey Index on List', () async {
      await collection.createIndex(["data", "lastName"]);
      expect(() async => await insert(), throwsUniqueConstraintException);
    });

    test('Test Create Index on Invalid Field', () async {
      await insert();
      // multiple null value will be created for an unique index
      expect(() async => await collection.createIndex(['my-value', 'lastName']),
          throwsUniqueConstraintException);

      await collection.dropAllIndices();
      expect(
          () async => await collection.createIndex(
              ['my-value', 'lastName'], indexOptions(IndexType.nonUnique)),
          returnsNormally);
    });

    test('Test Drop Index on NonIndexed Field', () async {
      expect(() async => await collection.dropIndex(['data', 'firstName']),
          throwsIndexingException);
    });

    test('Test Rebuild Invalid Index', () async {
      expect(
          () async => await collection.rebuildIndex(['unknown', 'firstName']),
          throwsIndexingException);
    });

    test('Test Create Multiple Index Type on Same Fields', () async {
      await collection.createIndex(['lastName', 'firstName']);

      expect(
          () async => await collection.createIndex(
              ['lastName', 'firstName'], indexOptions(IndexType.nonUnique)),
          throwsIndexingException);
    });

    test('Test Index Already Exists', () async {
      await collection.createIndex(['firstName', 'lastName']);
      expect(await collection.hasIndex(['firstName']), isTrue);

      expect(
          () async => await collection.createIndex(
              ['firstName', 'lastName'], indexOptions(IndexType.nonUnique)),
          throwsIndexingException);
    });

    test('Test Create Compound Text Index', () async {
      expect(
          () async => await collection.createIndex(
              ['body', 'lastName'], indexOptions(IndexType.fullText)),
          throwsIndexingException);
    });

    test('Test Create Multikey Index in Second Field', () async {
      await collection
          .createIndex(['lastName', 'data'], indexOptions(IndexType.nonUnique));
      expect(await collection.hasIndex(['lastName']), isTrue);
      expect(() async => await insert(), throwsIndexingException);
    });
  });
}
