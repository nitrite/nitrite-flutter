part of 'filter.dart';

class IndexScanFilter extends Filter {
  final Iterable<ComparableFilter> filters;

  IndexScanFilter(this.filters);

  @override
  bool apply(Document doc) {
    throw InvalidOperationException(
        "Index scan filter cannot be applied on collection");
  }
}

class EqualsFilter extends ComparableFilter {
  EqualsFilter(String field, dynamic value) : super(field, value);

  @override
  bool apply(Document doc) {
    var fieldValue = doc.get(field);
    return deepEquals(fieldValue, value);
  }

  @override
  List applyOnIndex(IndexMap indexMap) {
    var val = indexMap.get(value as Comparable);
    if (val is List) {
      return val;
    }

    var result = <List<dynamic>>[];
    result.add(val);
    return result;
  }

  @override
  toString() => "($field == $value)";
}

class OrFilter extends LogicalFilter {
  OrFilter(List<Filter> filters) : super(filters);

  @override
  bool apply(Document doc) {
    for (var filter in filters) {
      if (filter.apply(doc)) {
        return true;
      }
    }

    return false;
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write("(");
    for (var i = 0; i < filters.length; i++) {
      if (i > 0) {
        buffer.write(" | ");
      }
      buffer.write(filters[i].toString());
    }
    buffer.write(")");
    return buffer.toString();
  }
}

class AndFilter extends LogicalFilter {
  AndFilter(List<Filter> filters) : super(filters) {
    for (int i = 1; i < filters.length; i++) {
      if (filters[i] is TextFilter) {
        throw FilterException(
            "Text filter must be the first filter in AND operation");
      }
    }
  }

  @override
  bool apply(Document doc) {
    for (var filter in filters) {
      if (!filter.apply(doc)) {
        return false;
      }
    }

    return true;
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write("(");
    for (var i = 0; i < filters.length; i++) {
      if (i > 0) {
        buffer.write(" & ");
      }
      buffer.write(filters[i].toString());
    }
    buffer.write(")");
    return buffer.toString();
  }
}

class TextFilter extends StringFilter {
  TextTokenizer? _tokenizer;

  TextFilter(String field, String value) : super(field, value);

  set textTokenizer(TextTokenizer tokenizer) {
    _tokenizer = tokenizer;
  }

  @override
  bool apply(Document doc) {
    field.notNullOrEmpty("field cannot be null or empty");
    stringValue.notNullOrEmpty("search term cannot be null or empty");

    var fieldValue = doc.get(field);

    if (fieldValue is! String) {
      throw FilterException("Text filter can not be applied on "
          "non string field $field");
    }

    var searchString = stringValue;
    if (searchString.startsWith("*") || searchString.endsWith("*")) {
      searchString = searchString.replaceAll("*", "");
    }

    return fieldValue.toLowerCase().contains(searchString.toLowerCase());
  }

  @override
  List applyOnIndex(IndexMap indexMap) {
    return [];
  }

  @override
  String toString() => "($field like $value)";

  Future<Set<NitriteId>> applyOnTextIndex(
      NitriteMap<String, List> indexMap) async {
    field.notNullOrEmpty("field cannot be null or empty");
    stringValue.notNullOrEmpty("search term cannot be null or empty");

    var searchString = stringValue;
    if (searchString.startsWith("*") || searchString.endsWith("*")) {
      return await _searchByWildCard(indexMap, searchString);
    } else {
      return await _searchExactByIndex(indexMap, searchString);
    }
  }

  Future<Set<NitriteId>> _searchExactByIndex(
      NitriteMap<String, List> indexMap, String searchString) async {
    if (_tokenizer != null) {
      var words = _tokenizer!.tokenize(searchString);
      var scoreMap = <NitriteId, int>{};
      for (var word in words) {
        var nitriteIds = await indexMap[word];
        if (nitriteIds != null) {
          for (var nitriteId in nitriteIds) {
            var score = scoreMap[nitriteId];
            if (score == null) {
              scoreMap[nitriteId] = 1;
            } else {
              scoreMap[nitriteId] = score + 1;
            }
          }
        }
      }

      return Future.value(_sortedIdsByScore(scoreMap));
    }

    return Future.value(<NitriteId>{});
  }

