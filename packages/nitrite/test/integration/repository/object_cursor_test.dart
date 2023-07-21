import 'package:test/test.dart';

import '../../test_utils.dart';
import 'base_object_repository_test_loader.dart';

void main() {
  group('Object Cursor Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Projection For Abstract Class', () async {
      var cursor = employeeRepository.find();
      expect(() async => await cursor.project<Comparable>().toList(),
          throwsValidationException);
    });

    test('Test Projection For Number', () async {
      var cursor = employeeRepository.find();
      expect(() async => await cursor.project<int>().toList(),
          throwsValidationException);
    });

    test('Test Projection For List', () async {
      var cursor = employeeRepository.find();
      expect(() async => await cursor.project<List<String>>().toList(),
          throwsValidationException);
    });
  });
}
