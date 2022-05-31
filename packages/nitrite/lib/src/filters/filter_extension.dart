import 'package:nitrite/src/filters/filter.dart';

/// String extension for nitrite filter.
extension StringFilterExtension on String {

  NitriteFilter eq(dynamic value) {
    return where(this).eq(value);
  }

  NitriteFilter notEq(dynamic value) {
    return where(this).notEq(value);
  }

  NitriteFilter gt(dynamic value) {
    return where(this).gt(value);
  }

  NitriteFilter gte(dynamic value) {
    return where(this).gte(value);
  }

  NitriteFilter lt(dynamic value) {
    return where(this).lt(value);
  }

  NitriteFilter lte(dynamic value) {
    return where(this).lte(value);
  }

  NitriteFilter between(Comparable lowerBound, Comparable upperBound,
      {upperInclusive = true, lowerInclusive = true}) {
    return where(this).between(lowerBound, upperBound,
        upperInclusive: upperInclusive, lowerInclusive: lowerInclusive);
  }

  NitriteFilter within(List<dynamic> values) {
    return where(this).within(values);
  }

  NitriteFilter notIn(List<dynamic> values) {
    return where(this).notIn(values);
  }

  NitriteFilter elemMatch(Filter filter) {
    return where(this).elemMatch(filter);
  }

  NitriteFilter text(String value) {
    return where(this).text(value);
  }

  NitriteFilter regex(String value) {
    return where(this).regex(value);
  }
}
