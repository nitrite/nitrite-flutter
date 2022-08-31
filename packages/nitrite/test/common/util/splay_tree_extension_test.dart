import 'dart:collection';

import 'package:nitrite/src/common/util/splay_tree_extensions.dart';
import 'package:test/test.dart';

void main() {
  group("SplayTree Extension Test Suite", () {
    late SplayTreeMap<int, String> map;

    setUp(() {
      map = SplayTreeMap<int, String>();
      map[1] = 'a';
      map[10] = 'aa';
      map[7] = 'ba';
      map[2] = 'ca';
      map[21] = 'ad';
      map[11] = 'ae';
    });

    test("Test HigherKey", () {
      expect(map.higherKey(-10), 1);
      expect(map.higherKey(1), 2);
      expect(map.higherKey(15), 21);
      expect(map.higherKey(35), null);
    });

    test("Test CeilingKey", () {
      expect(map.ceilingKey(-10), 1);
      expect(map.ceilingKey(1), 1);
      expect(map.ceilingKey(15), 21);
      expect(map.ceilingKey(35), null);
    });

    test("Test LowerKey", () {
      expect(map.lowerKey(-10), null);
      expect(map.lowerKey(1), null);
      expect(map.lowerKey(10), 7);
      expect(map.lowerKey(35), 21);
    });

    test("Test FloorKey", () {
      expect(map.floorKey(-10), null);
      expect(map.floorKey(1), 1);
      expect(map.floorKey(10), 10);
      expect(map.floorKey(35), 21);
    });

    test("Test ReversedEntries", () {
      var reversedMap = [
        MapEntry(21, 'ad'),
        MapEntry(11, 'ae'),
        MapEntry(10, 'aa'),
        MapEntry(7, 'ba'),
        MapEntry(2, 'ca'),
        MapEntry(1, 'a'),
      ];

      expect(map.reversedEntries.toList().toString(), reversedMap.toString());
    });
  });
}