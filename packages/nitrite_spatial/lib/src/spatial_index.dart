import 'package:dart_jts/dart_jts.dart';
import 'package:nitrite/nitrite.dart';

class SpatialIndex implements NitriteIndex {
  IndexDescriptor _indexDescriptor;
  NitriteStore _nitriteStore;

  SpatialIndex(this._indexDescriptor, this._nitriteStore);

  @override
  List addNitriteIds(List? nitriteIds, FieldValues fieldValues) {
    // TODO: implement addNitriteIds
    throw UnimplementedError();
  }

  @override
  Future<void> drop() {
    // TODO: implement drop
    throw UnimplementedError();
  }

  @override
  Stream<NitriteId> findNitriteIds(FindPlan findPlan) {
    // TODO: implement findNitriteIds
    throw UnimplementedError();
  }

  @override
  IndexDescriptor get indexDescriptor => _indexDescriptor;

  @override
  // TODO: implement isUnique
  bool get isUnique => throw UnimplementedError();

  @override
  Future<void> remove(FieldValues fieldValues) {
    // TODO: implement remove
    throw UnimplementedError();
  }

  @override
  List removeNitriteIds(List nitriteIds, FieldValues fieldValues) {
    // TODO: implement removeNitriteIds
    throw UnimplementedError();
  }

  @override
  void validateIndexField(value, String field) {
    // TODO: implement validateIndexField
  }

  @override
  Future<void> write(FieldValues fieldValues) async {
    var fields = fieldValues.fields;
    var fieldNames = fields.fieldNames;

    var firstField = fieldNames.first;
    var element = fieldValues.get(firstField);

    var indexMap = await _findIndexMap();
    if (element == null) {
      await indexMap.add(_NullBox(), fieldValues.nitriteId);
    }
  }

  Future<NitriteRTree<BoundingBox, Geometry>> _findIndexMap() async {
    var mapName = deriveIndexMapName(_indexDescriptor);
    return _nitriteStore.openRTree<BoundingBox, Geometry>(mapName);
  }
}

class _NullBox extends BoundingBox {
  @override
  double get maxX => 0;

  @override
  double get maxY => 0;

  @override
  double get minX => 0;

  @override
  double get minY => 0;
}
