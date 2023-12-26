import 'package:nitrite/nitrite.dart';
import 'package:nitrite_spatial/src/spatial_index.dart';

/// Spatial index type.
const String spatialIndex = "Spatial";

/// @nodoc
class SpatialIndexer extends NitriteIndexer {
  final Map<IndexDescriptor, SpatialIndex> _indexRegistry = {};

  @override
  Future<void> dropIndex(
      IndexDescriptor indexDescriptor, NitriteConfig nitriteConfig) {
    var spatialIndex = _findSpatialIndex(indexDescriptor, nitriteConfig);
    return spatialIndex.drop();
  }

  @override
  Stream<NitriteId> findByFilter(
      FindPlan findPlan, NitriteConfig nitriteConfig) {
    if (findPlan.indexDescriptor == null) {
      throw IndexingException('Spatial index not found');
    }
    var spatialIndex =
        _findSpatialIndex(findPlan.indexDescriptor!, nitriteConfig);
    return spatialIndex.findNitriteIds(findPlan);
  }

  @override
  String get indexType => spatialIndex;

  @override
  Future<void> initialize(NitriteConfig nitriteConfig) async {}

  @override
  Future<void> removeIndexEntry(FieldValues fieldValues,
      IndexDescriptor indexDescriptor, NitriteConfig nitriteConfig) {
    var spatialIndex = _findSpatialIndex(indexDescriptor, nitriteConfig);
    return spatialIndex.remove(fieldValues);
  }

  @override
  Future<void> validateIndex(Fields fields) async {
    if (fields.fieldNames.length > 1) {
      throw IndexingException(
          'Spatial index can only be created on a single field');
    }
  }

  @override
  Future<void> writeIndexEntry(FieldValues fieldValues,
      IndexDescriptor indexDescriptor, NitriteConfig nitriteConfig) {
    var spatialIndex = _findSpatialIndex(indexDescriptor, nitriteConfig);
    return spatialIndex.write(fieldValues);
  }

  SpatialIndex _findSpatialIndex(
      IndexDescriptor indexDescriptor, NitriteConfig nitriteConfig) {
    var spatialIndex = _indexRegistry[indexDescriptor];
    if (spatialIndex == null) {
      spatialIndex =
          SpatialIndex(indexDescriptor, nitriteConfig.getNitriteStore());
      _indexRegistry[indexDescriptor] = spatialIndex;
    }

    return spatialIndex;
  }
}
