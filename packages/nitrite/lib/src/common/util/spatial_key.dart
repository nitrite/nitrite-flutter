import 'dart:math' as math;

import 'package:collection/collection.dart';

/// Whether the bounding boxes of [a] and [b] overlap. Null boxes never overlap.
///
/// @nodoc
bool spatialOverlap(SpatialKey a, SpatialKey b) {
  if (a.isNull() || b.isNull()) return false;
  for (var i = 0; i < 2; i++) {
    if (a.max(i) < b.min(i) || a.min(i) > b.max(i)) return false;
  }
  return true;
}

/// Whether [a]'s bounding box lies strictly inside [b]'s. Null boxes are never
/// inside anything.
///
/// @nodoc
bool spatialInside(SpatialKey a, SpatialKey b) {
  if (a.isNull() || b.isNull()) return false;
  for (var i = 0; i < 2; i++) {
    if (a.min(i) <= b.min(i) || a.max(i) >= b.max(i)) return false;
  }
  return true;
}

/// Returns the ids of the [k] spatial keys nearest to the point ([x], [y]),
/// ordered by ascending distance to each key's bounding box. Keys with an empty
/// bounding box are skipped; if [maxDistance] is given, keys farther than it are
/// excluded.
///
/// @nodoc
Iterable<int> nearestNeighborIds(
  Iterable<SpatialKey> keys,
  double x,
  double y,
  int k, [
  double? maxDistance,
]) {
  var scored = <(int, double)>[];
  for (var sk in keys) {
    if (sk.isNull()) continue;
    var d = sk.distanceToPoint(x, y);
    if (maxDistance != null && d > maxDistance) continue;
    scored.add((sk.id, d));
  }
  scored.sort((a, b) => a.$2.compareTo(b.$2));
  return scored.take(k).map((e) => e.$1);
}

/// @nodoc
class SpatialKey {
  final int id;
  final List<double> minMax;

  SpatialKey(this.id, this.minMax);

  double min(int dim) {
    return minMax[dim + dim];
  }

  void setMin(int dim, double value) {
    minMax[dim + dim] = value;
  }

  double max(int dim) {
    return minMax[dim + dim + 1];
  }

  void setMax(int dim, double value) {
    minMax[dim + dim + 1] = value;
  }

  bool isNull() {
    return minMax.isEmpty;
  }

  /// The Euclidean distance from the point ([x], [y]) to this key's bounding
  /// box. Zero if the point lies inside the box.
  double distanceToPoint(double x, double y) {
    var dx = math.max(math.max(min(0) - x, x - max(0)), 0.0);
    var dy = math.max(math.max(min(1) - y, y - max(1)), 0.0);
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  int get hashCode => (id >>> 32) ^ id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    } else if (other is! SpatialKey) {
      return false;
    }

    if (id != other.id) {
      return false;
    }

    return ListEquality().equals(minMax, other.minMax);
  }

  @override
  String toString() {
    return 'SpatialKey{id: $id, minMax: $minMax}';
  }
}

/// Maximum entries/children per R-tree node. 16 keeps nodes shallow while
/// bounding the per-node scan during traversal.
const int _rTreeNodeCapacity = 16;

/// A node in the packed R-tree. Either an internal node ([children] set) or a
/// leaf ([entries] set). [minX]..[maxY] is the node's minimum bounding
/// rectangle.
class _RNode {
  double minX, minY, maxX, maxY;
  final List<_RNode>? children;
  final List<SpatialKey>? entries;

  _RNode.leaf(this.entries, this.minX, this.minY, this.maxX, this.maxY)
      : children = null;
  _RNode.internal(this.children, this.minX, this.minY, this.maxX, this.maxY)
      : entries = null;

  double mindist(double x, double y) {
    var dx = math.max(math.max(minX - x, x - maxX), 0.0);
    var dy = math.max(math.max(minY - y, y - maxY), 0.0);
    return math.sqrt(dx * dx + dy * dy);
  }

  bool overlapsQuery(SpatialKey q) => !(maxX < q.min(0) ||
      minX > q.max(0) ||
      maxY < q.min(1) ||
      minY > q.max(1));
}

class _NearestItem {
  final double dist;
  final _RNode? node;
  final SpatialKey? entry;
  _NearestItem.node(this.dist, this.node) : entry = null;
  _NearestItem.entry(this.dist, this.entry) : node = null;
}

/// An in-memory R-tree over [SpatialKey] entries, giving O(log n + result)
/// window and nearest-neighbour queries instead of a linear scan.
///
/// Entries are held by id and the spatial tree is (re)built lazily on the next
/// query after any mutation using Sort-Tile-Recursive packing, which produces a
/// well-balanced tree in O(n log n).
///
/// ponytail: lazy bulk-rebuild on the first query after a write. A batch of
/// inserts then queries rebuilds once; a tightly interleaved write/read/write
/// workload rebuilds each query (O(n log n) per query). Swap in an incremental
/// (Guttman) insert/split if interleaved write+read ever becomes the hot path.
///
/// @nodoc
class SpatialRTree {
  final Map<int, SpatialKey> _entries = {};
  _RNode? _root;
  bool _dirty = false;

  int get size => _entries.length;

  void put(SpatialKey key) {
    _entries[key.id] = key;
    _dirty = true;
  }

  void removeId(int id) {
    if (_entries.remove(id) != null) _dirty = true;
  }

  void clear() {
    _entries.clear();
    _root = null;
    _dirty = false;
  }

  /// Ids of stored boxes overlapping [query], in no particular order.
  Iterable<int> intersecting(SpatialKey query) sync* {
    if (query.isNull()) return;
    _ensureBuilt();
    yield* _window(query, spatialOverlap);
  }

