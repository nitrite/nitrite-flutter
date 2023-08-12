import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/index/index_map.dart';

part 'filter_impl.dart';

/// The where clause for elemMatch filter.
FluentFilter $ = where("\$");

/// A filter to select all elements.
final Filter all = _All();

/// Where clause for fluent filter api.
FluentFilter where(String field) {
  var filter = FluentFilter._();
  filter._field = field;
  return filter;
}

/// Filter by document _id.
Filter byId(NitriteId id) => EqualsFilter(docId, id.idValue);

Filter createUniqueFilter(Document document) {
  return byId(document.id);
}

/// Performs logical AND on the given filters.
Filter and(List<Filter> filters) {
  filters.notNullOrEmpty('At least two filters must be specified');
  if (filters.length < 2) {
    throw FilterException('At least two filters must be specified');
  }

  return AndFilter(filters);
}

/// Performs logical OR on the given filters.
Filter or(List<Filter> filters) {
  filters.notNullOrEmpty('At least two filters must be specified');
  if (filters.length < 2) {
    throw FilterException('At least two filters must be specified');
  }

  return OrFilter(filters);
}

// private forward declaration
Filter _and(List<Filter> filters) => and(filters);
Filter _or(List<Filter> filters) => or(filters);

/// A fluent api for the [NitriteFilter].
class FluentFilter {
  late String _field;

  FluentFilter._();

  /// Creates an equality filter which matches documents where the value
  /// of a field equals the specified value.
  NitriteFilter eq(dynamic value) => EqualsFilter(_field, value);

  /// Creates an equality filter which matches documents where the value
  /// of a field not equals the specified value.
  NitriteFilter notEq(dynamic value) => _NotEqualsFilter(_field, value);

  /// Creates a greater than filter which matches those documents where the value
  /// of the field is greater than the specified value.
  NitriteFilter gt(dynamic value) => _GreaterThanFilter(_field, value);

  /// Creates a greater equal filter which matches those documents where the value
  /// of the field is greater than or equals to the specified value.
  NitriteFilter gte(dynamic value) => _GreaterEqualFilter(_field, value);

  /// Creates a lesser than filter which matches those documents where the value
  /// of the field is less than the specified value.
  NitriteFilter lt(dynamic value) => _LesserThanFilter(_field, value);

  /// Creates a lesser equal filter which matches those documents where the value
  /// of the field is less than or equals to the specified value.
  NitriteFilter lte(dynamic value) => _LesserEqualFilter(_field, value);

  /// Creates a between filter which matches those documents where the value
  /// of the field is within the specified bound including the end values.
  ///
  /// ```dart
  /// collection.find(where("age").between(30, 40));
  /// ```
  NitriteFilter between(Comparable lowerBound, Comparable upperBound,
          {upperInclusive = true, lowerInclusive = true}) =>
      _BetweenFilter(
          _field,
          _Bound(upperBound, lowerBound,
              upperInclusive: upperInclusive, lowerInclusive: lowerInclusive));

  /// Creates a text filter which performs a text search on the content of
  /// the fields indexed with a full-text index.
  NitriteFilter text(String value) => TextFilter(_field, value);

  /// Creates a string filter which provides regular expression capabilities
  /// for pattern matching strings in documents.
  NitriteFilter regex(String value) => _RegexFilter(_field, value);

  /// Creates an in filter which matches the documents where
  /// the value of a field equals any value in the specified values.
  NitriteFilter within(List<Comparable> value) => _InFilter(_field, value);

  /// Creates a notIn filter which matches the documents where
  /// the value of a field not equals any value in the specified values.
  NitriteFilter notIn(List<Comparable> value) => _NotInFilter(_field, value);

  /// Creates an element match filter that matches documents that contain a list
  /// value with at least one element that matches the specified filter.
  NitriteFilter elemMatch(Filter filter) => _ElementMatchFilter(_field, filter);

  /// Creates a greater than filter which matches those documents where the value
  /// of the field is greater than the specified value.
  NitriteFilter operator >(dynamic value) => _GreaterThanFilter(_field, value);

  /// Creates a greater equal filter which matches those documents where the value
  /// of the field is greater than or equals to the specified value.
  NitriteFilter operator >=(dynamic value) =>
      _GreaterEqualFilter(_field, value);

  /// Creates a lesser than filter which matches those documents where the value
  /// of the field is less than the specified value.
  NitriteFilter operator <(dynamic value) => _LesserThanFilter(_field, value);

  /// Creates a lesser equal filter which matches those documents where the value
  /// of the field is less than or equals to the specified value.
  NitriteFilter operator <=(dynamic value) => _LesserEqualFilter(_field, value);
}

/// An interface to specify filtering criteria during find operation. When
/// a filter is applied to a collection, based on the criteria it returns
/// a set of matching records.
///
/// Each filtering criteria is based on a value of a document. If the value
/// is indexed, the find operation takes the advantage of it and only scans
/// the index map for that value. But if the value is not indexed, it scans
/// the whole collection.
abstract class Filter {
  /// Filters a document map and returns `true` if the criteria matches.
  bool apply(Document doc);

