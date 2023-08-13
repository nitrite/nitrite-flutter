import 'package:nitrite/src/common/util/spatial_key.dart';
import 'package:test/test.dart';

void main() {
  group(retry: 3, "Spatial Key Test Suite", () {
    test("Test Min", () {
      var key = SpatialKey(1, [1.1, 2.2, 1.5, 2.5]);

      expect(key.min(0), 1.1);
      expect(key.min(1), 1.5);
    });

    test("Test Max", () {
      var key = SpatialKey(1, [1.1, 2.2, 1.5, 2.5]);

      expect(key.max(0), 2.2);
      expect(key.max(1), 2.5);
    });

    test("Test SetMin", () {
      var key = SpatialKey(1, [1.1, 2.2, 1.5, 2.5]);
      key.setMin(1, 2.1);

      expect(key.min(0), 1.1);
      expect(key.min(1), 2.1);
    });

    test("Test SetMax", () {
      var key = SpatialKey(1, [1.1, 2.2, 1.5, 2.5]);
      key.setMax(1, 3.5);

      expect(key.max(0), 2.2);
      expect(key.max(1), 3.5);
    });

    test("Test IsNull", () {
      var key = SpatialKey(1, []);
      expect(key.isNull(), isTrue);

      key = SpatialKey(1, [1.1, 2.2, 1.5, 2.5]);
      expect(key.isNull(), isFalse);
    });

    test("Test Equals", () {
      var key1 = SpatialKey(1, [1.1, 2.2, 1.5, 2.5]);
      var key2 = SpatialKey(2, [1.1, 2.2, 1.5, 2.5]);
      var key3 = SpatialKey(1, [1.1, 2.2, 1.5, 3.5]);

      expect(key1 == key2, isFalse);
      expect(key3 == key2, isFalse);
      expect(key3 == key1, isFalse);

      key3.setMax(1, 2.5);
      expect(key3 == key1, isTrue);
      expect(key1 == key1, isTrue);
    });

    test("Test HashCode", () {
      var key1 = SpatialKey(1, [1.1, 2.2, 1.5, 2.5]);
      var key2 = SpatialKey(2, [1.1, 2.2, 1.5, 2.5]);
      var key3 = SpatialKey(1, [1.1, 2.2, 1.5, 3.5]);

      expect(key1.hashCode == key2.hashCode, isFalse);
      expect(key3.hashCode == key2.hashCode, isFalse);
      expect(key3.hashCode == key1.hashCode, isTrue);

      key3.setMax(1, 2.5);
      expect(key3.hashCode == key1.hashCode, isTrue);
      expect(key1.hashCode == key1.hashCode, isTrue);
    });
  });
}
