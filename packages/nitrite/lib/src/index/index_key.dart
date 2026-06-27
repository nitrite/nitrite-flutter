import 'package:nitrite/nitrite.dart';

/// Where a sentinel [IndexKey] sorts relative to the real entries sharing the
/// same value: [lower] before all of them, [upper] after all of them.
enum _Bound { lower, exact, upper }

/// A composite key for a non-unique index: a field [value] paired with the
/// document [id].
///
/// Non-unique indexes store one `(value, id)` entry per indexed document. This
/// makes inserts and removals O(1) point operations, instead of reading,
/// mutating and re-writing a growing id-list stored under a single value key
/// (which is O(n) per write and O(n²) to bulk-load a low-cardinality field).
///
/// Equality on a value is a prefix range scan over `[lowerBound, upperBound]`.
class IndexKey implements Comparable<IndexKey> {
  /// The indexed field value (a [DBValue], possibly [DBNull]).
  final DBValue value;

  /// The document id for this entry, or `null` for a transient range sentinel.
  final NitriteId? id;

  final _Bound _bound;

  /// A real, stored `(value, id)` entry.
  IndexKey(this.value, NitriteId this.id) : _bound = _Bound.exact;

  IndexKey._bound(this.value, this._bound) : id = null;

  /// A transient sentinel that sorts before every stored entry for [value].
  factory IndexKey.lowerBound(DBValue value) =>
      IndexKey._bound(value, _Bound.lower);

  /// A transient sentinel that sorts after every stored entry for [value].
  factory IndexKey.upperBound(DBValue value) =>
      IndexKey._bound(value, _Bound.upper);

  int get _boundRank => switch (_bound) {
        _Bound.lower => -1,
        _Bound.exact => 0,
        _Bound.upper => 1,
      };

  @override
  int compareTo(IndexKey other) {
    var c = value.compareTo(other.value);
    if (c != 0) return c;

    var b = _boundRank.compareTo(other._boundRank);
    if (b != 0) return b;

    // both exact entries with the same value: order by id
    if (id == null || other.id == null) return 0;
    return id!.compareTo(other.id!);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndexKey &&
          _bound == other._bound &&
          value == other.value &&
          id == other.id;

  @override
  int get hashCode => Object.hash(value, id, _bound);

  @override
  String toString() => 'IndexKey($value, ${id?.idValue})';
}
