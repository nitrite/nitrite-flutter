import 'dart:math' as math;

import 'package:nitrite/nitrite.dart';

/// Where a sentinel [IndexKey] sorts relative to the real entries sharing the
/// same value prefix: [lower] before all of them, [upper] after all of them.
enum _Bound { lower, exact, upper }

/// A composite key for a non-unique index: a tuple of field [values] paired
/// with the document [id].
///
/// Non-unique indexes (single-field and compound) store one `(values…, id)`
/// entry per indexed document. This makes inserts and removals O(1) point
/// operations, instead of reading, mutating and re-writing a growing id-list
/// (single field) or nested sub-map (compound) stored under one value key —
/// which is O(n) per write and O(n²) to bulk-load a low-cardinality field.
///
/// A query on a value prefix is a range scan over `[lowerBound, upperBound]`
/// of that prefix.
class IndexKey implements Comparable<IndexKey> {
  /// The indexed field value tuple (each a [DBValue], possibly [DBNull]). For a
  /// range sentinel this holds only the fixed prefix.
  final List<DBValue> values;

  /// The document id for this entry, or `null` for a transient range sentinel.
  final NitriteId? id;

  final _Bound _bound;

  /// A real, stored single-field `(value, id)` entry.
  IndexKey(DBValue value, NitriteId this.id)
      : values = [value],
        _bound = _Bound.exact;

  /// A real, stored compound `(values…, id)` entry.
  IndexKey.compound(this.values, NitriteId this.id) : _bound = _Bound.exact;

  IndexKey._bound(this.values, this._bound) : id = null;

  /// A transient sentinel that sorts before every stored entry whose values
  /// start with [prefix].
  factory IndexKey.lowerBound(List<DBValue> prefix) =>
      IndexKey._bound(prefix, _Bound.lower);

  /// A transient sentinel that sorts after every stored entry whose values
  /// start with [prefix].
  factory IndexKey.upperBound(List<DBValue> prefix) =>
      IndexKey._bound(prefix, _Bound.upper);

  /// Convenience accessor for the first (often only) value in the tuple.
  DBValue get value => values.first;

  int get _boundRank => switch (_bound) {
        _Bound.lower => -1,
        _Bound.exact => 0,
        _Bound.upper => 1,
      };

  @override
  int compareTo(IndexKey other) {
    var n = math.min(values.length, other.values.length);
    for (var i = 0; i < n; i++) {
      var c = values[i].compareTo(other.values[i]);
      if (c != 0) return c;
    }

    // common prefix is equal: a shorter sentinel brackets the longer entries
    var b = _boundRank.compareTo(other._boundRank);
    if (b != 0) return b;

    // both exact entries with the same tuple: order by id
    if (id == null || other.id == null) return 0;
    return id!.compareTo(other.id!);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndexKey &&
          _bound == other._bound &&
          id == other.id &&
          _listEquals(values, other.values);

  @override
  int get hashCode => Object.hash(Object.hashAll(values), id, _bound);

  @override
  String toString() => 'IndexKey($values, ${id?.idValue})';

  static bool _listEquals(List<DBValue> a, List<DBValue> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
