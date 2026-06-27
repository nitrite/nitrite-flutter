import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/index/index_scanner.dart';
import 'package:rxdart/rxdart.dart';

/// @nodoc
class SingleFieldIndex extends NitriteIndex {
  final IndexDescriptor _indexDescriptor;
  final NitriteStore _nitriteStore;

  SingleFieldIndex(this._indexDescriptor, this._nitriteStore) : super();

  @override
  IndexDescriptor get indexDescriptor => _indexDescriptor;

  @override
  Future<void> drop() async {
    if (isUnique) {
      var indexMap = await _findUniqueMap();
      await indexMap.clear();
      await indexMap.drop();
    } else {
      var indexMap = await _findCompositeMap();
      await indexMap.clear();
      await indexMap.drop();
    }
  }

  @override
  Stream<NitriteId> findNitriteIds(FindPlan findPlan) async* {
    if (findPlan.indexScanFilter == null) return;

    var filters = findPlan.indexScanFilter?.filters;
    IndexMap iMap;
    if (isUnique) {
      iMap = IndexMap(nitriteMap: await _findUniqueMap());
    } else {
      iMap = IndexMap(compositeMap: await _findCompositeMap());
    }
    yield* IndexScanner(iMap)
        .doScan(filters, findPlan.indexScanOrder)
        .distinctUnique();
  }

  @override
  Future<void> remove(FieldValues fieldValues) async {
    var firstField = fieldValues.fields.fieldNames.first;
    var element = fieldValues.get(firstField);

    if (isUnique) {
      var indexMap = await _findUniqueMap();
      await _forEachElement(element, (dbValue) async {
        var nitriteIds = await indexMap[dbValue];
        if (nitriteIds != null) {
          nitriteIds.remove(fieldValues.nitriteId);
          if (nitriteIds.isEmpty) {
            await indexMap.remove(dbValue);
          } else {
            await indexMap.put(dbValue, nitriteIds);
          }
        }
      });
    } else {
      var indexMap = await _findCompositeMap();
      var id = fieldValues.nitriteId!;
      await _forEachElement(element, (dbValue) async {
        await indexMap.remove(IndexKey(dbValue, id));
      });
    }
  }

  @override
  Future<void> write(FieldValues fieldValues) async {
    var firstField = fieldValues.fields.fieldNames.first;
    var element = fieldValues.get(firstField);

    if (isUnique) {
      var indexMap = await _findUniqueMap();
      await _forEachElement(element, (dbValue) async {
        var nitriteIds = await indexMap[dbValue];
        nitriteIds = addNitriteIds(nitriteIds, fieldValues);
        await indexMap.put(dbValue, nitriteIds);
      });
    } else {
      // one `(value, id)` row per entry: O(1) point insert, no read-modify-write
      var indexMap = await _findCompositeMap();
      var id = fieldValues.nitriteId!;
      await _forEachElement(element, (dbValue) async {
        await indexMap.put(IndexKey(dbValue, id), true);
      });
    }
  }

  /// Invokes [action] once per indexed element. A `null` element maps to a
  /// [DBNull] key, a single comparable to one key, and an iterable (multikey
  /// index) to one key per item.
  Future<void> _forEachElement(
      dynamic element, Future<void> Function(DBValue) action) async {
    if (element == null) {
      await action(DBNull.instance);
    } else if (element is Comparable) {
      await action(DBValue(element));
    } else if (element is Iterable) {
      for (var item in element) {
        await action(item == null ? DBNull.instance : DBValue(item));
      }
    }
  }

  Future<NitriteMap<DBValue, List<dynamic>>> _findUniqueMap() {
    var mapName = deriveIndexMapName(_indexDescriptor);
    return _nitriteStore.openMap<DBValue, List<dynamic>>(mapName);
  }

  Future<NitriteMap<IndexKey, bool>> _findCompositeMap() {
    var mapName = deriveIndexMapName(_indexDescriptor);
    return _nitriteStore.openMap<IndexKey, bool>(mapName);
  }
}
