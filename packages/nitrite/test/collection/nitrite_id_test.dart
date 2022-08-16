import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';
import 'package:dart_numerics/dart_numerics.dart' as num;

import '../test_utils.dart';

void main() async {
  group('Nitrite Id Test Suite', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Test Limit', () {
      var one = NitriteId.createId(num.int64MaxValue.toString());
      var two = NitriteId.createId(num.int64MinValue.toString());
      expect(one.compareTo(two), 1);
    });

    test("Test Hash Equals", () {
      var one = NitriteId.createId("1");
      var two = NitriteId.createId("1");

      expect(one, two);
      expect(one.hashCode, two.hashCode);

      var three = NitriteId.createId("2");
      expect(one, isNot(three));
      expect(one.hashCode, isNot(three.hashCode));
    });

    test('Test Compare', () {
      var one = NitriteId.createId("1");
      var two = NitriteId.createId("2");
      var three = NitriteId.createId("3");

      expect(one.compareTo(two), -1);
      expect(three.compareTo(one), 1);

      one = NitriteId.createId("10");
      two = NitriteId.createId("20");

      expect(one.compareTo(two), -1);

      one = NitriteId.newId();
      two = NitriteId.newId();

      expect(one.compareTo(two), isNot(0));
    });

    test('Test CreatId', () {
      var one = NitriteId.createId("42");
      expect(one.idValue, "42");
      expect(() => NitriteId.createId("value"), throwsInvalidIdException);
    });

    test('Test ValidId', () {
      expect(() => NitriteId.createId("value"), throwsInvalidIdException);
      expect(NitriteId.validId(42), isTrue);
    });

    test('Test Equals', () {
      var one = NitriteId.createId("1");
      var two = NitriteId.createId("1");

      expect(one, two);
    });

    test("Test Uniqueness", () {
      var ids = <NitriteId>{};
      for (var i = 0; i < 100; i++) {
        var id = NitriteId.newId();
        expect(ids.contains(id), isFalse);
        ids.add(id);
      }

      expect(ids.length, 100);
    });
  });
}
