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
    var indexMap = await _findIndexMap();
    await indexMap.clear();
    await indexMap.drop();
  }

  @override
  Stream<NitriteId> findNitriteIds(FindPlan findPlan) async* {
    if (findPlan.indexScanFilter == null) return;

    var indexMap = await _findIndexMap();
    yield* _scanIndex(findPlan, indexMap);
  }

  @override
  Future<void> remove(FieldValues fieldValues) async {
    var fields = fieldValues.fields;
    var fieldNames = fields.fieldNames;

    var firstField = fieldNames.first;
    var element = fieldValues.get(firstField);

    var indexMap = await _findIndexMap();
    if (element == null) {
      await _removeIndexElement(indexMap, fieldValues, DBNull.instance);
    } else if (element is Comparable) {
      // wrap around db value
      var dbValue = DBValue(element);
      await _removeIndexElement(indexMap, fieldValues, dbValue);
    } else if (element is Iterable) {
      for (var item in element) {
        // wrap around db value
        var dbValue = item == null ? DBNull.instance : DBValue(item);
        await _removeIndexElement(indexMap, fieldValues, dbValue);
      }
    }
  }

  @override
  Future<void> write(FieldValues fieldValues) async {
    var fields = fieldValues.fields;
    var fieldNames = fields.fieldNames;

    var firstField = fieldNames.first;
    var element = fieldValues.get(firstField);

    var indexMap = await _findIndexMap();

    if (element == null) {
      await _addIndexElement(indexMap, fieldValues, DBNull.instance);
    } else if (element is Comparable) {
      // wrap around db value
      var dbValue = DBValue(element);
      await _addIndexElement(indexMap, fieldValues, dbValue);
    } else if (element is Iterable) {
      for (var item in element) {
        // wrap around db value
        var dbValue = item == null ? DBNull.instance : DBValue(item);
        await _addIndexElement(indexMap, fieldValues, dbValue);
      }
    }
  }

  Future<NitriteMap<DBValue, List<dynamic>>> _findIndexMap() {
    var mapName = deriveIndexMapName(_indexDescriptor);
    return _nitriteStore.openMap<DBValue, List<dynamic>>(mapName);
  }

  Future<void> _addIndexElement(NitriteMap<DBValue, List<dynamic>> indexMap,
      FieldValues fieldValues, DBValue element) async {
    var nitriteIds = await indexMap[element];
    nitriteIds = addNitriteIds(nitriteIds, fieldValues);
    return indexMap.put(element, nitriteIds);
  }

  Future<void> _removeIndexElement(NitriteMap<DBValue, List<dynamic>> indexMap,
      FieldValues fieldValues, DBValue element) async {
    var nitriteIds = await indexMap[element];
    if (nitriteIds != null) {
      nitriteIds.remove(fieldValues.nitriteId);
      if (nitriteIds.isEmpty) {
        await indexMap.remove(element);
      } else {
        await indexMap.put(element, nitriteIds);
      }
    }
  }

  Stream<NitriteId> _scanIndex(
      FindPlan findPlan, NitriteMap<DBValue, List<dynamic>> indexMap) async* {
    var filters = findPlan.indexScanFilter?.filters;
    var iMap = IndexMap(nitriteMap: indexMap);
    var indexScanner = IndexScanner(iMap);
    yield* indexScanner
        .doScan(filters, findPlan.indexScanOrder)
        .distinctUnique();
  }
}
