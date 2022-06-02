import 'package:nitrite/src/filters/filter.dart';

/// String extension for nitrite filter.
extension StringFilterExtension on String {

  /// Creates an equality filter which matches documents where the value
  /// of a field equals the specified value.
  NitriteFilter eq(dynamic value) {
    return where(this).eq(value);
  }

  /// Creates an equality filter which matches documents where the value
  /// of a field not equals the specified value.
  NitriteFilter notEq(dynamic value) {
    return where(this).notEq(value);
  }

  /// Creates a greater than filter which matches those documents where the value
  /// of the field is greater than the specified value.
  NitriteFilter gt(dynamic value) {
    return where(this).gt(value);
  }

  /// Creates a greater equal filter which matches those documents where the value
  /// of the field is greater than or equals to the specified value.
  NitriteFilter gte(dynamic value) {
    return where(this).gte(value);
  }

  /// Creates a lesser than filter which matches those documents where the value
  /// of the field is less than the specified value.
  NitriteFilter lt(dynamic value) {
    return where(this).lt(value);
  }

  /// Creates a lesser equal filter which matches those documents where the value
  /// of the field is less than or equals to the specified value.
  NitriteFilter lte(dynamic value) {
    return where(this).lte(value);
  }

  /// Creates a between filter which matches those documents where the value
  /// of the field is within the specified bound including the end values.
  ///
  /// ```dart
  /// collection.find(where("age").between(40, 30));
  /// ```
  NitriteFilter between(Comparable lowerBound, Comparable upperBound,
      {upperInclusive = true, lowerInclusive = true}) {
    return where(this).between(lowerBound, upperBound,
        upperInclusive: upperInclusive, lowerInclusive: lowerInclusive);
  }

  /// Creates an in filter which matches the documents where
  /// the value of a field equals any value in the specified values.
  NitriteFilter within(List<dynamic> values) {
    return where(this).within(values);
  }

  /// Creates a notIn filter which matches the documents where
  /// the value of a field not equals any value in the specified values.
  NitriteFilter notIn(List<dynamic> values) {
    return where(this).notIn(values);
  }

  /// Creates an element match filter that matches documents that contain a list
  /// value with at least one element that matches the specified filter.
  NitriteFilter elemMatch(Filter filter) {
    return where(this).elemMatch(filter);
  }

  /// Creates a text filter which performs a text search on the content of
  /// the fields indexed with a full-text index.
  NitriteFilter text(String value) {
    return where(this).text(value);
  }

  /// Creates a string filter which provides regular expression capabilities
  /// for pattern matching strings in documents.
  NitriteFilter regex(String value) {
    return where(this).regex(value);
  }
}
