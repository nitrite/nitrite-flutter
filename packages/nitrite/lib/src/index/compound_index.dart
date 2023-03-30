import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/async/executor.dart';
import 'package:nitrite/src/common/util/index_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/index/index_map.dart';
import 'package:nitrite/src/index/index_scanner.dart';
import 'package:nitrite/src/index/nitrite_index.dart';
import 'package:rxdart/rxdart.dart';

/// Represents a nitrite compound index.
class CompoundIndex extends NitriteIndex {
  final IndexDescriptor _indexDescriptor;
  final NitriteStore _nitriteStore;

  CompoundIndex(this._indexDescriptor, this._nitriteStore) : super();

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
    var firstValue = fieldValues.get(firstField);

    // NOTE: only first field can have iterable value, subsequent fields can not
    validateIndexField(firstValue, firstField);
    var indexMap = await _findIndexMap();

    if (firstValue == null) {
      await _removeIndexElement(indexMap, fieldValues, DBNull.instance);
    } else if (firstValue is Comparable) {
      // wrap around db value
      var dbValue = DBValue(firstValue);
      await _removeIndexElement(indexMap, fieldValues, dbValue);
    } else if (firstValue is Iterable) {
      var executor = Executor();
      for (var item in firstValue) {
        // wrap around db value
        var dbValue = item != null ? DBValue(item) : DBNull.instance;
        // remove index element in parallel
        executor
            .submit(() => _removeIndexElement(indexMap, fieldValues, dbValue));
      }
      await executor.execute();
    }
  }

  @override
  Future<void> write(FieldValues fieldValues) async {
    var fields = fieldValues.fields;
    var fieldNames = fields.fieldNames;

    var firstField = fieldNames.first;
    var firstValue = fieldValues.get(firstField);

    // NOTE: only first field can have iterable value, subsequent fields can not
    validateIndexField(firstValue, firstField);

    var indexMap = await _findIndexMap();
    if (firstValue == null) {
      await _addIndexElement(indexMap, fieldValues, DBNull.instance);
    } else if (firstValue is Comparable) {
      //wrap around a db value
      var dbValue = DBValue(firstValue);
      await _addIndexElement(indexMap, fieldValues, dbValue);
    } else if (firstValue is Iterable) {
      var executor = Executor();
      for (var item in firstValue) {
        // wrap around db value
        var dbValue = item != null ? DBValue(item) : DBNull.instance;
        // add index element in parallel
        executor.submit(
            () async => await _addIndexElement(indexMap, fieldValues, dbValue));
      }
      await executor.execute();
    }
  }

  Future<NitriteMap<DBValue, Map>> _findIndexMap() {
    var mapName = deriveIndexMapName(_indexDescriptor);
    return _nitriteStore.openMap<DBValue, Map>(mapName);
  }

  Stream<NitriteId> _scanIndex(
      FindPlan findPlan, NitriteMap<DBValue, Map> indexMap) {
    var filters = findPlan.indexScanFilter?.filters;
    var iMap = IndexMap(nitriteMap: indexMap);
    var indexScanner = IndexScanner(iMap);
    return indexScanner
        .doScan(filters, findPlan.indexScanOrder)
        .distinctUnique();
  }

  Future<void> _addIndexElement(NitriteMap<DBValue, Map> indexMap,
      FieldValues fieldValues, DBValue element) async {
    var subMap = await indexMap[element];
    subMap ??= <DBValue, dynamic>{};

    _populateSubMap(subMap, fieldValues, 1);
    return indexMap.put(element, subMap);
  }

  Future<void> _removeIndexElement(NitriteMap<DBValue, Map> indexMap,
      FieldValues fieldValues, DBValue element) async {
    var subMap = await indexMap[element];

    if (subMap != null && subMap.isNotEmpty) {
      _deleteFromSubMap(subMap, fieldValues, 1);
      return indexMap.put(element, subMap);
    }
  }

  void _populateSubMap(Map subMap, FieldValues fieldValues, int depth) {
    if (depth >= fieldValues.values.length) return;

    var pair = fieldValues.values[depth];
    var value = pair.second;
    DBValue dbValue;
    if (value == null) {
      dbValue = DBNull.instance;
    } else {
      if (value is Iterable) {
        throw IndexingException('Compound multikey index is supported on the '
            'first field of the index only');
      }

      if (value is! Comparable) {
        throw IndexingException('$value is not a comparable type');
      }
      dbValue = DBValue(value);
    }

    if (depth == fieldValues.values.length - 1) {
      // terminal field
      var nitriteIds = subMap[dbValue];
      nitriteIds = addNitriteIds(nitriteIds, fieldValues);
      subMap[dbValue] = nitriteIds;
    } else {
      // intermediate fields
      var subMap2 = subMap[dbValue];
      subMap2 ??= <DBValue, dynamic>{};

      subMap[dbValue] = subMap2;
      _populateSubMap(subMap2, fieldValues, depth + 1);
    }
  }

  void _deleteFromSubMap(Map subMap, FieldValues fieldValues, int depth) {
    var pair = fieldValues.values[depth];
    var value = pair.second;
    DBValue dbValue;
    if (value == null) {
      dbValue = DBNull.instance;
    } else {
      if (value is! Comparable) {
        return;
      }
      dbValue = DBValue(value);
    }

    if (depth == fieldValues.values.length - 1) {
      // terminal field
      var nitriteIds = subMap[dbValue] as List<NitriteId>;
      nitriteIds = removeNitriteIds(nitriteIds, fieldValues);
      if (nitriteIds.isNullOrEmpty) {
        subMap.remove(dbValue);
      } else {
        subMap[dbValue] = nitriteIds;
      }
    } else {
      // intermediate fields
      var subMap2 = subMap[dbValue];
      if (subMap2 == null) return;

      _deleteFromSubMap(subMap2, fieldValues, depth + 1);
      subMap[dbValue] = subMap2;
    }
  }
}
