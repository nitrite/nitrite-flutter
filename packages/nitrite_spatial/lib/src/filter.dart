import 'package:dart_jts/dart_jts.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_spatial/src/indexer.dart';

/// The abstract base class for all spatial filters in Nitrite.
///
/// A spatial filter is used to query Nitrite database for
/// documents that have a specific spatial relationship with a given geometry.
/// It extends [IndexOnlyFilter] because it can only be applied on an index.
abstract class SpatialFilter extends IndexOnlyFilter {
  final Geometry _geometry;

  SpatialFilter(super.field, Geometry super.value) : _geometry = value;

  @override
  Geometry get value => _geometry;

  @override
  bool apply(Document doc) {
    return false;
  }

  @override
  String supportedIndexType() {
    return spatialIndex;
  }

  @override
  bool canBeGrouped(IndexOnlyFilter other) {
    return other is SpatialFilter && other.field == field;
  }
}

///@nodoc
class WithinFilter extends SpatialFilter {
  WithinFilter(super.field, super.value);

  @override
  Stream<dynamic> applyOnIndex(IndexMap indexMap) {
    // calculated from SpatialIndex
    return const Stream.empty();
  }

  @override
  String toString() {
    return '($field within $value)';
  }
}

///@nodoc
class IntersectsFilter extends SpatialFilter {
  IntersectsFilter(super.field, super.value);

  @override
  Stream<dynamic> applyOnIndex(IndexMap indexMap) {
    // calculated from SpatialIndex
    return const Stream.empty();
  }

  @override
  String toString() {
    return '($field intersects $value)';
  }
}

///@nodoc
class NearFilter extends WithinFilter {
  factory NearFilter(String field, Coordinate center, double radius) {
    var geometry = _createCircle(center, radius);
    return NearFilter._(field, geometry);
  }

  factory NearFilter.fromPoint(String field, Point point, double radius) {
    return NearFilter._(field, _createCircle(point.getCoordinate(), radius));
  }

  NearFilter._(super.field, super.geometry);
}

Geometry _createCircle(Coordinate? center, double radius) {
  var factory = GeometryFactory.defaultPrecision();
  var point = factory.createPoint(center);
  return point.buffer(radius);
}

/// A fluent API for creating spatial filters.
///
/// Example:
/// ```dart
/// var filter = where('location').intersects(geometry);
/// ```
class SpatialFluentFilter {
  final String _field;

  SpatialFluentFilter(this._field);

  /// Creates a filter that matches documents whose field intersects the given [geometry].
  ///
  /// Example:
  /// ```dart
  /// var filter = where('location').intersects(geometry);
  /// ```
  Filter intersects(Geometry geometry) {
    return IntersectsFilter(_field, geometry);
  }

  /// Creates a filter that matches documents whose field is within the given [geometry].
  ///
  /// Example:
  /// ```dart
  /// var filter = where('location').within(geometry);
  /// ```
  Filter within(Geometry geometry) {
    return WithinFilter(_field, geometry);
  }

  /// Creates a filter that matches documents whose field is near the given [center] within the given [radius].
  ///
  /// Example:
  /// ```dart
  /// var filter = where('location').near(center, radius);
  /// ```
  Filter near(Center center, double radius) {
    return switch (center) {
      CenterCoordinate() => NearFilter(_field, center.coordinate, radius),
      CenterPoint() => NearFilter.fromPoint(_field, center.point, radius),
    };
  }
}

/// Creates a fluent API for creating spatial filters.
SpatialFluentFilter where(String field) {
  return SpatialFluentFilter(field);
}

/// A center point or coordinate.
///
/// Used for creating a [NearFilter].
sealed class Center {
  /// Creates a center point.
  const Center();

  /// Creates a center point from the given [point].
  factory Center.fromPoint(Point point) {
    return CenterPoint(point);
  }

  /// Creates a center point from the given [coordinate].
  factory Center.fromCoordinate(Coordinate coordinate) {
    return CenterCoordinate(coordinate);
  }
}

///@nodoc
class CenterPoint extends Center {
  final Point point;

  CenterPoint(this.point);
}

///@nodoc
class CenterCoordinate extends Center {
  final Coordinate coordinate;

  CenterCoordinate(this.coordinate);
}
