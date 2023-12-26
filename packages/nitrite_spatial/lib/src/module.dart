import 'package:nitrite/nitrite.dart';
import 'package:nitrite_spatial/nitrite_spatial.dart';
import 'package:nitrite_spatial/src/indexer.dart';

/// A module that provides spatial indexing capability to Nitrite.
/// This module provides a spatial index on a single field of a document.
class SpatialModule extends NitriteModule {
  @override
  Set<NitritePlugin> get plugins => {SpatialIndexer(), GeometryConverter()};
}
