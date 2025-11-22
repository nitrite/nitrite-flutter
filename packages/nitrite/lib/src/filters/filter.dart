import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

part 'filter_impl.dart';

/// The where clause for elemMatch filter.
FluentFilter $ = where("\$");

/// A filter to select all elements.
final Filter all = _All();

/// Creates a new [FluentFilter] instance with the specified field name.
FluentFilter where(String field) {
  var filter = FluentFilter._();
  filter._field = field;
  return filter;
}

/// Returns a filter that matches documents with the specified NitriteId.
///
/// The returned filter matches documents where the value of the "docId" field
/// is equal to the specified NitriteId's idValue.
///
/// Example usage:
/// ```
/// var id = NitriteId.newId();
/// var filter = byId(id);
/// var result = collection.find(filter);
/// ```
Filter byId(NitriteId id) => EqualsFilter(docId, id.idValue);

/// @nodoc
Filter createUniqueFilter(Document document) {
  return byId(document.id);
}

/// Returns a filter that performs a logical AND operation on the provided filters.
/// The returned filter accepts a document if all filters in the list accept
/// the document.
Filter and(List<Filter> filters) {
  filters.notNullOrEmpty('At least two filters must be specified');
  if (filters.length < 2) {
    throw FilterException('At least two filters must be specified');
  }

  return AndFilter(filters);
}

/// Returns a filter that performs a logical OR operation on the provided list
/// of filters. The returned filter selects all documents that satisfy at least
/// one of the filters in the list.
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

  /// Returns a filter that matches documents where the value
  /// of the given field is equal to the specified value.
  NitriteFilter eq(dynamic value) => EqualsFilter(_field, value);

  /// Returns a filter that matches documents where the value of
  /// the field is not equal to the given [value].
  NitriteFilter notEq(dynamic value) => _NotEqualsFilter(_field, value);

  /// Returns a filter that matches documents where the value of the field is
  /// greater than the given value.
  NitriteFilter gt(dynamic value) => _GreaterThanFilter(_field, value);

  /// Returns a filter that matches documents where the value of the field
  /// is greater than or equal to the specified value.
  NitriteFilter gte(dynamic value) => _GreaterEqualFilter(_field, value);

  /// Returns a filter that matches documents where the value of the
  /// field is less than the given value.
  NitriteFilter lt(dynamic value) => _LesserThanFilter(_field, value);

  /// Returns a filter that matches documents where the value of the
  /// field is less than or equal to the specified value.
  NitriteFilter lte(dynamic value) => _LesserEqualFilter(_field, value);

  /// Returns a filter that matches documents where the value of a
  /// field is between the specified lower and upper bounds (inclusive).
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

  /// Returns a filter which performs a text search on the content of
  /// the field indexed with a full-text index.
  NitriteFilter text(String value) => TextFilter(_field, value);

  /// Creates a filter that matches documents where the value of the
  /// specified field matches the specified regular expression pattern.
  NitriteFilter regex(String value) => _RegexFilter(_field, value);

  /// Creates a filter that matches documents where the value of the field
  /// is in the specified array of values.
  NitriteFilter within(List<Comparable> value) => _InFilter(_field, value);

  /// Creates a filter that matches documents where the value of the field
  /// is not in the specified array of values.
  NitriteFilter notIn(List<Comparable> value) => _NotInFilter(_field, value);

  /// Creates a filter that matches documents where the value of a field
  /// contains at least one element that matches the specified filter.
  NitriteFilter elemMatch(Filter filter) => _ElementMatchFilter(_field, filter);

  /// Returns a filter that matches documents where the value of the field is
  /// greater than the given value.
  NitriteFilter operator >(dynamic value) => _GreaterThanFilter(_field, value);

  /// Returns a filter that matches documents where the value of the field
  /// is greater than or equal to the specified value.
  NitriteFilter operator >=(dynamic value) =>
      _GreaterEqualFilter(_field, value);

  /// Returns a filter that matches documents where the value of the
  /// field is less than the given value.
  NitriteFilter operator <(dynamic value) => _LesserThanFilter(_field, value);

  /// Returns a filter that matches documents where the value of the
  /// field is less than or equal to the specified value.
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
  /// Applies the filter to the given element.
  bool apply(Document doc);

  /// Creates a not filter which performs a logical NOT operation on a filter
  /// and selects the documents that **do not** satisfy the criteria.
  ///
  /// NOTE: This also includes documents that do not contain the value.
  Filter operator ~() {
    return _NotFilter(this);
  }

  /// Creates a not filter which performs a logical NOT operation on a filter
  /// and selects the documents that **do not** satisfy the criteria.
  ///
  /// NOTE: This also includes documents that do not contain the value.
  Filter not() {
    return _NotFilter(this);
  }
}

/// An abstract class representing a filter for Nitrite database.
abstract class NitriteFilter extends Filter {
  /// Gets the [NitriteConfig] instance.
  NitriteConfig? nitriteConfig;

  /// Gets the name of the collection on which this filter is applied.
  String? collectionName;

  /// Indicates if this filter is an object filter.
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

/// The base class for all field-based filters in Nitrite.
/// Provides common functionality for filters that operate on a specific field.
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

  /// Validates the search term for a given field and value.
  void validateSearchTerm(
      NitriteMapper nitriteMapper, String field, dynamic value) {
    field.notNullOrEmpty("field cannot be empty");
  }

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

/// An abstract class representing a filter that compares fields.
abstract class ComparableFilter extends FieldBasedFilter {
  ComparableFilter(super.field, super.value);

  Comparable get comparable {
    if (value == null) {
      throw FilterException("The value for field '$field' must not be null");
    }
    return value as Comparable;
  }

  /// Apply this filter on a nitrite index.
  Stream<dynamic> applyOnIndex(IndexMap indexMap);
}

abstract class SortingAwareFilter extends ComparableFilter {
  SortingAwareFilter(super.field, super.value);

  /// Indicates if the filter should scan the index in reverse order.
  bool isReverseScan = false;
}

/// An abstract class representing a filter for string values.
abstract class StringFilter extends ComparableFilter {
  StringFilter(super.field, super.value);

  String get stringValue => value as String;
}

/// An abstract class representing a filter that can be applied to an index.
///
/// NOTE: This filter does not support collection scan.
abstract class IndexOnlyFilter extends ComparableFilter {
  IndexOnlyFilter(super.field, super.value);

  /// Gets the supported index type for this filter.
  String supportedIndexType();

  /// Checks if `other` filter can be grouped together with this filter.
  bool canBeGrouped(IndexOnlyFilter other);

  /// Indicates whether this filter requires post-index validation.
  /// 
  /// Some index-only filters (like spatial filters) use the index for
  /// preliminary filtering but need a second pass to validate the actual
  /// condition. For example, R-Tree spatial indexes store only bounding boxes,
  /// so they may return false positives that need to be filtered out.
  /// 
  /// Returns `true` if this filter needs to be applied again after index scan
  /// to validate results. Defaults to `false`.
  bool needsPostIndexValidation() => false;
}

/// @nodoc
abstract class ComparableArrayFilter extends FieldBasedFilter {
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
