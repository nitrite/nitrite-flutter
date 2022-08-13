import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

void main() {
  group('Find Options Test Suite', () {
    setUp(() {});

    test("Test OrderBy", () {
      var orderByResult = FindOptions.orderBy("fieldName", SortOrder.ascending);
      expect(orderByResult.orderBy, isNotNull);
      expect(orderByResult.orderBy?.encodedName, "fieldName");

      orderByResult = FindOptions.orderBy("fieldName1", SortOrder.descending)
          .thenOrderBy("fieldName2", SortOrder.ascending);
      expect(orderByResult.orderBy, isNotNull);
      expect(orderByResult.orderBy?.encodedName,
          "fieldName1${internalNameSeparator}fieldName2");
    });

    test("Test SkipBy", () {
      var findOptions = FindOptions.skipBy(1);
      expect(findOptions.skip, 1);
      expect(findOptions.limit, isNull);
    });

    test("Test LimitBy", () {
      var findOptions = FindOptions.limitBy(1);
      expect(findOptions.limit, 1);
      expect(findOptions.skip, isNull);
    });

    test("Test SkipBy and LimitBy", () {
      var findOptions = FindOptions.skipBy(1).setLimit(1);
      expect(findOptions.skip, 1);
      expect(findOptions.limit, 1);
    });

    test("Test SkipBy and LimitBy", () {
      var findOptions = FindOptions();
      findOptions.setLimit(1);
      findOptions.setSkip(1);

      expect(findOptions.skip, 1);
      expect(findOptions.limit, 1);
    });

    test("Test then order by", () {
      var findOptions = FindOptions();
      findOptions.setLimit(1);
      findOptions.setSkip(1);
      findOptions.thenOrderBy("fieldName", SortOrder.ascending);

      expect(findOptions.skip, 1);
      expect(findOptions.limit, 1);
      expect(findOptions.orderBy?.encodedName, "fieldName");
    });

    test("Test Distinct", () {
      var findOptions = FindOptions.distinct();
      expect(findOptions.distinct, isTrue);
    });

    test("Test Distinct", () {
      var findOptions = FindOptions();
      expect(findOptions.distinct, isFalse);
      findOptions.withDistinct(true);
      expect(findOptions.distinct, isTrue);
    });
  });
}