  Future<Set<NitriteId>> _searchByWildCard(
      NitriteMap<String, List> indexMap, String searchString) async {
    if (searchString == "*") {
      throw FilterException("* is not a valid search term");
    }

    if (_tokenizer != null) {
      var words = _tokenizer!.tokenize(searchString);
      if (words.length > 1) {
        throw FilterException("Wild card search can not be applied on "
            "multiple words");
      }

      if (searchString.startsWith("*") && !searchString.endsWith("*")) {
        return await _searchByLeadingWildCard(indexMap, searchString);
      } else if (searchString.endsWith("*") && !searchString.startsWith("*")) {
        return await _searchByTrailingWildCard(indexMap, searchString);
      } else {
        var term = searchString.substring(1, searchString.length - 1);
        return await _searchContains(indexMap, term);
      }
    }

    return Future.value(<NitriteId>{});
  }

  Future<Set<NitriteId>> _searchByLeadingWildCard(
      NitriteMap<String, List> indexMap, String searchString) async {
    if (searchString == "*") {
      throw FilterException("* is not a valid search term");
    }

    var idSet = <NitriteId>{};
    var term = searchString.substring(1);

    await for (var entry in indexMap.entries()) {
      var key = entry.first;
      if (key.endsWith(term.toLowerCase())) {
        idSet.addAll(entry.second as List<NitriteId>);
      }
    }

    return Future.value(idSet);
  }

  Future<Set<NitriteId>> _searchByTrailingWildCard(
      NitriteMap<String, List> indexMap, String searchString) async {
    if (searchString == "*") {
      throw FilterException("* is not a valid search term");
    }

    var idSet = <NitriteId>{};
    var term = searchString.substring(0, searchString.length - 1);

    await for (var entry in indexMap.entries()) {
      var key = entry.first;
      if (key.startsWith(term.toLowerCase())) {
        idSet.addAll(entry.second as List<NitriteId>);
      }
    }

    return Future.value(idSet);
  }

  Future<Set<NitriteId>> _searchContains(
      NitriteMap<String, List> indexMap, String term) async {
    var idSet = <NitriteId>{};
    await for (var entry in indexMap.entries()) {
      var key = entry.first;
      if (key.contains(term.toLowerCase())) {
        idSet.addAll(entry.second as List<NitriteId>);
      }
    }

    return Future.value(idSet);
  }

  Set<NitriteId> _sortedIdsByScore(Map<NitriteId, int> unsortedMap) {
    var sortedKeys = unsortedMap.keys.toList(growable: false)
      ..sort((a, b) {
        var score1 = unsortedMap[a]!;
        var score2 = unsortedMap[b]!;
        return score1.compareTo(score2);
      });
    var sortedMap = LinkedHashMap<NitriteId, int>.fromIterable(sortedKeys,
        key: (k) => k, value: (k) => unsortedMap[k]!);

    return sortedMap.keys.toSet();
  }
}

class _BetweenFilter<T> extends AndFilter {
  _BetweenFilter(String field, _Bound<T> bound)
      : super(<Filter>[_rhs(field, bound), _lhs(field, bound)]);

  static Filter _rhs<R>(String field, _Bound<R> bound) {
    _validateBound(bound);
    R value = bound.upperBound;
    if (bound.upperInclusive) {
      return _LesserEqualFilter(field, value as Comparable);
    } else {
      return _LesserThanFilter(field, value as Comparable);
    }
  }

  static Filter _lhs<R>(String field, _Bound<R> bound) {
    _validateBound(bound);
    R value = bound.upperBound;
    if (bound.lowerInclusive) {
      return _GreaterEqualFilter(field, value as Comparable);
    } else {
      return _GreaterThanFilter(field, value as Comparable);
    }
  }

  static void _validateBound<R>(_Bound<R> bound) {
    if (bound.upperBound is! Comparable || bound.lowerBound is! Comparable) {
      throw FilterException("Upper bound or lower bound value "
          "must be comparable");
    }
  }
}

