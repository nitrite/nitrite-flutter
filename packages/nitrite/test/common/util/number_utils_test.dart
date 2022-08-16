import 'package:nitrite/src/common/util/number_utils.dart';
import 'package:test/test.dart';

void main() {
  group("Number Utils Test Suite", () {
    test('Test CompareNum', () {
      expect(compareNum(1, 2), -1);
      expect(compareNum(2, 1), 1);
      expect(compareNum(1, 1), 0);

      expect(compareNum(1.0, 2), -1);
      expect(compareNum(2.0, 1.0), 1);
      expect(compareNum(1.0, 1), 0);

      expect(compareNum(double.infinity, 2), 1);
      expect(compareNum(2.0, double.infinity), -1);
      expect(compareNum(double.infinity, double.infinity), 0);

      expect(compareNum(double.nan, 2), 1);
      expect(compareNum(2.0, double.nan), -1);
      expect(compareNum(double.nan, double.nan), 0);

      expect(compareNum(double.negativeInfinity, 2), -1);
      expect(compareNum(2.0, double.negativeInfinity), 1);
      expect(compareNum(double.negativeInfinity, double.negativeInfinity), 0);

      expect(compareNum(double.infinity, -2), 1);
      expect(compareNum(-2.0, double.infinity), -1);
      expect(compareNum(-2.0, -2.0), 0);
    });
  });
}
