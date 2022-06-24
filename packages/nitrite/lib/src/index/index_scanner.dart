import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/filters/filter.dart';
import 'package:nitrite/src/index/index_map.dart';

class IndexScanner {
  final IndexMap _indexMap;

  IndexScanner(this._indexMap);

  Stream<NitriteId> doScan(Iterable<ComparableFilter>? filters,
      Map<String, bool> indexScanOrder) async* {
    if (filters != null && filters.isNotEmpty) {
      // get the first filter to start scanning
      ComparableFilter comparableFilter = filters.first;

      // set the scan order of the index map
      var reverseScan = indexScanOrder.containsKey(comparableFilter.field)
          ? indexScanOrder[comparableFilter.field]
          : false;
      _indexMap.reverseScan = reverseScan!;

      // apply the filter on the index map
      // result can be list of nitrite ids or list of navigable maps
      var scanResult =
          comparableFilter.applyOnIndex(_indexMap).asBroadcastStream();

      if (await scanResult.isEmpty) {
        // no results found, return empty stream
        return;
      }

      var type = await _streamType(scanResult);
      switch (type) {
        case _StreamType.nitriteId:
          // if this is a stream of nitrite ids then yield those
          // and no further scanning is required as we have
          // reached the terminal nitrite ids
          yield* scanResult.cast();
          break;
        case _StreamType.treeMap:
          // if this is a stream of sub maps, then take each of the sub map
          // and the next filter and scan the sub map
          var remainingFilters = filters.skip(1);

          await for (var subMap in scanResult) {
            // create an index map from the sub map and scan to get the
            // terminal nitrite ids
            var iMap = IndexMap(navigableMap: subMap);
            var subScanner = IndexScanner(iMap);
            yield* subScanner.doScan(remainingFilters, indexScanOrder);
          }
          break;
      }
    } else {
      // if no more filter left, yield all terminal nitrite ids from
      // index map
      yield* _indexMap.getTerminalNitriteIds();
    }
  }

  Future<_StreamType> _streamType(Stream<dynamic> stream) async {
    var first = await stream.first;
    if (first is SplayTreeMap) {
      return _StreamType.treeMap;
    } else if (first is NitriteId) {
      return _StreamType.nitriteId;
    } else {
      throw FilterException('Unknown stream type');
    }
  }
}

enum _StreamType {
  nitriteId,
  treeMap,
}