class _Bound<T> {
  T upperBound;
  T lowerBound;
  bool upperInclusive = true;
  bool lowerInclusive = true;

  _Bound(this.upperBound, this.lowerBound,
      {this.upperInclusive = true, this.lowerInclusive = true});
}

class _GreaterEqualFilter extends ComparableFilter {
  _GreaterEqualFilter(String field, dynamic value) : super(field, value);

  @override
  bool apply(Document doc) {
    var fieldValue = doc.get(field);
    if (fieldValue != null) {
      if (fieldValue is num && comparable is num) {
        return compare(fieldValue, comparable as num) >= 0;
      } else if (fieldValue is Comparable) {
        return fieldValue.compareTo(comparable) >= 0;
      } else {
        throw FilterException("$fieldValue is not comparable");
      }
    }
    return false;
  }

  @override
  List applyOnIndex(IndexMap indexMap) {
    var subMaps = <SplayTreeMap<Comparable, dynamic>>[];

    // maintain the find sorting order
    var nitriteIds = <NitriteId>[];
    var ceilingKey = indexMap.ceilingKey(comparable);
    while (ceilingKey != null) {
      // get the starting value, it can be a navigable-map (compound index)
      // or list (single field index)
      var val = indexMap.get(ceilingKey);
      processIndexValue(val, subMaps, nitriteIds);
      ceilingKey = indexMap.higherKey(comparable);
    }

    if (subMaps.isNotEmpty) {
      // if sub-map is populated then filtering on compound index, return sub-map
      return subMaps;
    } else {
      // else it is filtering on either single field index,
      // or it is a terminal filter on compound index, return only nitrite-ids
      return nitriteIds;
    }
  }

  @override
  toString() => "($field >= $value)";
}

class _GreaterThanFilter extends ComparableFilter {
  _GreaterThanFilter(String field, dynamic value) : super(field, value);

  @override
  bool apply(Document doc) {
    var fieldValue = doc.get(field);
    if (fieldValue != null) {
      if (fieldValue is num && comparable is num) {
        return compare(fieldValue, comparable as num) > 0;
      } else if (fieldValue is Comparable) {
        return fieldValue.compareTo(comparable) > 0;
      } else {
        throw FilterException("$fieldValue is not comparable");
      }
    }
    return false;
  }

  @override
  List applyOnIndex(IndexMap indexMap) {
    var subMaps = <SplayTreeMap<Comparable, dynamic>>[];

    // maintain the find sorting order
    var nitriteIds = <NitriteId>[];
    var ceilingKey = indexMap.higherKey(comparable);
    while (ceilingKey != null) {
      // get the starting value, it can be a navigable-map (compound index)
      // or list (single field index)
      var val = indexMap.get(ceilingKey);
      processIndexValue(val, subMaps, nitriteIds);
      ceilingKey = indexMap.higherKey(comparable);
    }

    if (subMaps.isNotEmpty) {
      // if sub-map is populated then filtering on compound index, return sub-map
      return subMaps;
    } else {
      // else it is filtering on either single field index,
      // or it is a terminal filter on compound index, return only nitrite-ids
      return nitriteIds;
    }
  }

  @override
  toString() => "($field > $value)";
}

class _LesserEqualFilter extends ComparableFilter {
  _LesserEqualFilter(String field, dynamic value) : super(field, value);

  @override
  bool apply(Document doc) {
    var fieldValue = doc.get(field);
    if (fieldValue != null) {
      if (fieldValue is num && comparable is num) {
        return compare(fieldValue, comparable as num) <= 0;
      } else if (fieldValue is Comparable) {
        return fieldValue.compareTo(comparable) <= 0;
      } else {
        throw FilterException("$fieldValue is not comparable");
      }
    }
    return false;
  }