  /// Ids of stored boxes lying strictly inside [query], in no particular order.
  Iterable<int> contained(SpatialKey query) sync* {
    if (query.isNull()) return;
    _ensureBuilt();
    yield* _window(query, spatialInside);
  }

  Iterable<int> _window(
      SpatialKey query, bool Function(SpatialKey, SpatialKey) match) sync* {
    var root = _root;
    if (root == null) return;
    var stack = <_RNode>[root];
    while (stack.isNotEmpty) {
      var node = stack.removeLast();
      if (!node.overlapsQuery(query)) continue;
      var entries = node.entries;
      if (entries != null) {
        for (var e in entries) {
          if (match(e, query)) yield e.id;
        }
      } else {
        stack.addAll(node.children!);
      }
    }
  }

  /// Ids of the [k] entries nearest to ([x], [y]) in ascending distance,
  /// excluding entries farther than [maxDistance] when given.
  Iterable<int> nearest(double x, double y, int k,
      [double? maxDistance]) sync* {
    if (k <= 0) return;
    _ensureBuilt();
    var root = _root;
    if (root == null) return;
    var pq =
        HeapPriorityQueue<_NearestItem>((a, b) => a.dist.compareTo(b.dist));
    pq.add(_NearestItem.node(root.mindist(x, y), root));
    var found = 0;
    while (pq.isNotEmpty && found < k) {
      var item = pq.removeFirst();
      if (maxDistance != null && item.dist > maxDistance) break;
      var node = item.node;
      if (node == null) {
        yield item.entry!.id;
        found++;
        continue;
      }
      var entries = node.entries;
      if (entries != null) {
        for (var e in entries) {
          pq.add(_NearestItem.entry(e.distanceToPoint(x, y), e));
        }
      } else {
        for (var c in node.children!) {
          pq.add(_NearestItem.node(c.mindist(x, y), c));
        }
      }
    }
  }

  void _ensureBuilt() {
    if (!_dirty) return;
    var keys = _entries.values.where((k) => !k.isNull()).toList();
    _root = keys.isEmpty ? null : _pack(keys);
    _dirty = false;
  }

  /// Sort-Tile-Recursive bulk load of leaf entries into a balanced tree.
  _RNode _pack(List<SpatialKey> keys) {
    var leaves = _packLeaves(keys);
    var nodes = leaves;
    while (nodes.length > 1) {
      nodes = _packLevel(nodes);
    }
    return nodes.first;
  }

  List<_RNode> _packLeaves(List<SpatialKey> keys) {
    keys.sort((a, b) => _centerX(a).compareTo(_centerX(b)));
    var leafCount = (keys.length / _rTreeNodeCapacity).ceil();
    var sliceCount = math.sqrt(leafCount).ceil();
    var sliceSize = sliceCount * _rTreeNodeCapacity;
    var leaves = <_RNode>[];
    for (var s = 0; s < keys.length; s += sliceSize) {
      var slice = keys.sublist(s, math.min(s + sliceSize, keys.length));
      slice.sort((a, b) => _centerY(a).compareTo(_centerY(b)));
      for (var i = 0; i < slice.length; i += _rTreeNodeCapacity) {
        var chunk =
            slice.sublist(i, math.min(i + _rTreeNodeCapacity, slice.length));
        leaves.add(_leafNode(chunk));
      }
    }
    return leaves;
  }

  List<_RNode> _packLevel(List<_RNode> nodes) {
    nodes.sort((a, b) => ((a.minX + a.maxX)).compareTo(b.minX + b.maxX));
    var parentCount = (nodes.length / _rTreeNodeCapacity).ceil();
    var sliceCount = math.sqrt(parentCount).ceil();
    var sliceSize = sliceCount * _rTreeNodeCapacity;
    var parents = <_RNode>[];
    for (var s = 0; s < nodes.length; s += sliceSize) {
      var slice = nodes.sublist(s, math.min(s + sliceSize, nodes.length));
      slice.sort((a, b) => (a.minY + a.maxY).compareTo(b.minY + b.maxY));
      for (var i = 0; i < slice.length; i += _rTreeNodeCapacity) {
        var chunk =
            slice.sublist(i, math.min(i + _rTreeNodeCapacity, slice.length));
        parents.add(_internalNode(chunk));
      }
    }
    return parents;
  }

  _RNode _leafNode(List<SpatialKey> chunk) {
    var minX = chunk.first.min(0), minY = chunk.first.min(1);
    var maxX = chunk.first.max(0), maxY = chunk.first.max(1);
    for (var e in chunk) {
      minX = math.min(minX, e.min(0));
      minY = math.min(minY, e.min(1));
      maxX = math.max(maxX, e.max(0));
      maxY = math.max(maxY, e.max(1));
    }
    return _RNode.leaf(chunk, minX, minY, maxX, maxY);
  }

  _RNode _internalNode(List<_RNode> chunk) {
    var minX = chunk.first.minX, minY = chunk.first.minY;
    var maxX = chunk.first.maxX, maxY = chunk.first.maxY;
    for (var c in chunk) {
      minX = math.min(minX, c.minX);
      minY = math.min(minY, c.minY);
      maxX = math.max(maxX, c.maxX);
      maxY = math.max(maxY, c.maxY);
    }
    return _RNode.internal(chunk, minX, minY, maxX, maxY);
  }

  double _centerX(SpatialKey k) => (k.min(0) + k.max(0)) / 2;
  double _centerY(SpatialKey k) => (k.min(1) + k.max(1)) / 2;
}
