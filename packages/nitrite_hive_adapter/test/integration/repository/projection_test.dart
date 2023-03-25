import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import 'base_object_repository_test_loader.dart';
import 'data/test_objects.dart';

void main() {
  group('Projection Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Has More', () async {
      var cursor =
          await employeeRepository.find(findOptions: skipBy(0).setLimit(5));
      var result = cursor.project<SubEmployee>();
      expect(await result.isEmpty, false);
    });

    test('Test Size', () async {
      var cursor =
          await employeeRepository.find(findOptions: skipBy(0).setLimit(5));
      var result = cursor.project<SubEmployee>();
      expect(await result.length, 5);
    });

    test('Test ToString', () async {
      var cursor =
          await employeeRepository.find(findOptions: skipBy(0).setLimit(5));
      var result = cursor.project<SubEmployee>();
      expect(result.toString(), isNotNull);
    });
  });
}
