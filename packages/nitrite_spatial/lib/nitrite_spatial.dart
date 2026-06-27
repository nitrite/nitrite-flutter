///A library for using spatial data in Nitrite database.
library nitrite_spatial;

export 'src/converter.dart';
export 'src/filter.dart'
    show Center, GeoPoint, SpatialFilter, SpatialFluentFilter, where;
export 'src/filter.dart' show GeoNearFilter, KNearestFilter;
export 'src/geom_utils.dart' show GeometrySerializer, geometryEquals;
export 'src/geometry_adapter.dart';
export 'src/indexer.dart' show spatialIndex;
export 'src/module.dart';