  @override
  List applyOnIndex(IndexMap indexMap) {
    var subMaps = <SplayTreeMap<Comparable, dynamic>>[];

    // maintain the find sorting order
    var nitriteIds = <NitriteId>[];
    var floorKey = indexMap.floorKey(comparable);
    while (floorKey != null) {
      // get the starting value, it can be a navigable-map (compound index)
      // or list (single field index)
      var val = indexMap.get(floorKey);
      processIndexValue(val, subMaps, nitriteIds);
      floorKey = indexMap.lowerKey(comparable);
    }

    if (subMaps.isNotEmpty) {
      // if sub-map is populated then filtering on compound index, return sub-map
      return subMaps;
    } else {
      // else it is filtering on either single field index,
      // or it is a terminal filter on compound index, return only nitrite-ids
      return nitriteIds;
    }
  }

  @override
  toString() => "($field <= $value)";
}

class _LesserThanFilter extends ComparableFilter {
  _LesserThanFilter(String field, dynamic value) : super(field, value);

  @override
  bool apply(Document doc) {
    var fieldValue = doc.get(field);
    if (fieldValue != null) {
      if (fieldValue is num && comparable is num) {
        return compare(fieldValue, comparable as num) < 0;
      } else if (fieldValue is Comparable) {
        return fieldValue.compareTo(comparable) < 0;
      } else {
        throw FilterException("$fieldValue is not comparable");
      }
    }
    return false;
  }

  @override
  List applyOnIndex(IndexMap indexMap) {
    var subMaps = <SplayTreeMap<Comparable, dynamic>>[];

    // maintain the find sorting order
    var nitriteIds = <NitriteId>[];
    var floorKey = indexMap.lowerKey(comparable);
    while (floorKey != null) {
      // get the starting value, it can be a navigable-map (compound index)
      // or list (single field index)
      var val = indexMap.get(floorKey);
      processIndexValue(val, subMaps, nitriteIds);
      floorKey = indexMap.lowerKey(comparable);
    }

    if (subMaps.isNotEmpty) {
      // if sub-map is populated then filtering on compound index, return sub-map
      return subMaps;
    } else {
      // else it is filtering on either single field index,
      // or it is a terminal filter on compound index, return only nitrite-ids
      return nitriteIds;
    }
  }

  @override
  toString() => "($field < $value)";
}

class _NotEqualsFilter extends ComparableFilter {
  _NotEqualsFilter(String field, dynamic value) : super(field, value);

  @override
  bool apply(Document doc) {
    var fieldValue = doc.get(field);
    return !deepEquals(fieldValue, value);
  }

  @override
  List applyOnIndex(IndexMap indexMap) {
    var subMaps = <SplayTreeMap<Comparable, dynamic>>[];

    // maintain the find sorting order
    var nitriteIds = <NitriteId>[];

    for (Pair<Comparable, dynamic> entry in indexMap.entries()) {
      if (!deepEquals(value, entry.first)) {
        processIndexValue(entry.second, subMaps, nitriteIds);
      }
    }

    if (subMaps.isNotEmpty) {
      // if sub-map is populated then filtering on compound index, return sub-map
      return subMaps;
    } else {
      // else it is filtering on either single field index,
      // or it is a terminal filter on compound index, return only nitrite-ids
      return nitriteIds;
    }
  }

  @override
  toString() => "($field != $value)";
}

class _RegexFilter extends FieldBasedFilter {
  final RegExp _pattern;

  _RegexFilter(String field, String value)
      : _pattern = RegExp(value),
        super(field, value);

  @override
  bool apply(Document doc) {
    var fieldValue = doc.get(field);

    if (fieldValue is! String) {
      throw FilterException("Regex filter can not be applied on "
          "non string field $field");
    }

    return _pattern.hasMatch(fieldValue);
  }
}

class _InFilter extends ComparableArrayFilter {
  final List<Comparable> _comparableSet = [];

  _InFilter(String field, List<Comparable> values) : super(field, values) {
    _comparableSet.addAll(values);
  }

  @override
  bool apply(Document doc) {
    var fieldValue = doc.get(field);

    if (fieldValue is Comparable) {
      return _comparableSet.contains(comparable);
    }
    return false;
  }

