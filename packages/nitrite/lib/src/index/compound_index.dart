import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/index/index_scanner.dart';
import 'package:rxdart/rxdart.dart';

/// @nodoc
///
/// Compound index over two or more fields. Both unique and non-unique variants
/// store one flat composite key `(values…, id)` per document, so writes and
/// removals are O(1) point operations. Uniqueness is enforced with an O(log n)
/// prefix probe rather than a separate nested-map layout.
class CompoundIndex extends NitriteIndex {
  final IndexDescriptor _indexDescriptor;
  final NitriteStore _nitriteStore;

  CompoundIndex(this._indexDescriptor, this._nitriteStore) : super();

  @override
  IndexDescriptor get indexDescriptor => _indexDescriptor;

  int get _fieldCount => _indexDescriptor.fields.fieldNames.length;

  @override
  Future<void> drop() async {
    var indexMap = await _findCompositeMap();
    await indexMap.clear();
    await indexMap.drop();
  }

  @override
  Stream<NitriteId> findNitriteIds(FindPlan findPlan) async* {
    if (findPlan.indexScanFilter == null) return;

    var filters = findPlan.indexScanFilter?.filters;
    var iMap = IndexMap(
        compositeMap: await _findCompositeMap(),
        compositeFieldCount: _fieldCount);
    yield* IndexScanner(iMap)
        .doScan(filters, findPlan.indexScanOrder)
        .distinctUnique();
  }

  @override
  Future<void> write(FieldValues fieldValues) async {
    var indexMap = await _findCompositeMap();
    var id = fieldValues.nitriteId!;
    var unique = isUnique;
    for (var tuple in _buildTuples(fieldValues)) {
      if (unique) {
        await _checkUnique(indexMap, tuple, id);
      }
      await indexMap.put(IndexKey.compound(tuple, id), true);
    }
  }

  @override
  Future<void> remove(FieldValues fieldValues) async {
    var indexMap = await _findCompositeMap();
    var id = fieldValues.nitriteId!;
    for (var tuple in _buildTuples(fieldValues)) {
      await indexMap.remove(IndexKey.compound(tuple, id));
    }
  }

  /// Enforces a unique compound constraint: the field-value [tuple] must not
  /// already map to a different id. `lowerBound(tuple)` sorts immediately before
  /// every stored row for that tuple, so the ceiling lands on the first such
  /// row (if any) in O(log n).
  Future<void> _checkUnique(
      NitriteMap<IndexKey, bool> indexMap, List<DBValue> tuple, NitriteId id) async {
    var ceiling = await indexMap.ceilingKey(IndexKey.lowerBound(tuple));
    if (ceiling != null &&
        ceiling.id != null &&
        ceiling.id != id &&
        _tupleEquals(ceiling.values, tuple)) {
      throw UniqueConstraintException(
          'Unique key constraint violation for ${_indexDescriptor.fields}');
    }
  }

  bool _tupleEquals(List<DBValue> a, List<DBValue> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].compareTo(b[i]) != 0) return false;
    }
    return true;
  }

  /// Builds the `(values…)` tuples for a document. Only the first field may be
  /// an iterable (multikey), yielding one tuple per item; the remaining fields
  /// must each be a single comparable (or null).
  List<List<DBValue>> _buildTuples(FieldValues fieldValues) {
    var fieldNames = _indexDescriptor.fields.fieldNames;
    var firstField = fieldNames.first;
    var firstValue = fieldValues.get(firstField);
    validateIndexField(firstValue, firstField);

    var tail = <DBValue>[];
    for (var i = 1; i < fieldNames.length; i++) {
      var value = fieldValues.get(fieldNames[i]);
      if (value == null) {
        tail.add(DBNull.instance);
      } else if (value is Iterable) {
        throw IndexingException('Compound multikey index is supported on the '
            'first field of the index only');
      } else if (value is Comparable) {
        tail.add(DBValue(value));
      } else {
        throw IndexingException('$value is not a comparable type');
      }
    }

    if (firstValue == null) {
      return [
        [DBNull.instance, ...tail]
      ];
    } else if (firstValue is Iterable) {
      return [
        for (var item in firstValue)
          [item == null ? DBNull.instance : DBValue(item), ...tail]
      ];
    } else {
      return [
        [DBValue(firstValue as Comparable), ...tail]
      ];
    }
  }

  Future<NitriteMap<IndexKey, bool>> _findCompositeMap() {
    var mapName = deriveIndexMapName(_indexDescriptor);
    return _nitriteStore.openMap<IndexKey, bool>(mapName);
  }
}
