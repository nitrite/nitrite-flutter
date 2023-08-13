import 'package:mockito/annotations.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/operations/find_optimizer.dart';
import 'package:test/test.dart';

import 'find_optimizer_test.mocks.dart';

@GenerateMocks([Filter])
void main() {
  group(retry: 3, 'Find Optimizer Test Suite', () {
    setUp(() {
      // Additional setup goes here.
    });

    test("Test Optimize", () {
      var findOptimizer = FindOptimizer();
      var filter = MockFilter();
      var findOptions = FindOptions();
      var actualOptimizeResult =
          findOptimizer.optimize(filter, findOptions, []);
      expect(actualOptimizeResult, isNotNull);
      expect(actualOptimizeResult.blockingSortOrder, isEmpty);
      expect(actualOptimizeResult.subPlans, isEmpty);
      expect(actualOptimizeResult.skip, isNull);
      expect(actualOptimizeResult.limit, isNull);
    });

    test("Test Optimize with Null FindOptions", () {
      var findOptimizer = FindOptimizer();
      var filter = MockFilter();
      var actualOptimizeResult = findOptimizer.optimize(filter, null, []);
      expect(actualOptimizeResult, isNotNull);
      expect(actualOptimizeResult.blockingSortOrder, isEmpty);
      expect(actualOptimizeResult.subPlans, isEmpty);
      expect(actualOptimizeResult.skip, isNull);
      expect(actualOptimizeResult.limit, isNull);
    });

    test("Test Optimize with Sort Order", () {
      var findOptimizer = FindOptimizer();
      var filter = MockFilter();
      var findOptions = orderBy("Field Name");
      var actualOptimizeResult =
          findOptimizer.optimize(filter, findOptions, []);
      expect(actualOptimizeResult, isNotNull);
      expect(actualOptimizeResult.blockingSortOrder.length, 1);
      expect(actualOptimizeResult.subPlans, isEmpty);
      expect(actualOptimizeResult.skip, isNull);
      expect(actualOptimizeResult.limit, isNull);
    });

    test("Test Optimize with IndexDescriptor", () {
      var findOptimizer = FindOptimizer();
      var filter = MockFilter();
      var findOptions = FindOptions();

      var indexDescriptor = IndexDescriptor(
          IndexType.unique, Fields.withNames(["a"]), "Collection Name");
      var actualOptimizeResult =
          findOptimizer.optimize(filter, findOptions, [indexDescriptor]);
      expect(actualOptimizeResult, isNotNull);
      expect(actualOptimizeResult.blockingSortOrder, isEmpty);
      expect(actualOptimizeResult.subPlans, isEmpty);
      expect(actualOptimizeResult.skip, isNull);
      expect(actualOptimizeResult.limit, isNull);
    });
  });
}