  @override
  List applyOnIndex(IndexMap indexMap) {
    var subMaps = <SplayTreeMap<Comparable, dynamic>>[];

    // maintain the find sorting order
    var nitriteIds = <NitriteId>[];
    for (Pair<Comparable, dynamic> entry in indexMap.entries()) {
      if (_comparableSet.contains(entry.first)) {
        processIndexValue(entry.second, subMaps, nitriteIds);
      }
    }

    if (subMaps.isNotEmpty) {
      // if sub-map is populated then filtering on compound index, return sub-map
      return subMaps;
    } else {
      // else it is filtering on either single field index,
      // or it is a terminal filter on compound index, return only nitrite-ids
      return nitriteIds;
    }
  }

  @override
  toString() => "($field in $value)";
}

class _NotInFilter extends ComparableArrayFilter {
  final List<Comparable> _comparableSet = [];

  _NotInFilter(String field, List<Comparable> values) : super(field, values) {
    _comparableSet.addAll(values);
  }

  @override
  bool apply(Document doc) {
    var fieldValue = doc.get(field);

    if (fieldValue is Comparable) {
      return !_comparableSet.contains(comparable);
    }
    return false;
  }

  @override
  List applyOnIndex(IndexMap indexMap) {
    var subMaps = <SplayTreeMap<Comparable, dynamic>>[];

    // maintain the find sorting order
    var nitriteIds = <NitriteId>[];
    for (Pair<Comparable, dynamic> entry in indexMap.entries()) {
      if (!_comparableSet.contains(entry.first)) {
        processIndexValue(entry.second, subMaps, nitriteIds);
      }
    }

    if (subMaps.isNotEmpty) {
      // if sub-map is populated then filtering on compound index, return sub-map
      return subMaps;
    } else {
      // else it is filtering on either single field index,
      // or it is a terminal filter on compound index, return only nitrite-ids
      return nitriteIds;
    }
  }

  @override
  toString() => "($field not in $value)";
}

class _NotFilter extends NitriteFilter {
  final Filter _filter;

  _NotFilter(this._filter);

  @override
  bool apply(Document element) {
    return !_filter.apply(element);
  }

  @override
  String toString() => "!(${_filter.toString()})";
}

class _ElementMatchFilter extends NitriteFilter {
  final String _field;
  final Filter _elementFilter;

  _ElementMatchFilter(this._field, this._elementFilter);

  @override
  bool apply(Document doc) {
    if (_elementFilter is _ElementMatchFilter) {
      throw FilterException("Nested elemMatch filter is not supported");
    }

    if (_elementFilter is TextFilter) {
      throw FilterException("Text filter is not supported in elemMatch filter");
    }

    var fieldValue = doc.get(_field);
    if (fieldValue == null) return false;

    if (fieldValue is Iterable) {
      return _matches(fieldValue, _elementFilter);
    } else {
      throw FilterException("elemMatch filter only applies to iterables");
    }
  }

  @override
  String toString() => "elemMatch($_field : $_elementFilter)";

  bool _matches(Iterable iterable, Filter filter) {
    for (var element in iterable) {
      if (_matchElement(element, filter)) {
        return true;
      }
    }
    return false;
  }

  bool _matchElement(dynamic element, Filter filter) {
    if (filter is AndFilter) {
      var filters = filter.filters;
      for (var subFilter in filters) {
        if (!_matchElement(element, subFilter)) {
          return false;
        }
      }
      return true;
    } else if (filter is OrFilter) {
      var filters = filter.filters;
      for (var subFilter in filters) {
        if (_matchElement(element, subFilter)) {
          return true;
        }
      }
      return false;
    } else if (filter is _NotFilter) {
      var not = filter._filter;
      return !_matchElement(element, not);
    } else if (filter is EqualsFilter) {
      return _matchEquals(element, filter);
    } else if (filter is _GreaterEqualFilter) {
      return _matchGreaterEqual(element, filter);
    } else if (filter is _GreaterThanFilter) {
      return _matchGreater(element, filter);
    } else if (filter is _LesserEqualFilter) {
      return _matchLesserEqual(element, filter);
    } else if (filter is _LesserThanFilter) {
      return _matchLesser(element, filter);
    } else if (filter is _InFilter) {
      return _matchIn(element, filter);
    } else if (filter is _NotInFilter) {
      return _matchNotIn(element, filter);
    } else if (filter is _RegexFilter) {
      return _matchRegex(element, filter);
    } else {
      throw FilterException("Unsupported filter type in elemMatch: "
          "${filter.runtimeType}");
    }
  }

