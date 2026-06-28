import 'dart:math';

import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

// Cross-checks the packed R-tree against a brute-force linear scan over the
// same keys, so any bug in STR packing / pruning / best-first knn fails here.
void main() {
  SpatialKey box(int id, double minX, double minY, double maxX, double maxY) =>
      SpatialKey(id, [minX, maxX, minY, maxY]);

  group('SpatialRTree matches brute force', () {
    final rnd = Random(42);
    late List<SpatialKey> keys;
    late SpatialRTree tree;

    setUp(() {
      keys = [];
      tree = SpatialRTree();
      for (var i = 1; i <= 500; i++) {
        var x = rnd.nextDouble() * 1000;
        var y = rnd.nextDouble() * 1000;
        var w = rnd.nextDouble() * 50;
        var h = rnd.nextDouble() * 50;
        var k = box(i, x, y, x + w, y + h);
        keys.add(k);
        tree.put(k);
      }
    });

    test('intersecting', () {
      for (var t = 0; t < 50; t++) {
        var x = rnd.nextDouble() * 1000;
        var y = rnd.nextDouble() * 1000;
        var q = box(0, x, y, x + 100, y + 100);
        var expected =
            keys.where((k) => spatialOverlap(k, q)).map((k) => k.id).toSet();
        expect(tree.intersecting(q).toSet(), expected);
      }
    });

    test('contained', () {
      for (var t = 0; t < 50; t++) {
        var x = rnd.nextDouble() * 1000;
        var y = rnd.nextDouble() * 1000;
        var q = box(0, x, y, x + 200, y + 200);
        var expected =
            keys.where((k) => spatialInside(k, q)).map((k) => k.id).toSet();
        expect(tree.contained(q).toSet(), expected);
      }
    });

    test('nearest k ascending, with maxDistance', () {
      for (var t = 0; t < 20; t++) {
        var x = rnd.nextDouble() * 1000;
        var y = rnd.nextDouble() * 1000;
        var maxDist = rnd.nextBool() ? null : rnd.nextDouble() * 300;
        var k = 1 + rnd.nextInt(10);
        var expected = nearestNeighborIds(keys, x, y, k, maxDist).toSet();
        var actual = tree.nearest(x, y, k, maxDist).toList();
        // best-first yields ascending distance and the same chosen set
        expect(actual.toSet(), expected);
        var dists =
            actual.map((id) => keys[id - 1].distanceToPoint(x, y)).toList();
        for (var i = 1; i < dists.length; i++) {
          expect(dists[i] >= dists[i - 1], isTrue);
        }
      }
    });

    test('removal is reflected', () {
      for (var i = 1; i <= 250; i++) {
        tree.removeId(i);
      }
      var remaining = keys.skip(250).toList();
      var q = box(0, 0, 0, 1000, 1000);
      var expected =
          remaining.where((k) => spatialOverlap(k, q)).map((k) => k.id).toSet();
      expect(tree.intersecting(q).toSet(), expected);
      expect(tree.size, 250);
    });

    test('empty query and empty tree', () {
      expect(tree.intersecting(SpatialKey(0, [])).toList(), isEmpty);
      var empty = SpatialRTree();
      expect(empty.intersecting(box(0, 0, 0, 1, 1)).toList(), isEmpty);
      expect(empty.nearest(0, 0, 5).toList(), isEmpty);
    });
  });
}
