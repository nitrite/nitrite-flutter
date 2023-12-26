import 'package:dart_jts/dart_jts.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_spatial/src/filter.dart';
import 'package:nitrite_spatial/src/geom_utils.dart';

//@nodoc
class SpatialIndex extends NitriteIndex {
  final IndexDescriptor _indexDescriptor;
  final NitriteStore _nitriteStore;

  SpatialIndex(this._indexDescriptor, this._nitriteStore);

  @override
  Future<void> drop() async {
    var indexMap = await _findIndexMap();
    await indexMap.clear();
    await indexMap.drop();
  }

  @override
  Stream<NitriteId> findNitriteIds(FindPlan findPlan) async* {
    var indexScanFilter = findPlan.indexScanFilter;
    if (indexScanFilter == null || indexScanFilter.filters.isEmpty) {
      throw FilterException('No spatial filter found');
    }

    var filters = indexScanFilter.filters;
    var filter = filters.first;

    if (filter is! SpatialFilter) {
      throw FilterException(
          'Spatial filter must be the first filter for index scan');
    }

    var indexMap = await _findIndexMap();
    var geometry = filter.value;
    var boundingBox = _fromGeometry(geometry);

    Stream<NitriteId> keys;
    if (filter is WithinFilter) {
      keys = indexMap.findContainedKeys(boundingBox);
    } else if (filter is IntersectsFilter) {
      keys = indexMap.findIntersectingKeys(boundingBox);
    } else {
      throw FilterException('Unsupported spatial filter: $filter');
    }

    await for (var key in keys) {
      yield key;
    }
  }

  @override
  IndexDescriptor get indexDescriptor => _indexDescriptor;

  @override
  Future<void> remove(FieldValues fieldValues) async {
    var fields = fieldValues.fields;
    var fieldNames = fields.fieldNames;

    var firstField = fieldNames.first;
    var element = fieldValues.get(firstField);

    var indexMap = await _findIndexMap();
    if (element == null) {
      await indexMap.remove(BoundingBox.empty, fieldValues.nitriteId);
    } else {
      var geometry = _parseGeometry(firstField, element);
      if (geometry == null) {
        await indexMap.remove(BoundingBox.empty, fieldValues.nitriteId);
      } else {
        var boundingBox = _fromGeometry(geometry);
        await indexMap.remove(boundingBox, fieldValues.nitriteId);
      }
    }
  }

  @override
  Future<void> write(FieldValues fieldValues) async {
    var fields = fieldValues.fields;
    var fieldNames = fields.fieldNames;

    var firstField = fieldNames.first;
    var element = fieldValues.get(firstField);

    var indexMap = await _findIndexMap();
    if (element == null) {
      await indexMap.add(BoundingBox.empty, fieldValues.nitriteId);
    } else {
      var geometry = _parseGeometry(firstField, element);
      if (geometry == null) {
        await indexMap.add(BoundingBox.empty, fieldValues.nitriteId);
      } else {
        var boundingBox = _fromGeometry(geometry);
        await indexMap.add(boundingBox, fieldValues.nitriteId);
      }
    }
  }

  Future<NitriteRTree<BoundingBox, Geometry>> _findIndexMap() async {
    var mapName = deriveIndexMapName(_indexDescriptor);
    return _nitriteStore.openRTree<BoundingBox, Geometry>(mapName);
  }

  Geometry? _parseGeometry(String fieldName, Object? fieldValue) {
    if (fieldValue == null) {
      return null;
    }
    if (fieldValue is Geometry) {
      return fieldValue;
    }
    if (fieldValue is String) {
      return geometryFromString(fieldValue);
    }
    if (fieldValue is Document && fieldValue.containsField('geometry')) {
      // in case of document, check if it contains geometry field
      // GeometryConverter convert a geometry to document with geometry field
      var geometryString = fieldValue['geometry'] as String;
      return geometryFromString(geometryString);
    }
    throw IndexingException(
        'field $fieldName is not a valid geometry: $fieldValue');
  }

  BoundingBox _fromGeometry(Geometry geometry) {
    var envelope = geometry.getEnvelopeInternal();
    return BoundingBox(envelope.getMinX(), envelope.getMinY(),
        envelope.getMaxX(), envelope.getMaxY());
  }
}
