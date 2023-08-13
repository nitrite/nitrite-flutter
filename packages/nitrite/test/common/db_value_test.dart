import 'package:collection/collection.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/db_value.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group(retry: 3, "DBValue Test Suite", () {
    test("Test CompareTo", () {
      var dbValue = DBValue(1);

      expect(dbValue.compareTo(DBValue(2)), -1);
      expect(dbValue.compareTo(DBValue(-2)), 1);
    });

    test("Test CompareTo 2", () {
      var dbValue = DBValue(DBValue('a'));

      expect(
          () => dbValue.compareTo(DBValue(2)), throwsInvalidOperationException);
      expect(() => dbValue.compareTo(DBValue('c')),
          throwsInvalidOperationException);
      expect(() => dbValue.compareTo(DBValue(DateTime.now())),
          throwsInvalidOperationException);
      expect(dbValue.compareTo(DBValue(DBValue('a'))), 0);
    });

    test("Test CompareTo 3", () {
      var dbValue = DBValue(DBNull.instance);

      expect(
          () => dbValue.compareTo(DBValue(2)), throwsInvalidOperationException);
      expect(dbValue.compareTo(DBValue(DBNull.instance)), 0);
    });

    test("Test CompareTo 4", () {
      var dbValue = DBValue(UnknownType());

      expect(
          () => dbValue.compareTo(DBValue(2)), throwsInvalidOperationException);
      expect(() => dbValue.compareTo(DBValue(DBNull.instance)),
          throwsInvalidOperationException);
      expect(dbValue.compareTo(DBValue(UnknownType())), 0);
    });

    test("Test Sort Ascending", () {
      var list = [DBValue(10), DBValue(1), DBValue(5)];
      list.sort();

      expect(ListEquality().equals(list, [DBValue(1), DBValue(5), DBValue(10)]),
          isTrue);
    });

    test("Test Sort Descending", () {
      var list = [DBValue(10), DBValue(1), DBValue(5)];
      list.sort((a, b) => -1 * a.compareTo(b));

      expect(ListEquality().equals(list, [DBValue(10), DBValue(5), DBValue(1)]),
          isTrue);
    });

    test("Test Invalid Comparison", () {
      var list = [DBValue(10), DBValue('a'), DBValue(5)];

      expect(() => list.sort(), throwsInvalidOperationException);
    });
  });
}