  /// Creates a not filter which performs a logical NOT operation on a filter
  /// and selects the documents that **do not** satisfy the criteria.
  /// This also includes documents that do not contain the value.
  Filter operator ~() {
    return _NotFilter(this);
  }

  /// Creates a not filter which performs a logical NOT operation on a filter
  /// and selects the documents that **do not** satisfy the criteria.
  /// This also includes documents that do not contain the value.
  Filter not() {
    return _NotFilter(this);
  }
}

/// Represents a nitrite filter.
abstract class NitriteFilter extends Filter {
  NitriteConfig? nitriteConfig;
  String? collectionName;
  bool objectFilter = false;

  /// Creates an and filter which performs a logical AND operation on
  /// two filters and selects the documents that satisfy both filters.
  Filter and(Filter filter) {
    return this & filter;
  }

  /// Creates an or filter which performs a logical OR operation on
  /// two filters and selects the documents that satisfy at least one
  /// of the filter.
  Filter or(Filter filter) {
    return this | filter;
  }

  /// Creates an and filter which performs a logical AND operation on
  /// two filters and selects the documents that satisfy both filters.
  Filter operator &(Filter other) {
    return _and([this, other]);
  }

  /// Creates an or filter which performs a logical OR operation on
  /// two filters and selects the documents that satisfy at least one
  /// of the filter.
  Filter operator |(Filter other) {
    return _or([this, other]);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NitriteFilter &&
          runtimeType == other.runtimeType &&
          toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;
}

class _All extends Filter {
  _All();

  @override
  bool apply(Document element) {
    return true;
  }

  @override
  String toString() {
    return 'ALL';
  }
}

/// Represents a filter which does a logical operation (AND, OR)
/// between a set of filters.
abstract class LogicalFilter extends NitriteFilter {
  List<Filter> filters;

  LogicalFilter(this.filters);
}

/// Represents a filter based on value of a nitrite document field.
abstract class FieldBasedFilter extends NitriteFilter {
  String field;
  dynamic _value;
  bool _processed = false;

  FieldBasedFilter(this.field, this._value);

  /// Gets the value of the filter.
  dynamic get value {
    if (_processed) return _value;
    if (_value == null) return null;

    if (objectFilter && nitriteConfig != null) {
      var mapper = nitriteConfig!.nitriteMapper;
      validateSearchTerm(mapper, field, _value);
      if (_value is Comparable && _value is! DBNull) {
        _value = mapper.tryConvert<dynamic, Comparable>(_value);
      }
    }

    _processed = true;
    return _value;
  }

  void validateSearchTerm(
      NitriteMapper nitriteMapper, String field, dynamic value) {
    field.notNullOrEmpty("field cannot be empty");
  }
}

/// Represents a filter based on document field holding [Comparable] values.
abstract class ComparableFilter extends FieldBasedFilter {
  ComparableFilter(String field, dynamic value) : super(field, value);

  Comparable get comparable {
    if (value == null) {
      throw FilterException("The value for field '$field' must not be null");
    }
    return value as Comparable;
  }

  /// Apply this filter on a nitrite index.
  Stream<dynamic> applyOnIndex(IndexMap indexMap);

  /// Yield values after index scanning.
  Stream<dynamic> yieldValues(dynamic value) async* {
    if (value is List) {
      // if it is a list then it is filtering on either single field index,
      // or it is a terminal filter on compound index, emit the nitrite-ids
      yield* Stream.fromIterable(value);
    } else if (value is Map) {
      // if it is a map then filtering on compound index, emit sub-map
      yield value;
    }
  }
}

/// Represents a filter on string values.
abstract class StringFilter extends ComparableFilter {
  StringFilter(String field, dynamic value) : super(field, value);

  String get stringValue => value as String;
}

/// Represents an index-only filter. This filter does not support
/// collection scan.
abstract class IndexOnlyFilter extends ComparableFilter {
  IndexOnlyFilter(super.field, super.value);

  /// Gets the supported index type for this filter.
  String supportedIndexType();

  /// Checks if `other` filter can be grouped together with this filter.
  bool canBeGrouped(IndexOnlyFilter other);
}

abstract class ComparableArrayFilter extends ComparableFilter {
  ComparableArrayFilter(super.field, super.value);

  @override
  validateSearchTerm(NitriteMapper nitriteMapper, String field, dynamic value) {
    field.notNullOrEmpty("Field cannot be empty");
    if (value is Iterable) {
      _validateFilterIterableField(value, field);
    }
  }

  void _validateFilterIterableField(Iterable value, String field) {
    for (var item in value) {
      if (item == null) continue;

      if (item is Iterable) {
        throw InvalidOperationException("Nested iterables are not supported");
      }

      if (item is! Comparable) {
        throw InvalidOperationException(
            "Each value for the iterable field '$field' must be comparable");
      }
    }
  }
}
