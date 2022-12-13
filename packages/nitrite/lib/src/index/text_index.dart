import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/async/executor.dart';
import 'package:nitrite/src/common/util/index_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/index/nitrite_index.dart';

class TextIndex extends NitriteIndex {
  final IndexDescriptor _indexDescriptor;
  final NitriteStore _nitriteStore;
  final TextTokenizer _textTokenizer;

  TextIndex(this._textTokenizer, this._indexDescriptor, this._nitriteStore);

  @override
  IndexDescriptor get indexDescriptor => _indexDescriptor;

  @override
  Future<void> write(FieldValues fieldValues) async {
    var fields = fieldValues.fields;
    var fieldNames = fields.fieldNames;

    var firstField = fieldNames.first;
    var element = fieldValues.get(firstField);

    var indexMap = await _findIndexMap();

    if (element == null) {
      await _addIndexElement(indexMap, fieldValues, null);
    } else if (element is String) {
      await _addIndexElement(indexMap, fieldValues, element);
    } else if (element is Iterable) {
      validateStringIterableIndexField(element, firstField);

      var executor = Executor();
      for (var item in element) {
        // add index element in parallel
        executor.submit(() async => await _addIndexElement(indexMap, fieldValues, item));
      }
      await executor.execute();
    } else {
      throw IndexingException("Index field $firstField must be a "
          "String or Iterable<String>");
    }
  }

  @override
  Future<void> remove(FieldValues fieldValues) async {
    var fields = fieldValues.fields;
    var fieldNames = fields.fieldNames;

    var firstField = fieldNames.first;
    var element = fieldValues.get(firstField);

    var indexMap = await _findIndexMap();

    if (element == null) {
      await _removeIndexElement(indexMap, fieldValues, null);
    } else if (element is String) {
      await _removeIndexElement(indexMap, fieldValues, element);
    } else if (element is Iterable) {
      validateStringIterableIndexField(element, firstField);

      var executor = Executor();
      for (var item in element) {
        // remove index element in parallel
        executor.submit(() async => await _removeIndexElement(indexMap, fieldValues, item));
      }
      await executor.execute();
    } else {
      throw IndexingException("Index field $firstField must be a "
          "String or Iterable<String>");
    }
  }

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
    var filters = findPlan.indexScanFilter!.filters;

    if (filters.length == 1 && filters.first is TextFilter) {
      var textFilter = filters.first as TextFilter;
      textFilter.textTokenizer = _textTokenizer;
      yield* textFilter.applyOnTextIndex(indexMap).distinct();
    } else {
      throw FilterException("Text index only supports a single TextFilter");
    }
  }

  Future<NitriteMap<String, List<dynamic>>> _findIndexMap() {
    var mapName = deriveIndexMapName(_indexDescriptor);
    return _nitriteStore.openMap<String, List<dynamic>>(mapName);
  }

  Future<void> _addIndexElement(NitriteMap<String, List<dynamic>> indexMap,
      FieldValues fieldValues, String? value) async {
    var words = _decompose(value);

    var executor = Executor();
    for (var word in words) {
      var nitriteIds = await indexMap[word];
      nitriteIds ??= <NitriteId>[];
      nitriteIds = addNitriteIds(nitriteIds as List<NitriteId>, fieldValues);
      // update index map in parallel
      executor.submit(() async => await indexMap.put(word, nitriteIds!));
    }
    await executor.execute();
  }

  Future<void> _removeIndexElement(NitriteMap<String, List<dynamic>> indexMap,
      FieldValues fieldValues, String? value) async {
    var words = _decompose(value);

    var executor = Executor();
    for (var word in words) {
      var nitriteIds = await indexMap[word];
      if (!nitriteIds.isNullOrEmpty) {
        nitriteIds!.remove(fieldValues.nitriteId);
        // update index map in parallel
        executor.submit(() async {
          if (nitriteIds.isEmpty) {
            await indexMap.remove(word);
          } else {
            await indexMap.put(word, nitriteIds);
          }
        });
      }
    }
    await executor.execute();
  }

  Set<String> _decompose(String? value) {
    if (value == null) return {};
    return _textTokenizer.tokenize(value);
  }
}
