import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';
import 'package:dart_numerics/dart_numerics.dart' as num;

void main() async {

  group('Nitrite Id Test Suite', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Test Limit', () async {
      var one = await NitriteId.createId(num.int64MaxValue.toString());
      var two = await NitriteId.createId(num.int64MinValue.toString());
      expect(one.compareTo(two), 1);
    });

    test("Test Hash Equals", () async {
      var one = await NitriteId.createId("1");
      var two = await NitriteId.createId("1");

      expect(one, two);
      expect(one.hashCode, two.hashCode);

      var three = await NitriteId.createId("2");
      expect(one, isNot(three));
      expect(one.hashCode, isNot(three.hashCode));
    });

    test('Test Compare', () async {
      var one = await NitriteId.createId("1");
      var two = await NitriteId.createId("2");
      var three = await NitriteId.createId("3");

      expect(one.compareTo(two), -1);
      expect(three.compareTo(one), 1);

      one = await NitriteId.createId("10");
      two = await NitriteId.createId("20");

      expect(one.compareTo(two), -1);

      one = await NitriteId.newId();
      two = await NitriteId.newId();

      expect(one.compareTo(two), isNot(0));
    });

    test('Test CreatId', () async {
      var one = await NitriteId.createId("42");
      expect(one.idValue, "42");
      expect(() async => NitriteId.createId("value"), throwsException);
    });

    test('Test ValidId', () async {
      expect(() async => NitriteId.createId("value"), throwsException);
      expect(NitriteId.validId(42), isTrue);
    });

    test('Test Equals', () async {
      var one = await NitriteId.createId("1");
      var two = await NitriteId.createId("1");

      expect(one, two);
    });
  });
}
