import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/filters/filter.dart';

/// @nodoc
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

      for (var item in element) {
        await _addIndexElement(indexMap, fieldValues, item);
      }
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

      for (var item in element) {
        await _removeIndexElement(indexMap, fieldValues, item);
      }
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
      throw FilterException("TextFilter can only be applied on text index.");
    }
  }

  Future<NitriteMap<String, List<dynamic>>> _findIndexMap() {
    var mapName = deriveIndexMapName(_indexDescriptor);
    return _nitriteStore.openMap<String, List<dynamic>>(mapName);
  }

  Future<void> _addIndexElement(NitriteMap<String, List<dynamic>> indexMap,
      FieldValues fieldValues, String? value) async {
    var words = _decompose(value);

    for (var word in words) {
      var values = await indexMap[word];
      values ??= <NitriteId>[];
      List nitriteIds = castList<NitriteId>(values);
      nitriteIds = addNitriteIds(nitriteIds, fieldValues);
      await indexMap.put(word, nitriteIds);
    }
  }

  Future<void> _removeIndexElement(NitriteMap<String, List<dynamic>> indexMap,
      FieldValues fieldValues, String? value) async {
    var words = _decompose(value);

    for (var word in words) {
      var nitriteIds = await indexMap[word];
      if (!nitriteIds.isNullOrEmpty) {
        nitriteIds!.remove(fieldValues.nitriteId);
        if (nitriteIds.isEmpty) {
          await indexMap.remove(word);
        } else {
          await indexMap.put(word, nitriteIds);
        }
      }
    }
  }

  Set<String> _decompose(String? value) {
    if (value == null) return {};
    return _textTokenizer.tokenize(value);
  }
}
