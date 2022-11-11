import 'package:nitrite/src/index/index.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'base_collection_test.dart';

void main() {
  group('Compound Index Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Create And Check Index', () async {
      await collection.createIndex(['firstName', 'lastName']);
      expect(await collection.hasIndex(['firstName']), isTrue);
      expect(await collection.hasIndex(['firstName', 'lastName']), isTrue);
      expect(await collection.hasIndex(['firstName', 'lastName', 'birthDay']),
          isFalse);
      expect(await collection.hasIndex(['lastName', 'firstName']), isFalse);
      expect(await collection.hasIndex(['lastName']), isFalse);

      await collection
          .createIndex(['firstName'], indexOptions(IndexType.nonUnique));
      expect(await collection.hasIndex(['firstName']), isTrue);

      await collection
          .createIndex(['lastName'], indexOptions(IndexType.nonUnique));
      expect(await collection.hasIndex(['lastName']), isTrue);

      await insert();
    });

    test('Test Create Multi Key Index on First Field', () async {
      await collection.createIndex(['data', 'lastName'], indexOptions(IndexType.nonUnique));
      expect(await collection.hasIndex(['data', 'lastName']), isTrue);
      expect(await collection.hasIndex(['data']), isTrue);
      expect(await collection.hasIndex(['lastName']), isFalse);

      await insert();
    });
  });
}