  bool _matchEquals(dynamic element, EqualsFilter filter) {
    var value = filter.value;
    if (element is Document) {
      var docValue = element[filter.field];
      return deepEquals(value, docValue);
    } else {
      return deepEquals(value, element);
    }
  }

  bool _matchGreater(dynamic element, _GreaterThanFilter filter) {
    var comparable = filter.comparable;

    if (element is num && comparable is num) {
      return compare(element, comparable) > 0;
    } else if (element is Comparable) {
      return element.compareTo(comparable) > 0;
    } else if (element is Document) {
      var docValue = element[filter.field];
      if (docValue is Comparable) {
        return docValue.compareTo(comparable) > 0;
      } else {
        throw FilterException("${filter.field} is not comparable");
      }
    } else {
      throw FilterException("$element is not comparable");
    }
  }

  bool _matchGreaterEqual(dynamic element, _GreaterEqualFilter filter) {
    var comparable = filter.comparable;

    if (element is num && comparable is num) {
      return compare(element, comparable) >= 0;
    } else if (element is Comparable) {
      return element.compareTo(comparable) >= 0;
    } else if (element is Document) {
      var docValue = element[filter.field];
      if (docValue is Comparable) {
        return docValue.compareTo(comparable) >= 0;
      } else {
        throw FilterException("${filter.field} is not comparable");
      }
    } else {
      throw FilterException("$element is not comparable");
    }
  }

  bool _matchLesserEqual(dynamic element, _LesserEqualFilter filter) {
    var comparable = filter.comparable;

    if (element is num && comparable is num) {
      return compare(element, comparable) <= 0;
    } else if (element is Comparable) {
      return element.compareTo(comparable) <= 0;
    } else if (element is Document) {
      var docValue = element[filter.field];
      if (docValue is Comparable) {
        return docValue.compareTo(comparable) <= 0;
      } else {
        throw FilterException("${filter.field} is not comparable");
      }
    } else {
      throw FilterException("$element is not comparable");
    }
  }

  bool _matchLesser(dynamic element, _LesserThanFilter filter) {
    var comparable = filter.comparable;

    if (element is num && comparable is num) {
      return compare(element, comparable) < 0;
    } else if (element is Comparable) {
      return element.compareTo(comparable) < 0;
    } else if (element is Document) {
      var docValue = element[filter.field];
      if (docValue is Comparable) {
        return docValue.compareTo(comparable) < 0;
      } else {
        throw FilterException("${filter.field} is not comparable");
      }
    } else {
      throw FilterException("$element is not comparable");
    }
  }

  bool _matchIn(dynamic element, _InFilter filter) {
    var values = filter._comparableSet;
    if (element is Document) {
      var docValue = element[filter.field];
      if (docValue is Comparable) {
        return values.contains(docValue);
      }
    } else if (element is Comparable) {
      return values.contains(element);
    }
    return false;
  }

  bool _matchNotIn(dynamic element, _NotInFilter filter) {
    var values = filter._comparableSet;
    if (element is Document) {
      var docValue = element[filter.field];
      if (docValue is Comparable) {
        return !values.contains(docValue);
      }
    } else if (element is Comparable) {
      return !values.contains(element);
    }
    return false;
  }

  bool _matchRegex(dynamic element, _RegexFilter filter) {
    var value = filter.value;
    if (element is String) {
      var regExp = RegExp(value);
      return regExp.hasMatch(element);
    } else if (element is Document) {
      var docValue = element[filter.field];
      if (docValue is String) {
        var regExp = RegExp(value);
        return regExp.hasMatch(docValue);
      } else {
        throw FilterException("${filter.field} is not a string");
      }
    } else {
      throw FilterException("$element is not a string");
    }
  }
}
