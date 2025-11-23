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

/// A non-index filter that validates actual geometry relationships.
/// This filter is used as the second stage of spatial filtering after
/// the R-Tree index has filtered candidates based on bounding boxes.
class _GeometryValidationFilter extends FieldBasedFilter {
  final bool Function(Geometry, Geometry) _validator;

  _GeometryValidationFilter(super.field, super.value, this._validator);

  @override
  bool apply(Document doc) {
    var fieldValue = doc.get(field);
    if (fieldValue == null) {
      return false;
    }

    Geometry? documentGeometry;
    if (fieldValue is Geometry) {
      documentGeometry = fieldValue;
    } else if (fieldValue is String) {
      // Try to parse WKT string
      try {
        var reader = WKTReader();
        documentGeometry = reader.read(fieldValue);
      } catch (e) {
        return false;
      }
    } else {
      return false;
    }

    return _validator(documentGeometry!, value as Geometry);
  }
}

/// Internal implementation of WithinFilter for index scanning only.
/// Does not implement FlattenableFilter to avoid infinite recursion.
class WithinIndexFilter extends SpatialFilter {
  WithinIndexFilter(super.field, super.value);

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

/// Internal implementation of IntersectsFilter for index scanning only.
/// Does not implement FlattenableFilter to avoid infinite recursion.
class IntersectsIndexFilter extends SpatialFilter {
  IntersectsIndexFilter(super.field, super.value);

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
class WithinFilter extends Filter implements FlattenableFilter {
  final String field;
  final Geometry geometry;

  WithinFilter(this.field, this.geometry);

  @override
  bool apply(Document doc) {
    // This should not be called directly as the filter is flattened
    return false;
  }

  @override
  List<Filter> getFilters() {
    // Return two filters: one for index scan, one for validation
    return [
      WithinIndexFilter(field, geometry),
      _GeometryValidationFilter(
        field,
        geometry,
        (docGeom, filterGeom) => docGeom.within(filterGeom),
      ),
    ];
  }

  @override
  String toString() {
    return '($field within $geometry)';
  }
}

///@nodoc
class IntersectsFilter extends Filter implements FlattenableFilter {
  final String field;
  final Geometry geometry;

  IntersectsFilter(this.field, this.geometry);

  @override
  bool apply(Document doc) {
    // This should not be called directly as the filter is flattened
    return false;
  }

  @override
  List<Filter> getFilters() {
    // Return two filters: one for index scan, one for validation
    return [
      IntersectsIndexFilter(field, geometry),
      _GeometryValidationFilter(
        field,
        geometry,
        (docGeom, filterGeom) => docGeom.intersects(filterGeom),
      ),
    ];
  }

  @override
  String toString() {
    return '($field intersects $geometry)';
  }
}

///@nodoc
class NearFilter extends Filter implements FlattenableFilter {
  final String field;
  final Geometry circle;
  final Coordinate center;
  final double radius;

  factory NearFilter(String field, Coordinate center, double radius) {
    var circle = _createCircle(center, radius);
    return NearFilter._(field, circle, center, radius);
  }

  factory NearFilter.fromPoint(String field, Point point, double radius) {
    var center = point.getCoordinate();
    var circle = _createCircle(center, radius);
    return NearFilter._(field, circle, center!, radius);
  }

  NearFilter._(this.field, this.circle, this.center, this.radius);

  @override
  bool apply(Document doc) {
    // This should not be called directly as the filter is flattened
    return false;
  }

  @override
  List<Filter> getFilters() {
    // Return two filters: one for index scan (using within), one for distance validation
    return [
      WithinIndexFilter(field, circle),
      _NearValidationFilter(field, center, radius),
    ];
  }

  @override
  String toString() {
    return '($field near $center within $radius)';
  }
}

/// Validation filter for near queries that checks actual distance.
class _NearValidationFilter extends Filter {
  final String field;
  final Coordinate center;
  final double radius;

  _NearValidationFilter(this.field, this.center, this.radius);

  @override
  bool apply(Document doc) {
    var fieldValue = doc.get(field);
    if (fieldValue == null) {
      return false;
    }

    Geometry? documentGeometry;
    if (fieldValue is Geometry) {
      documentGeometry = fieldValue;
    } else if (fieldValue is String) {
      try {
        var reader = WKTReader();
        documentGeometry = reader.read(fieldValue);
      } catch (e) {
        return false;
      }
    } else {
      return false;
    }

    // For near queries, check if the geometry is within the distance
    // For points, check direct distance. For other geometries, check if they intersect the circle.
    if (documentGeometry is Point) {
      var coord = documentGeometry.getCoordinate();
      if (coord == null) return false;
      var distance = center.distance(coord);
      return distance <= radius;
    } else {
      // For non-point geometries, check if they intersect the circle
      var circle = _createCircle(center, radius);
      return documentGeometry!.intersects(circle);
    }
  }
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
